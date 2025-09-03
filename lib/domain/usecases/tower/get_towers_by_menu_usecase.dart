import '../../entities/tower.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetTowersByMenuParams {
  final String menuLocalId;
  
  GetTowersByMenuParams({required this.menuLocalId});
}

class GetTowersByMenuUseCase implements UseCase<List<Tower>, GetTowersByMenuParams> {
  final TowerRepository _towerRepository;
  
  GetTowersByMenuUseCase(this._towerRepository);
  
  @override
  Future<List<Tower>> call(GetTowersByMenuParams params) async {
    try {
      return await _towerRepository.getByMenuIdLocal(params.menuLocalId);
    } catch (e) {
      throw Exception('Failed to get towers by menu: ${e.toString()}');
    }
  }
}