import 'package:freezed_annotation/freezed_annotation.dart';

part 'cached_file.freezed.dart';
part 'cached_file.g.dart';

/// Status do cache
enum CacheStatus { pending, downloading, cached, failed, expired }

@freezed
abstract class CachedFile with _$CachedFile {
  const CachedFile._();
  
  const factory CachedFile({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto do servidor
    String? remoteId,

    /// Tipo do arquivo (ex: image, video, document)
    required String fileType,

    /// MIME type (ex: image/png, video/mp4)
    required String mimeType,

    /// Nome original
    required String originalName,

    /// Caminho no cache local
    String? cachePath,

    /// URL remota original
    required String remoteUrl,

    /// Tamanho em bytes
    required int fileSizeBytes,

    /// Para imagens/vídeos
    int? width,
    int? height,

    /// Para vídeos
    int? durationSeconds,

    /// Status do cache
    @Default(CacheStatus.pending) CacheStatus cacheStatus,

    /// Prioridade de download (1–10, 1 = máxima)
    @Default(5) int downloadPriority,

    /// Progresso do download (0–100)
    @Default(0.0) double downloadProgress,

    /// Último acesso (para LRU cache)
    DateTime? lastAccessedAt,

    /// Quando expira o cache
    DateTime? expiresAt,

    /// Tentativas de retry
    @Default(0) int retryCount,

    /// Quando foi baixado
    DateTime? downloadedAt,

    /// Se foi modificado localmente
    @Default(false) bool isModified,

    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,
  }) = _CachedFile;

  /// Getter para verificar se o arquivo foi baixado
  bool get isDownloaded => cacheStatus == CacheStatus.cached && cachePath != null;

  factory CachedFile.fromJson(Map<String, dynamic> json) => _$CachedFileFromJson(json);
}
