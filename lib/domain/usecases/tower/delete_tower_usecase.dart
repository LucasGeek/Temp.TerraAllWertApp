import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class DeleteTowerParams {
  final String localId;
  
  DeleteTowerParams({required this.localId});
}

class DeleteTowerUseCase implements VoidUseCase<DeleteTowerParams> {
  final TowerRepository _towerRepository;
  
  DeleteTowerUseCase(this._towerRepository);
  
  @override
  Future<void> call(DeleteTowerParams params) async {
    try {
      // Check if tower exists
      final tower = await _towerRepository.getById(params.localId);
      if (tower == null) {
        throw Exception('Tower not found');
      }
      
      // Check if tower has floors
      final floors = await _towerRepository.getFloorsByTowerId(params.localId);
      if (floors.isNotEmpty) {
        throw Exception('Cannot delete tower with floors. Please delete floors first.');
      }
      
      // Delete tower
      await _towerRepository.delete(params.localId);
    } catch (e) {
      throw Exception('Failed to delete tower: ${e.toString()}');
    }
  }
}