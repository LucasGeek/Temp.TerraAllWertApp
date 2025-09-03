import '../../entities/menu_carousel.dart';
import '../usecase.dart';

class CreateMenuCarouselParams {
  final String menuLocalId;
  final String? promotionalVideoLocalId;
  final bool autoplay;
  final int autoplayInterval;
  final bool showIndicators;
  final bool showControls;
  final String transitionType;
  final bool enableSwipe;
  final bool loop;
  final int preloadItemsCount;
  final bool cacheVideoThumbnails;
  final String? offlineFallbackImageLocalId;
  
  CreateMenuCarouselParams({
    required this.menuLocalId,
    this.promotionalVideoLocalId,
    this.autoplay = true,
    this.autoplayInterval = 5000,
    this.showIndicators = true,
    this.showControls = true,
    this.transitionType = 'slide',
    this.enableSwipe = true,
    this.loop = true,
    this.preloadItemsCount = 2,
    this.cacheVideoThumbnails = true,
    this.offlineFallbackImageLocalId,
  });
}

class CreateMenuCarouselUseCase implements UseCase<MenuCarousel, CreateMenuCarouselParams> {
  
  @override
  Future<MenuCarousel> call(CreateMenuCarouselParams params) async {
    try {
      // Validate transition type
      final validTransitions = ['slide', 'fade', 'zoom', 'flip'];
      if (!validTransitions.contains(params.transitionType)) {
        throw Exception('Invalid transition type. Must be one of: ${validTransitions.join(", ")}');
      }
      
      // Validate autoplay interval
      if (params.autoplayInterval < 1000) {
        throw Exception('Autoplay interval must be at least 1000ms');
      }
      
      // Validate preload count
      if (params.preloadItemsCount < 0 || params.preloadItemsCount > 10) {
        throw Exception('Preload items count must be between 0 and 10');
      }
      
      // Create menu carousel configuration
      final menuCarousel = MenuCarousel(
        localId: '', // Will be generated
        menuLocalId: params.menuLocalId,
        promotionalVideoLocalId: params.promotionalVideoLocalId,
        autoplay: params.autoplay,
        autoplayInterval: params.autoplayInterval,
        showIndicators: params.showIndicators,
        showControls: params.showControls,
        transitionType: params.transitionType,
        enableSwipe: params.enableSwipe,
        loop: params.loop,
        preloadItemsCount: params.preloadItemsCount,
        cacheVideoThumbnails: params.cacheVideoThumbnails,
        offlineFallbackImageLocalId: params.offlineFallbackImageLocalId,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return menuCarousel;
    } catch (e) {
      throw Exception('Failed to create menu carousel: ${e.toString()}');
    }
  }
}