import '../../entities/suite.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetSuitesByFloorParams {
  final String floorLocalId;
  
  GetSuitesByFloorParams({required this.floorLocalId});
}

class GetSuitesByFloorUseCase implements UseCase<List<Suite>, GetSuitesByFloorParams> {
  final TowerRepository _towerRepository;
  
  GetSuitesByFloorUseCase(this._towerRepository);
  
  @override
  Future<List<Suite>> call(GetSuitesByFloorParams params) async {
    try {
      return await _towerRepository.getSuitesByFloorId(params.floorLocalId);
    } catch (e) {
      throw Exception('Failed to get suites by floor: ${e.toString()}');
    }
  }
}