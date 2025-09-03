import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/sync_queue.dart';

part 'sync_queue_dto.freezed.dart';
part 'sync_queue_dto.g.dart';

@freezed
abstract class SyncQueueDto with _$SyncQueueDto {
  const factory SyncQueueDto({
    required String id,
    required String entityType,
    required String entityId,
    required String operation,
    Map<String, dynamic>? data,
    @Default('pending') String status,
    @Default(0) int retryCount,
    @Default(3) int maxRetries,
    String? errorMessage,
    DateTime? lastAttemptAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) = _SyncQueueDto;

  factory SyncQueueDto.fromJson(Map<String, dynamic> json) => _$SyncQueueDtoFromJson(json);
}

extension SyncQueueDtoMapper on SyncQueueDto {
  SyncQueue toEntity(String localId) {
    return SyncQueue(
      localId: localId,
      remoteId: id,
      entityType: entityType,
      entityLocalId: entityId,
      operation: _parseOperation(operation),
      payload: data ?? {},
      status: _parseStatus(status),
      retryCount: retryCount,
      errorMessage: errorMessage,
      lastAttemptAt: lastAttemptAt,
      syncedAt: completedAt,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  SyncOperation _parseOperation(String operation) {
    switch (operation) {
      case 'create':
        return SyncOperation.create;
      case 'update':
        return SyncOperation.update;
      case 'delete':
        return SyncOperation.delete;
      case 'upsert':
        return SyncOperation.upsert;
      default:
        return SyncOperation.create;
    }
  }

  QueueStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return QueueStatus.pending;
      case 'processing':
        return QueueStatus.processing;
      case 'success':
        return QueueStatus.success;
      case 'failed':
        return QueueStatus.failed;
      case 'conflict':
        return QueueStatus.conflict;
      case 'cancelled':
        return QueueStatus.cancelled;
      default:
        return QueueStatus.pending;
    }
  }
}

extension SyncQueueMapper on SyncQueue {
  SyncQueueDto toDto() {
    return SyncQueueDto(
      id: remoteId ?? localId,
      entityType: entityType,
      entityId: entityLocalId,
      operation: operation.name,
      data: payload,
      status: status.name,
      retryCount: retryCount,
      maxRetries: 3, // Default max retries
      errorMessage: errorMessage,
      lastAttemptAt: lastAttemptAt,
      completedAt: syncedAt,
      createdAt: createdAt,
    );
  }
}