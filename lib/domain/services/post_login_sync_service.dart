import '../entities/user.dart';

/// Serviço responsável pelo fluxo de sincronização após login
/// Executa: 1. Verificação de atualizações de arquivos
///          2. Busca de menus da API com fallback para cache
abstract class PostLoginSyncService {
  /// Executa o fluxo completo de sincronização pós-login
  Future<PostLoginSyncResult> executeSyncFlow({
    required User user,
    required bool isOnline,
    required bool isWeb,
  });

  /// Verifica se existem atualizações de arquivos disponíveis
  Future<FileUpdateInfo> checkFileUpdates({
    required String userId,
    required bool isOnline,
  });

  /// Baixa arquivos atualizados
  Future<FileDownloadResult> downloadUpdatedFiles({
    required List<String> fileIds,
    required String userId,
  });

  /// Busca menus da API com fallback para cache
  Future<MenuSyncResult> syncMenus({
    required String userId,
    required bool isOnline,
  });
}

/// Resultado do fluxo de sincronização pós-login
class PostLoginSyncResult {
  final bool success;
  final String? error;
  final FileUpdateInfo fileUpdateInfo;
  final FileDownloadResult? downloadResult;
  final MenuSyncResult menuResult;
  final DateTime completedAt;

  PostLoginSyncResult({
    required this.success,
    this.error,
    required this.fileUpdateInfo,
    this.downloadResult,
    required this.menuResult,
    required this.completedAt,
  });
}

/// Informações sobre atualizações de arquivos
class FileUpdateInfo {
  final bool hasUpdates;
  final List<String> updatedFileIds;
  final int totalFiles;
  final int totalSizeBytes;
  final DateTime? lastCheck;

  FileUpdateInfo({
    required this.hasUpdates,
    required this.updatedFileIds,
    required this.totalFiles,
    required this.totalSizeBytes,
    this.lastCheck,
  });

  factory FileUpdateInfo.empty() => FileUpdateInfo(
    hasUpdates: false,
    updatedFileIds: [],
    totalFiles: 0,
    totalSizeBytes: 0,
  );
}

/// Resultado do download de arquivos
class FileDownloadResult {
  final bool success;
  final int downloadedFiles;
  final int failedFiles;
  final List<String> errors;
  final Duration downloadTime;

  FileDownloadResult({
    required this.success,
    required this.downloadedFiles,
    required this.failedFiles,
    required this.errors,
    required this.downloadTime,
  });
}

/// Resultado da sincronização de menus
class MenuSyncResult {
  final bool success;
  final MenuSyncSource source;
  final int menuCount;
  final String? error;
  final DateTime syncedAt;

  MenuSyncResult({
    required this.success,
    required this.source,
    required this.menuCount,
    this.error,
    required this.syncedAt,
  });
}

/// Fonte dos dados dos menus
enum MenuSyncSource {
  api,      // Dados obtidos da API
  cache,    // Dados obtidos do cache local
  fallback, // Dados padrão/fallback
}