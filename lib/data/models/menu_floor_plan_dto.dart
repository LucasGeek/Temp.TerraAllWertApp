import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/menu_floor_plan.dart';

part 'menu_floor_plan_dto.freezed.dart';
part 'menu_floor_plan_dto.g.dart';

@freezed
abstract class MenuFloorPlanDto with _$MenuFloorPlanDto {
  const factory MenuFloorPlanDto({
    required String id,
    required String menuId,
    required String towerId,
    @Default(0) int position,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MenuFloorPlanDto;

  factory MenuFloorPlanDto.fromJson(Map<String, dynamic> json) => 
      _$MenuFloorPlanDtoFromJson(json);
}

extension MenuFloorPlanDtoMapper on MenuFloorPlanDto {
  MenuFloorPlan toEntity(String localId) {
    return MenuFloorPlan(
      localId: localId,
      remoteId: id,
      menuLocalId: menuId,
      createdAt: createdAt ?? DateTime.now(),
      lastModifiedAt: updatedAt,
    );
  }
}

extension MenuFloorPlanEntityMapper on MenuFloorPlan {
  MenuFloorPlanDto toDto() {
    return MenuFloorPlanDto(
      id: remoteId ?? localId,
      menuId: menuLocalId,
      towerId: '', // Default empty tower ID
      position: 0, // Default position
      isActive: true, // Default active
      createdAt: createdAt,
      updatedAt: lastModifiedAt,
    );
  }
}