import '../../entities/floor.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetFloorsByTowerParams {
  final String towerLocalId;
  
  GetFloorsByTowerParams({required this.towerLocalId});
}

class GetFloorsByTowerUseCase implements UseCase<List<Floor>, GetFloorsByTowerParams> {
  final TowerRepository _towerRepository;
  
  GetFloorsByTowerUseCase(this._towerRepository);
  
  @override
  Future<List<Floor>> call(GetFloorsByTowerParams params) async {
    try {
      return await _towerRepository.getFloorsByTowerId(params.towerLocalId);
    } catch (e) {
      throw Exception('Failed to get floors by tower: ${e.toString()}');
    }
  }
}