import '../../entities/floor.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetFloorByIdParams {
  final String localId;
  
  GetFloorByIdParams({required this.localId});
}

class GetFloorByIdUseCase implements UseCase<Floor?, GetFloorByIdParams> {
  final TowerRepository _towerRepository;
  
  GetFloorByIdUseCase(this._towerRepository);
  
  @override
  Future<Floor?> call(GetFloorByIdParams params) async {
    try {
      return await _towerRepository.getFloorById(params.localId);
    } catch (e) {
      throw Exception('Failed to get floor by ID: ${e.toString()}');
    }
  }
}