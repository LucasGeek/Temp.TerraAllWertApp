import '../../entities/menu_carousel.dart';
import '../usecase.dart';

class UpdateCarouselSettingsParams {
  final String localId;
  final String? promotionalVideoLocalId;
  final bool? autoplay;
  final int? autoplayInterval;
  final bool? showIndicators;
  final bool? showControls;
  final String? transitionType;
  final bool? enableSwipe;
  final bool? loop;
  final int? preloadItemsCount;
  final bool? cacheVideoThumbnails;
  final String? offlineFallbackImageLocalId;
  
  UpdateCarouselSettingsParams({
    required this.localId,
    this.promotionalVideoLocalId,
    this.autoplay,
    this.autoplayInterval,
    this.showIndicators,
    this.showControls,
    this.transitionType,
    this.enableSwipe,
    this.loop,
    this.preloadItemsCount,
    this.cacheVideoThumbnails,
    this.offlineFallbackImageLocalId,
  });
}

class UpdateCarouselSettingsUseCase implements UseCase<MenuCarousel, UpdateCarouselSettingsParams> {
  
  @override
  Future<MenuCarousel> call(UpdateCarouselSettingsParams params) async {
    try {
      // Validate transition type if provided
      if (params.transitionType != null) {
        final validTransitions = ['slide', 'fade', 'zoom', 'flip'];
        if (!validTransitions.contains(params.transitionType)) {
          throw Exception('Invalid transition type. Must be one of: ${validTransitions.join(", ")}');
        }
      }
      
      // Validate autoplay interval if provided
      if (params.autoplayInterval != null && params.autoplayInterval! < 1000) {
        throw Exception('Autoplay interval must be at least 1000ms');
      }
      
      // Validate preload count if provided
      if (params.preloadItemsCount != null && 
          (params.preloadItemsCount! < 0 || params.preloadItemsCount! > 10)) {
        throw Exception('Preload items count must be between 0 and 10');
      }
      
      // Create updated carousel config (in real app, would fetch existing and update)
      final updatedCarousel = MenuCarousel(
        localId: params.localId,
        menuLocalId: 'dummy', // Would come from existing record
        promotionalVideoLocalId: params.promotionalVideoLocalId,
        autoplay: params.autoplay ?? true,
        autoplayInterval: params.autoplayInterval ?? 5000,
        showIndicators: params.showIndicators ?? true,
        showControls: params.showControls ?? true,
        transitionType: params.transitionType ?? 'slide',
        enableSwipe: params.enableSwipe ?? true,
        loop: params.loop ?? true,
        preloadItemsCount: params.preloadItemsCount ?? 2,
        cacheVideoThumbnails: params.cacheVideoThumbnails ?? true,
        offlineFallbackImageLocalId: params.offlineFallbackImageLocalId,
        createdAt: DateTime.now(), // Would come from existing
        updatedAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return updatedCarousel;
    } catch (e) {
      throw Exception('Failed to update carousel settings: ${e.toString()}');
    }
  }
}