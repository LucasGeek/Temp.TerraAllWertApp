import '../entities/tower.dart';
import '../repositories/tower_repository.dart';

class GetTowersUseCase {
  final TowerRepository _repository;

  const GetTowersUseCase(this._repository);

  Future<List<Tower>> call() async {
    return await _repository.getTowers();
  }
}

class WatchTowersUseCase {
  final TowerRepository _repository;

  const WatchTowersUseCase(this._repository);

  Stream<List<Tower>> call() {
    return _repository.watchTowers();
  }
}