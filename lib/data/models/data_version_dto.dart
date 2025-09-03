import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/data_version.dart';

part 'data_version_dto.freezed.dart';
part 'data_version_dto.g.dart';

@freezed
abstract class DataVersionDto with _$DataVersionDto {
  const factory DataVersionDto({
    required String id,
    required String entityType,
    required String entityId,
    required int versionNumber,
    required String changeType,
    List<String>? changedFields,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? changedById,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _DataVersionDto;

  factory DataVersionDto.fromJson(Map<String, dynamic> json) => 
      _$DataVersionDtoFromJson(json);
}

extension DataVersionDtoMapper on DataVersionDto {
  DataVersion toEntity(String localId) {
    return DataVersion(
      localId: localId,
      remoteId: id,
      entityType: entityType,
      entityLocalId: entityId,
      versionNumber: versionNumber,
      changeType: _parseChangeType(changeType),
      changedFields: changedFields,
      oldValues: oldValues,
      newValues: newValues,
      changedByLocalId: changedById,
      deviceId: deviceId,
      createdAt: createdAt ?? DateTime.now(),
      lastModifiedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  ChangeType _parseChangeType(String type) {
    switch (type.toLowerCase()) {
      case 'create':
        return ChangeType.create;
      case 'update':
        return ChangeType.update;
      case 'delete':
        return ChangeType.delete;
      case 'restore':
        return ChangeType.restore;
      default:
        return ChangeType.update;
    }
  }
}

extension DataVersionEntityMapper on DataVersion {
  DataVersionDto toDto() {
    return DataVersionDto(
      id: remoteId ?? localId,
      entityType: entityType,
      entityId: entityLocalId,
      versionNumber: versionNumber,
      changeType: changeType.name,
      changedFields: changedFields,
      oldValues: oldValues,
      newValues: newValues,
      changedById: changedByLocalId,
      deviceId: deviceId,
      createdAt: createdAt,
      updatedAt: lastModifiedAt,
    );
  }
}