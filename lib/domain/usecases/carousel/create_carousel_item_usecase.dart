import '../../entities/carousel_item.dart';
import '../../repositories/carousel_item_repository.dart';
import '../usecase.dart';

class CreateCarouselItemParams {
  final String menuLocalId;
  final CarouselItemType itemType;
  final String? backgroundFileLocalId;
  final int position;
  final String? title;
  final String? subtitle;
  final String? ctaText;
  final String? ctaUrl;
  final Map<String, dynamic>? mapData;
  final int preloadPriority;
  
  CreateCarouselItemParams({
    required this.menuLocalId,
    required this.itemType,
    this.backgroundFileLocalId,
    this.position = 0,
    this.title,
    this.subtitle,
    this.ctaText,
    this.ctaUrl,
    this.mapData,
    this.preloadPriority = 5,
  });
}

class CreateCarouselItemUseCase implements UseCase<CarouselItem, CreateCarouselItemParams> {
  final CarouselItemRepository _repository;
  
  CreateCarouselItemUseCase(this._repository);
  
  @override
  Future<CarouselItem> call(CreateCarouselItemParams params) async {
    try {
      // Validate priority
      if (params.preloadPriority < 1 || params.preloadPriority > 10) {
        throw Exception('Preload priority must be between 1 and 10');
      }
      
      // Create carousel item
      final newItem = CarouselItem(
        localId: '', // Will be set by repository
        menuLocalId: params.menuLocalId,
        itemType: params.itemType,
        backgroundFileLocalId: params.backgroundFileLocalId,
        position: params.position,
        title: params.title?.trim(),
        subtitle: params.subtitle?.trim(),
        ctaText: params.ctaText?.trim(),
        ctaUrl: params.ctaUrl?.trim(),
        mapData: params.mapData,
        preloadPriority: params.preloadPriority,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return await _repository.create(newItem);
    } catch (e) {
      throw Exception('Failed to create carousel item: ${e.toString()}');
    }
  }
}