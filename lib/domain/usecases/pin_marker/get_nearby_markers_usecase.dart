import '../../entities/pin_marker.dart';
import '../../repositories/pin_marker_repository.dart';
import '../usecase.dart';

class GetNearbyMarkersParams {
  final double x;
  final double y;
  final double radius;
  
  GetNearbyMarkersParams({
    required this.x,
    required this.y,
    required this.radius,
  });
}

class GetNearbyMarkersUseCase implements UseCase<List<PinMarker>, GetNearbyMarkersParams> {
  final PinMarkerRepository _repository;
  
  GetNearbyMarkersUseCase(this._repository);
  
  @override
  Future<List<PinMarker>> call(GetNearbyMarkersParams params) async {
    try {
      // Validate parameters
      if (params.radius < 0) {
        throw Exception('Radius must be non-negative');
      }
      
      return await _repository.getNearbyMarkers(
        params.x,
        params.y,
        params.radius,
      );
    } catch (e) {
      throw Exception('Failed to get nearby markers: ${e.toString()}');
    }
  }
}