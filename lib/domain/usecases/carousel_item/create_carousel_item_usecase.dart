import '../../entities/carousel_item.dart';
import '../../repositories/carousel_item_repository.dart';

class CreateCarouselItemUseCase {
  final CarouselItemRepository _repository;
  
  CreateCarouselItemUseCase(this._repository);
  
  Future<CarouselItem> call(CarouselItem item) async {
    try {
      // Validate item data
      if (item.title?.isEmpty == true) {
        throw Exception('Carousel item title is required');
      }
      
      // Create carousel item
      final createdItem = await _repository.create(item);
      return createdItem;
    } catch (e) {
      throw Exception('Failed to create carousel item: ${e.toString()}');
    }
  }
}