import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_floor_plan.freezed.dart';
part 'menu_floor_plan.g.dart';

@freezed
abstract class MenuFloorPlan with _$MenuFloorPlan {
  const factory MenuFloorPlan({
    required String localId,
    String? remoteId,
    required String menuLocalId,
    @Default('2d') String defaultView,
    @Default(true) bool enableUnitFilters,
    @Default(true) bool enableUnitComparison,
    @Default(true) bool showAvailabilityLegend,
    @Default(true) bool allowFloorNavigation,
    @Default(true) bool cacheFloorImages,
    @Default(false) bool preloadAdjacentFloors,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(1) int syncVersion,
    @Default(false) bool isModified,
    DateTime? lastModifiedAt,
  }) = _MenuFloorPlan;

  factory MenuFloorPlan.fromJson(Map<String, dynamic> json) => _$MenuFloorPlanFromJson(json);
}