import '../../entities/tower.dart';
import '../../repositories/tower_repository.dart';

class UpdateTowerUseCase {
  final TowerRepository _repository;
  
  UpdateTowerUseCase(this._repository);
  
  Future<Tower> call(Tower tower) async {
    try {
      // Validate tower data
      if (tower.title.isEmpty) {
        throw Exception('Tower title is required');
      }
      
      if (tower.menuLocalId.isEmpty) {
        throw Exception('Menu is required');
      }
      
      // Update tower
      final updatedTower = await _repository.update(tower);
      return updatedTower;
    } catch (e) {
      throw Exception('Failed to update tower: ${e.toString()}');
    }
  }
}