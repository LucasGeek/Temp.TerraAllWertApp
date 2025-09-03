import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class ToggleFavoriteSuiteParams {
  final String suiteLocalId;
  
  ToggleFavoriteSuiteParams({required this.suiteLocalId});
}

class ToggleFavoriteSuiteUseCase implements VoidUseCase<ToggleFavoriteSuiteParams> {
  final TowerRepository _towerRepository;
  
  ToggleFavoriteSuiteUseCase(this._towerRepository);
  
  @override
  Future<void> call(ToggleFavoriteSuiteParams params) async {
    try {
      await _towerRepository.toggleFavorite(params.suiteLocalId);
    } catch (e) {
      throw Exception('Failed to toggle favorite suite: ${e.toString()}');
    }
  }
}