import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/tower.dart';

part 'tower_dto.freezed.dart';
part 'tower_dto.g.dart';

@freezed
abstract class TowerDto with _$TowerDto {
  const factory TowerDto({
    required String id,
    String? enterpriseId,
    String? menuId,
    required String title,
    String? description,
    @Default(0) int totalFloors,
    @Default(0) int unitsPerFloor,
    @Default(0) int position,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _TowerDto;

  factory TowerDto.fromJson(Map<String, dynamic> json) => _$TowerDtoFromJson(json);
}

extension TowerDtoMapper on TowerDto {
  Tower toEntity(String localId) {
    return Tower(
      localId: localId,
      remoteId: id,
      menuLocalId: menuId ?? '',
      title: title,
      description: description,
      totalFloors: totalFloors,
      unitsPerFloor: unitsPerFloor,
      position: position,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension TowerMapper on Tower {
  TowerDto toDto() {
    return TowerDto(
      id: remoteId ?? localId,
      enterpriseId: null, // Not available in entity
      menuId: menuLocalId,
      title: title,
      description: description,
      totalFloors: totalFloors,
      unitsPerFloor: unitsPerFloor ?? 0,
      position: position,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}