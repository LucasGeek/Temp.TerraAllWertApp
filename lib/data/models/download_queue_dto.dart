import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/download_queue.dart';

part 'download_queue_dto.freezed.dart';
part 'download_queue_dto.g.dart';

@freezed
abstract class DownloadQueueDto with _$DownloadQueueDto {
  const factory DownloadQueueDto({
    required String id,
    required String entityType,
    required String entityId,
    required String resourceType,
    required String resourceUrl,
    @Default('pending') String status,
    @Default(0) int priority,
    @Default(0) double progress,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _DownloadQueueDto;

  factory DownloadQueueDto.fromJson(Map<String, dynamic> json) => 
      _$DownloadQueueDtoFromJson(json);
}

extension DownloadQueueDtoMapper on DownloadQueueDto {
  DownloadQueue toEntity(String localId) {
    return DownloadQueue(
      localId: localId,
      remoteId: id,
      resourceType: resourceType,
      resourceLocalId: entityId,
      resourceUrl: resourceUrl,
      status: _parseStatus(status),
      priority: priority,
      progress: progress,
      startedAt: startedAt,
      completedAt: completedAt,
      errorMessage: error,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
  
  DownloadStatus _parseStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return DownloadStatus.pending;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      case 'cancelled':
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.pending;
    }
  }
}

extension DownloadQueueEntityMapper on DownloadQueue {
  DownloadQueueDto toDto() {
    return DownloadQueueDto(
      id: remoteId ?? localId,
      entityType: 'download_queue',
      entityId: resourceLocalId,
      resourceType: resourceType,
      resourceUrl: resourceUrl,
      status: status.name,
      priority: priority,
      progress: progress,
      startedAt: startedAt,
      completedAt: completedAt,
      error: errorMessage,
      createdAt: createdAt,
      updatedAt: null,
    );
  }
}