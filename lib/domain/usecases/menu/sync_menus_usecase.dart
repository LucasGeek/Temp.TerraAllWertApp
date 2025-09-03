import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class SyncMenusParams {
  final String enterpriseId;
  
  SyncMenusParams({required this.enterpriseId});
}

class SyncMenusUseCase implements VoidUseCase<SyncMenusParams> {
  final MenuRepository _menuRepository;
  
  SyncMenusUseCase(this._menuRepository);
  
  @override
  Future<void> call(SyncMenusParams params) async {
    try {
      await _menuRepository.syncWithRemote(params.enterpriseId);
    } catch (e) {
      throw Exception('Failed to sync menus: ${e.toString()}');
    }
  }
}