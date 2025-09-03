import '../../entities/tower.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class CreateTowerParams {
  final String menuLocalId;
  final String title;
  final String? description;
  final int totalFloors;
  final int? unitsPerFloor;
  final int position;
  
  CreateTowerParams({
    required this.menuLocalId,
    required this.title,
    this.description,
    required this.totalFloors,
    this.unitsPerFloor,
    this.position = 0,
  });
}

class CreateTowerUseCase implements UseCase<Tower, CreateTowerParams> {
  final TowerRepository _towerRepository;
  
  CreateTowerUseCase(this._towerRepository);
  
  @override
  Future<Tower> call(CreateTowerParams params) async {
    try {
      // Validate tower data
      if (params.title.trim().isEmpty) {
        throw Exception('Tower title cannot be empty');
      }
      
      if (params.totalFloors < 0) {
        throw Exception('Total floors must be non-negative');
      }
      
      // Create new tower
      final newTower = Tower(
        localId: '', // Will be set by repository
        menuLocalId: params.menuLocalId,
        title: params.title.trim(),
        description: params.description?.trim(),
        totalFloors: params.totalFloors,
        unitsPerFloor: params.unitsPerFloor,
        position: params.position,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Save locally
      await _towerRepository.saveTowerLocal(newTower);
      return newTower;
    } catch (e) {
      throw Exception('Failed to create tower: ${e.toString()}');
    }
  }
}