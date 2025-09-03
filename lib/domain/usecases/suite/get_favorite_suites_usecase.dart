import '../../entities/suite.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class GetFavoriteSuitesUseCase implements NoParamsUseCase<List<Suite>> {
  final TowerRepository _towerRepository;
  
  GetFavoriteSuitesUseCase(this._towerRepository);
  
  @override
  Future<List<Suite>> call() async {
    try {
      return await _towerRepository.getFavorites();
    } catch (e) {
      throw Exception('Failed to get favorite suites: ${e.toString()}');
    }
  }
}