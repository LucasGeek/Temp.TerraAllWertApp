import '../../entities/floor.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class CreateFloorParams {
  final String towerLocalId;
  final int floorNumber;
  final String? floorName;
  final String? bannerFileLocalId;
  final String? floorPlanFileLocalId;
  
  CreateFloorParams({
    required this.towerLocalId,
    required this.floorNumber,
    this.floorName,
    this.bannerFileLocalId,
    this.floorPlanFileLocalId,
  });
}

class CreateFloorUseCase implements UseCase<Floor, CreateFloorParams> {
  final TowerRepository _towerRepository;
  
  CreateFloorUseCase(this._towerRepository);
  
  @override
  Future<Floor> call(CreateFloorParams params) async {
    try {
      // Validate floor data
      if (params.floorNumber < 0) {
        throw Exception('Floor number must be non-negative');
      }
      
      // Check if floor number already exists for this tower
      final existingFloor = await _towerRepository.getFloorByNumber(
        params.towerLocalId, 
        params.floorNumber,
      );
      if (existingFloor != null) {
        throw Exception('Floor number ${params.floorNumber} already exists for this tower');
      }
      
      // Create new floor
      final newFloor = Floor(
        localId: '', // Will be set by repository
        towerLocalId: params.towerLocalId,
        floorNumber: params.floorNumber,
        floorName: params.floorName?.trim(),
        bannerFileLocalId: params.bannerFileLocalId,
        floorPlanFileLocalId: params.floorPlanFileLocalId,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Create floor
      return await _towerRepository.createFloor(newFloor);
    } catch (e) {
      throw Exception('Failed to create floor: ${e.toString()}');
    }
  }
}