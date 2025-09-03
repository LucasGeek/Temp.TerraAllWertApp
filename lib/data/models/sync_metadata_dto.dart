import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/sync_metadata.dart';

part 'sync_metadata_dto.freezed.dart';
part 'sync_metadata_dto.g.dart';

@freezed
abstract class SyncMetadataDto with _$SyncMetadataDto {
  const factory SyncMetadataDto({
    required String id,
    required String entityType,
    required String entityId,
    String? lastSyncVersion,
    DateTime? lastSyncedAt,
    @Default('pending') String syncStatus,
    @Default(0) int pendingChangesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SyncMetadataDto;

  factory SyncMetadataDto.fromJson(Map<String, dynamic> json) => 
      _$SyncMetadataDtoFromJson(json);
}

extension SyncMetadataDtoMapper on SyncMetadataDto {
  SyncMetadata toEntity(String localId) {
    return SyncMetadata(
      localId: localId,
      remoteId: id,
      entityType: entityType,
      entityLocalId: entityId,
      lastSyncVersion: lastSyncVersion,
      lastSyncedAt: lastSyncedAt,
      syncStatus: _parseSyncStatus(syncStatus),
      pendingChangesCount: pendingChangesCount,
      createdAt: createdAt ?? DateTime.now(),
      lastModifiedAt: updatedAt,
    );
  }

  SyncStatus _parseSyncStatus(String status) {
    switch (status) {
      case 'idle':
        return SyncStatus.idle;
      case 'pending':
        return SyncStatus.pending;
      case 'syncing':
        return SyncStatus.syncing;
      case 'error':
        return SyncStatus.error;
      case 'conflict':
        return SyncStatus.conflict;
      default:
        return SyncStatus.pending;
    }
  }
}

extension SyncMetadataEntityMapper on SyncMetadata {
  SyncMetadataDto toDto() {
    return SyncMetadataDto(
      id: remoteId ?? localId,
      entityType: entityType,
      entityId: entityLocalId,
      lastSyncVersion: lastSyncVersion,
      lastSyncedAt: lastSyncedAt,
      syncStatus: syncStatus.name,
      pendingChangesCount: pendingChangesCount,
      createdAt: createdAt,
      updatedAt: lastModifiedAt,
    );
  }
}