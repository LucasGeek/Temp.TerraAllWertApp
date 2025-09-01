import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infra/downloads/background_download_service.dart';

/// Provider para o serviço de downloads
final downloadServiceProvider = Provider<BackgroundDownloadService>((ref) {
  return BackgroundDownloadService();
});

/// Provider para downloads ativos
final activeDownloadsProvider = StreamProvider<List<String>>((ref) async* {
  final downloadService = ref.watch(downloadServiceProvider);
  
  // Stream inicial com downloads ativos
  yield await downloadService.getActiveDownloads();
  
  // Atualizar periodicamente (a cada 5 segundos)
  while (true) {
    await Future.delayed(const Duration(seconds: 5));
    yield await downloadService.getActiveDownloads();
  }
});

/// Provider para progresso de um download específico
final downloadProgressProvider = StreamProvider.family<DownloadProgress?, String>((ref, taskId) {
  final downloadService = ref.watch(downloadServiceProvider);
  return downloadService.getProgressStream(taskId) ?? const Stream.empty();
});

/// Provider para status de um download específico  
final downloadStatusProvider = StreamProvider.family<DownloadStatus?, String>((ref, taskId) {
  final downloadService = ref.watch(downloadServiceProvider);
  return downloadService.getStatusStream(taskId) ?? const Stream.empty();
});

/// Provider para informações de um download específico
final downloadInfoProvider = FutureProvider.family<DownloadTaskInfo?, String>((ref, taskId) async {
  final downloadService = ref.watch(downloadServiceProvider);
  return await downloadService.getDownloadInfo(taskId);
});

/// Controller para gerenciar downloads
class DownloadController extends StateNotifier<Map<String, DownloadTaskInfo>> {
  final BackgroundDownloadService _downloadService;
  
  DownloadController(this._downloadService) : super({});

  /// Inicia um novo download
  Future<String> startDownload({
    required String url,
    required String filename,
    String? directory,
    String? metadata,
    bool allowPause = true,
    bool requiresWiFi = false,
    int retries = 3,
  }) async {
    final taskId = await _downloadService.startDownload(
      url: url,
      filename: filename,
      directory: directory,
      metadata: metadata,
      allowPause: allowPause,
      requiresWiFi: requiresWiFi,
      retries: retries,
    );

    // Atualizar estado com nova tarefa
    await _updateTaskInfo(taskId);
    
    return taskId;
  }

  /// Pausa um download
  Future<bool> pauseDownload(String taskId) async {
    final success = await _downloadService.pauseDownload(taskId);
    if (success) {
      await _updateTaskInfo(taskId);
    }
    return success;
  }

  /// Resume um download
  Future<bool> resumeDownload(String taskId) async {
    final success = await _downloadService.resumeDownload(taskId);
    if (success) {
      await _updateTaskInfo(taskId);
    }
    return success;
  }

  /// Cancela um download
  Future<bool> cancelDownload(String taskId) async {
    final success = await _downloadService.cancelDownload(taskId);
    if (success) {
      // Remover do estado
      final newState = Map<String, DownloadTaskInfo>.from(state);
      newState.remove(taskId);
      state = newState;
    }
    return success;
  }

  /// Atualiza informações de uma tarefa
  Future<void> _updateTaskInfo(String taskId) async {
    final info = await _downloadService.getDownloadInfo(taskId);
    if (info != null) {
      final newState = Map<String, DownloadTaskInfo>.from(state);
      newState[taskId] = info;
      state = newState;
    }
  }

  /// Atualiza todas as tarefas ativas
  Future<void> refreshAllTasks() async {
    final activeTaskIds = await _downloadService.getActiveDownloads();
    final newState = <String, DownloadTaskInfo>{};
    
    for (final taskId in activeTaskIds) {
      final info = await _downloadService.getDownloadInfo(taskId);
      if (info != null) {
        newState[taskId] = info;
      }
    }
    
    state = newState;
  }

  /// Cancela todos os downloads
  Future<void> cancelAllDownloads() async {
    await _downloadService.cancelAllDownloads();
    state = {};
  }

  /// Obtém o caminho de um arquivo baixado
  Future<String?> getDownloadedFilePath(String taskId) async {
    return await _downloadService.getDownloadedFilePath(taskId);
  }
}

/// Provider do controller de downloads
final downloadControllerProvider = StateNotifierProvider<DownloadController, Map<String, DownloadTaskInfo>>((ref) {
  final downloadService = ref.watch(downloadServiceProvider);
  return DownloadController(downloadService);
});