import '../../repositories/carousel_item_repository.dart';
import '../usecase.dart';

class UpdateCarouselPositionParams {
  final String localId;
  final int newPosition;
  
  UpdateCarouselPositionParams({
    required this.localId,
    required this.newPosition,
  });
}

class UpdateCarouselPositionUseCase implements VoidUseCase<UpdateCarouselPositionParams> {
  final CarouselItemRepository _repository;
  
  UpdateCarouselPositionUseCase(this._repository);
  
  @override
  Future<void> call(UpdateCarouselPositionParams params) async {
    try {
      // Validate position
      if (params.newPosition < 0) {
        throw Exception('Position must be non-negative');
      }
      
      await _repository.updatePosition(params.localId, params.newPosition);
    } catch (e) {
      throw Exception('Failed to update carousel position: ${e.toString()}');
    }
  }
}