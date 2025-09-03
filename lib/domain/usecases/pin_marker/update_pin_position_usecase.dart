import '../../repositories/pin_marker_repository.dart';
import '../usecase.dart';

class UpdatePinPositionParams {
  final String localId;
  final double x;
  final double y;
  
  UpdatePinPositionParams({
    required this.localId,
    required this.x,
    required this.y,
  });
}

class UpdatePinPositionUseCase implements VoidUseCase<UpdatePinPositionParams> {
  final PinMarkerRepository _repository;
  
  UpdatePinPositionUseCase(this._repository);
  
  @override
  Future<void> call(UpdatePinPositionParams params) async {
    try {
      await _repository.updatePosition(params.localId, params.x, params.y);
    } catch (e) {
      throw Exception('Failed to update pin position: ${e.toString()}');
    }
  }
}