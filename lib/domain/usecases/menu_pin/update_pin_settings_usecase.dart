import '../../entities/menu_pin.dart';
import '../usecase.dart';

class UpdatePinSettingsParams {
  final String localId;
  final String? backgroundFileLocalId;
  final String? promotionalVideoLocalId;
  final bool? enableZoom;
  final bool? enablePan;
  final double? minZoom;
  final double? maxZoom;
  final double? initialZoom;
  final bool? showPinLabels;
  final bool? clusterNearbyPins;
  final bool? cacheAllPinImages;
  final bool? enableOfflineInteraction;
  
  UpdatePinSettingsParams({
    required this.localId,
    this.backgroundFileLocalId,
    this.promotionalVideoLocalId,
    this.enableZoom,
    this.enablePan,
    this.minZoom,
    this.maxZoom,
    this.initialZoom,
    this.showPinLabels,
    this.clusterNearbyPins,
    this.cacheAllPinImages,
    this.enableOfflineInteraction,
  });
}

class UpdatePinSettingsUseCase implements UseCase<MenuPin, UpdatePinSettingsParams> {
  
  @override
  Future<MenuPin> call(UpdatePinSettingsParams params) async {
    try {
      final currentMinZoom = params.minZoom ?? 0.5;
      final currentMaxZoom = params.maxZoom ?? 3.0;
      final currentInitialZoom = params.initialZoom ?? 1.0;
      
      // Validate zoom levels if provided
      if (currentMinZoom <= 0) {
        throw Exception('Min zoom must be greater than 0');
      }
      
      if (currentMaxZoom <= currentMinZoom) {
        throw Exception('Max zoom must be greater than min zoom');
      }
      
      if (currentInitialZoom < currentMinZoom || currentInitialZoom > currentMaxZoom) {
        throw Exception('Initial zoom must be between min and max zoom');
      }
      
      // Create updated pin config (in real app, would fetch existing and update)
      final updatedPin = MenuPin(
        localId: params.localId,
        menuLocalId: 'dummy', // Would come from existing record
        backgroundFileLocalId: params.backgroundFileLocalId,
        promotionalVideoLocalId: params.promotionalVideoLocalId,
        enableZoom: params.enableZoom ?? true,
        enablePan: params.enablePan ?? true,
        minZoom: currentMinZoom,
        maxZoom: currentMaxZoom,
        initialZoom: currentInitialZoom,
        showPinLabels: params.showPinLabels ?? true,
        clusterNearbyPins: params.clusterNearbyPins ?? false,
        cacheAllPinImages: params.cacheAllPinImages ?? false,
        enableOfflineInteraction: params.enableOfflineInteraction ?? true,
        createdAt: DateTime.now(), // Would come from existing
        updatedAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return updatedPin;
    } catch (e) {
      throw Exception('Failed to update pin settings: ${e.toString()}');
    }
  }
}