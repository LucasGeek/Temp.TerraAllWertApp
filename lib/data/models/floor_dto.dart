import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/floor.dart';

part 'floor_dto.freezed.dart';
part 'floor_dto.g.dart';

@freezed
abstract class FloorDto with _$FloorDto {
  const factory FloorDto({
    required String id,
    required String towerId,
    required int floorNumber,
    String? floorName,
    String? bannerFileId,
    String? floorPlanFileId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _FloorDto;

  factory FloorDto.fromJson(Map<String, dynamic> json) => _$FloorDtoFromJson(json);
}

extension FloorDtoMapper on FloorDto {
  Floor toEntity(String localId) {
    return Floor(
      localId: localId,
      remoteId: id,
      towerLocalId: towerId,
      floorNumber: floorNumber,
      floorName: floorName,
      bannerFileLocalId: bannerFileId,
      floorPlanFileLocalId: floorPlanFileId,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension FloorMapper on Floor {
  FloorDto toDto() {
    return FloorDto(
      id: remoteId ?? localId,
      towerId: towerLocalId,
      floorNumber: floorNumber,
      floorName: floorName,
      bannerFileId: bannerFileLocalId,
      floorPlanFileId: floorPlanFileLocalId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}