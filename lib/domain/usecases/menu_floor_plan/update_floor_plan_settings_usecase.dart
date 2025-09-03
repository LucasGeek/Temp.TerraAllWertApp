import '../../entities/menu_floor_plan.dart';
import '../usecase.dart';

class UpdateFloorPlanSettingsParams {
  final String localId;
  final String? defaultView;
  final bool? enableUnitFilters;
  final bool? enableUnitComparison;
  final bool? showAvailabilityLegend;
  final bool? allowFloorNavigation;
  final bool? cacheFloorImages;
  final bool? preloadAdjacentFloors;
  
  UpdateFloorPlanSettingsParams({
    required this.localId,
    this.defaultView,
    this.enableUnitFilters,
    this.enableUnitComparison,
    this.showAvailabilityLegend,
    this.allowFloorNavigation,
    this.cacheFloorImages,
    this.preloadAdjacentFloors,
  });
}

class UpdateFloorPlanSettingsUseCase implements UseCase<MenuFloorPlan, UpdateFloorPlanSettingsParams> {
  
  @override
  Future<MenuFloorPlan> call(UpdateFloorPlanSettingsParams params) async {
    try {
      // Validate default view if provided
      if (params.defaultView != null) {
        final validViews = ['2d', '3d', 'mixed'];
        if (!validViews.contains(params.defaultView)) {
          throw Exception('Invalid default view. Must be one of: ${validViews.join(", ")}');
        }
      }
      
      // Since we don't have a repository, we'll create a dummy updated object
      // In a real implementation, this would fetch current config, update it, and save
      final updatedFloorPlan = MenuFloorPlan(
        localId: params.localId,
        menuLocalId: 'dummy', // Would come from existing record
        defaultView: params.defaultView ?? '2d',
        enableUnitFilters: params.enableUnitFilters ?? true,
        enableUnitComparison: params.enableUnitComparison ?? true,
        showAvailabilityLegend: params.showAvailabilityLegend ?? true,
        allowFloorNavigation: params.allowFloorNavigation ?? true,
        cacheFloorImages: params.cacheFloorImages ?? true,
        preloadAdjacentFloors: params.preloadAdjacentFloors ?? false,
        createdAt: DateTime.now(), // Would come from existing
        updatedAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return updatedFloorPlan;
    } catch (e) {
      throw Exception('Failed to update floor plan settings: ${e.toString()}');
    }
  }
}