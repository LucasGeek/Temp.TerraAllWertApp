import '../../entities/floor.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class UpdateFloorParams {
  final String localId;
  final String? floorName;
  final String? bannerFileLocalId;
  final String? floorPlanFileLocalId;
  
  UpdateFloorParams({
    required this.localId,
    this.floorName,
    this.bannerFileLocalId,
    this.floorPlanFileLocalId,
  });
}

class UpdateFloorUseCase implements UseCase<Floor, UpdateFloorParams> {
  final TowerRepository _towerRepository;
  
  UpdateFloorUseCase(this._towerRepository);
  
  @override
  Future<Floor> call(UpdateFloorParams params) async {
    try {
      // Get current floor
      final currentFloor = await _towerRepository.getFloorById(params.localId);
      if (currentFloor == null) {
        throw Exception('Floor not found');
      }
      
      // Update floor with new information
      final updatedFloor = currentFloor.copyWith(
        floorName: params.floorName?.trim() ?? currentFloor.floorName,
        bannerFileLocalId: params.bannerFileLocalId ?? currentFloor.bannerFileLocalId,
        floorPlanFileLocalId: params.floorPlanFileLocalId ?? currentFloor.floorPlanFileLocalId,
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Update floor
      return await _towerRepository.updateFloor(updatedFloor);
    } catch (e) {
      throw Exception('Failed to update floor: ${e.toString()}');
    }
  }
}