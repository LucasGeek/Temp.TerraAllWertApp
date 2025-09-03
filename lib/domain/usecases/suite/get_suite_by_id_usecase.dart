import '../../entities/suite.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetSuiteByIdParams {
  final String localId;
  
  GetSuiteByIdParams({required this.localId});
}

class GetSuiteByIdUseCase implements UseCase<Suite?, GetSuiteByIdParams> {
  final TowerRepository _towerRepository;
  
  GetSuiteByIdUseCase(this._towerRepository);
  
  @override
  Future<Suite?> call(GetSuiteByIdParams params) async {
    try {
      return await _towerRepository.getSuiteById(params.localId);
    } catch (e) {
      throw Exception('Failed to get suite by ID: ${e.toString()}');
    }
  }
}