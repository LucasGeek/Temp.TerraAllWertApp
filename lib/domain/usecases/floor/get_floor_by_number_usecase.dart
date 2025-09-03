import '../../entities/floor.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetFloorByNumberParams {
  final String towerLocalId;
  final int floorNumber;
  
  GetFloorByNumberParams({
    required this.towerLocalId,
    required this.floorNumber,
  });
}

class GetFloorByNumberUseCase implements UseCase<Floor?, GetFloorByNumberParams> {
  final TowerRepository _towerRepository;
  
  GetFloorByNumberUseCase(this._towerRepository);
  
  @override
  Future<Floor?> call(GetFloorByNumberParams params) async {
    try {
      return await _towerRepository.getFloorByNumber(
        params.towerLocalId,
        params.floorNumber,
      );
    } catch (e) {
      throw Exception('Failed to get floor by number: ${e.toString()}');
    }
  }
}