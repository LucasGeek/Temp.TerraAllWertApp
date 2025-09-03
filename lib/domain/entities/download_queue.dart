import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_queue.freezed.dart';
part 'download_queue.g.dart';

/// Status do download
enum DownloadStatus { pending, downloading, paused, completed, failed, cancelled }

@freezed
abstract class DownloadQueue with _$DownloadQueue {
  const factory DownloadQueue({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,

    /// Tipo do recurso (ex: file, tower, floor, etc.)
    required String resourceType,

    /// FK local do recurso
    required String resourceLocalId,

    /// URL do recurso
    required String resourceUrl,

    /// Prioridade do download (1–10, default = 5)
    @Default(5) int priority,

    /// Status do download
    @Default(DownloadStatus.pending) DownloadStatus status,

    /// Progresso do download (0–100)
    @Default(0.0) double progress,

    /// Tamanho total em bytes
    int? fileSizeBytes,

    /// Bytes já baixados
    @Default(0) int downloadedBytes,

    /// Tentativas já feitas
    @Default(0) int retryCount,

    /// Máximo de tentativas
    @Default(3) int maxRetries,

    /// Mensagem de erro
    String? errorMessage,

    /// Quando começou
    DateTime? startedAt,

    /// Quando terminou
    DateTime? completedAt,

    /// Se foi modificado localmente
    @Default(false) bool isModified,

    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,

    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _DownloadQueue;

  factory DownloadQueue.fromJson(Map<String, dynamic> json) => _$DownloadQueueFromJson(json);
}
