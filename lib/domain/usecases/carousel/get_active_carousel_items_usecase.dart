import '../../entities/carousel_item.dart';
import '../../repositories/carousel_item_repository.dart';
import '../usecase.dart';

class GetActiveCarouselItemsUseCase implements NoParamsUseCase<List<CarouselItem>> {
  final CarouselItemRepository _repository;
  
  GetActiveCarouselItemsUseCase(this._repository);
  
  @override
  Future<List<CarouselItem>> call() async {
    try {
      return await _repository.getActive();
    } catch (e) {
      throw Exception('Failed to get active carousel items: ${e.toString()}');
    }
  }
}