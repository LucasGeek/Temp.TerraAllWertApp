import '../../entities/tower.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetTowerByIdParams {
  final String localId;
  
  GetTowerByIdParams({required this.localId});
}

class GetTowerByIdUseCase implements UseCase<Tower?, GetTowerByIdParams> {
  final TowerRepository _towerRepository;
  
  GetTowerByIdUseCase(this._towerRepository);
  
  @override
  Future<Tower?> call(GetTowerByIdParams params) async {
    try {
      return await _towerRepository.getById(params.localId);
    } catch (e) {
      throw Exception('Failed to get tower by ID: ${e.toString()}');
    }
  }
}