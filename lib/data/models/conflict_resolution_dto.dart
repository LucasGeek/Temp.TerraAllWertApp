import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/conflict_resolution.dart';

part 'conflict_resolution_dto.freezed.dart';
part 'conflict_resolution_dto.g.dart';

@freezed
abstract class ConflictResolutionDto with _$ConflictResolutionDto {
  const factory ConflictResolutionDto({
    required String id,
    required String entityType,
    required String entityId,
    required String conflictType,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    @Default('pending') String resolution,
    @Default('user') String resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ConflictResolutionDto;

  factory ConflictResolutionDto.fromJson(Map<String, dynamic> json) => 
      _$ConflictResolutionDtoFromJson(json);
}

extension ConflictResolutionDtoMapper on ConflictResolutionDto {
  ConflictResolution toEntity(String localId) {
    return ConflictResolution(
      localId: localId,
      remoteId: id,
      entityType: entityType,
      entityLocalId: entityId,
      entityRemoteId: null,
      localData: localData,
      remoteData: remoteData,
      conflictType: _parseConflictType(conflictType),
      resolutionStrategy: _parseResolutionStrategy(resolution),
      resolvedBy: resolvedBy,
      resolvedAt: resolvedAt,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
  
  ConflictType _parseConflictType(String type) {
    switch (type.toLowerCase()) {
      case 'concurrent_update':
        return ConflictType.concurrentUpdate;
      case 'deleted_remotely':
        return ConflictType.deletedRemotely;
      case 'deleted_locally':
        return ConflictType.deletedLocally;
      case 'version_mismatch':
        return ConflictType.versionMismatch;
      default:
        return ConflictType.versionMismatch;
    }
  }
  
  ResolutionStrategy? _parseResolutionStrategy(String resolution) {
    switch (resolution.toLowerCase()) {
      case 'local_wins':
        return ResolutionStrategy.localWins;
      case 'remote_wins':
        return ResolutionStrategy.remoteWins;
      case 'merge':
        return ResolutionStrategy.merge;
      case 'manual':
        return ResolutionStrategy.manual;
      default:
        return null;
    }
  }
}

extension ConflictResolutionEntityMapper on ConflictResolution {
  ConflictResolutionDto toDto() {
    return ConflictResolutionDto(
      id: remoteId ?? localId,
      entityType: entityType,
      entityId: entityLocalId,
      conflictType: conflictType.name,
      localData: localData,
      remoteData: remoteData,
      resolution: resolutionStrategy?.name ?? 'pending',
      resolvedBy: resolvedBy ?? 'user',
      resolvedAt: resolvedAt,
      createdAt: createdAt,
    );
  }
}