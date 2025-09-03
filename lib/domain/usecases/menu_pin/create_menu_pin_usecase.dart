import '../../entities/menu_pin.dart';
import '../usecase.dart';

class CreateMenuPinParams {
  final String menuLocalId;
  final String? backgroundFileLocalId;
  final String? promotionalVideoLocalId;
  final bool enableZoom;
  final bool enablePan;
  final double minZoom;
  final double maxZoom;
  final double initialZoom;
  final bool showPinLabels;
  final bool clusterNearbyPins;
  final bool cacheAllPinImages;
  final bool enableOfflineInteraction;
  
  CreateMenuPinParams({
    required this.menuLocalId,
    this.backgroundFileLocalId,
    this.promotionalVideoLocalId,
    this.enableZoom = true,
    this.enablePan = true,
    this.minZoom = 0.5,
    this.maxZoom = 3.0,
    this.initialZoom = 1.0,
    this.showPinLabels = true,
    this.clusterNearbyPins = false,
    this.cacheAllPinImages = false,
    this.enableOfflineInteraction = true,
  });
}

class CreateMenuPinUseCase implements UseCase<MenuPin, CreateMenuPinParams> {
  
  @override
  Future<MenuPin> call(CreateMenuPinParams params) async {
    try {
      // Validate zoom levels
      if (params.minZoom <= 0) {
        throw Exception('Min zoom must be greater than 0');
      }
      
      if (params.maxZoom <= params.minZoom) {
        throw Exception('Max zoom must be greater than min zoom');
      }
      
      if (params.initialZoom < params.minZoom || params.initialZoom > params.maxZoom) {
        throw Exception('Initial zoom must be between min and max zoom');
      }
      
      // Create menu pin configuration
      final menuPin = MenuPin(
        localId: '', // Will be generated
        menuLocalId: params.menuLocalId,
        backgroundFileLocalId: params.backgroundFileLocalId,
        promotionalVideoLocalId: params.promotionalVideoLocalId,
        enableZoom: params.enableZoom,
        enablePan: params.enablePan,
        minZoom: params.minZoom,
        maxZoom: params.maxZoom,
        initialZoom: params.initialZoom,
        showPinLabels: params.showPinLabels,
        clusterNearbyPins: params.clusterNearbyPins,
        cacheAllPinImages: params.cacheAllPinImages,
        enableOfflineInteraction: params.enableOfflineInteraction,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return menuPin;
    } catch (e) {
      throw Exception('Failed to create menu pin: ${e.toString()}');
    }
  }
}