import '../../entities/carousel_item.dart';
import '../../repositories/carousel_item_repository.dart';
import '../usecase.dart';

class GetCarouselItemsByMenuParams {
  final String menuLocalId;
  
  GetCarouselItemsByMenuParams({required this.menuLocalId});
}

class GetCarouselItemsByMenuUseCase implements UseCase<List<CarouselItem>, GetCarouselItemsByMenuParams> {
  final CarouselItemRepository _repository;
  
  GetCarouselItemsByMenuUseCase(this._repository);
  
  @override
  Future<List<CarouselItem>> call(GetCarouselItemsByMenuParams params) async {
    try {
      return await _repository.getByMenuId(params.menuLocalId);
    } catch (e) {
      throw Exception('Failed to get carousel items by menu: ${e.toString()}');
    }
  }
}