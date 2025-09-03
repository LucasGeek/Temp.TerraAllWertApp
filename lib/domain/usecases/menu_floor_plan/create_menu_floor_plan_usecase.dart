import '../../entities/menu_floor_plan.dart';
import '../usecase.dart';

class CreateMenuFloorPlanParams {
  final String menuLocalId;
  final String defaultView;
  final bool enableUnitFilters;
  final bool enableUnitComparison;
  final bool showAvailabilityLegend;
  final bool allowFloorNavigation;
  final bool cacheFloorImages;
  final bool preloadAdjacentFloors;
  
  CreateMenuFloorPlanParams({
    required this.menuLocalId,
    this.defaultView = '2d',
    this.enableUnitFilters = true,
    this.enableUnitComparison = true,
    this.showAvailabilityLegend = true,
    this.allowFloorNavigation = true,
    this.cacheFloorImages = true,
    this.preloadAdjacentFloors = false,
  });
}

class CreateMenuFloorPlanUseCase implements UseCase<MenuFloorPlan, CreateMenuFloorPlanParams> {
  
  @override
  Future<MenuFloorPlan> call(CreateMenuFloorPlanParams params) async {
    try {
      // Validate default view
      final validViews = ['2d', '3d', 'mixed'];
      if (!validViews.contains(params.defaultView)) {
        throw Exception('Invalid default view. Must be one of: ${validViews.join(", ")}');
      }
      
      // Create menu floor plan configuration
      final menuFloorPlan = MenuFloorPlan(
        localId: '', // Will be generated
        menuLocalId: params.menuLocalId,
        defaultView: params.defaultView,
        enableUnitFilters: params.enableUnitFilters,
        enableUnitComparison: params.enableUnitComparison,
        showAvailabilityLegend: params.showAvailabilityLegend,
        allowFloorNavigation: params.allowFloorNavigation,
        cacheFloorImages: params.cacheFloorImages,
        preloadAdjacentFloors: params.preloadAdjacentFloors,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return menuFloorPlan;
    } catch (e) {
      throw Exception('Failed to create menu floor plan: ${e.toString()}');
    }
  }
}