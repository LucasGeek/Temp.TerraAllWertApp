import '../../entities/menu.dart';
import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class GetVisibleMenusParams {
  final String enterpriseLocalId;
  
  GetVisibleMenusParams({required this.enterpriseLocalId});
}

class GetVisibleMenusUseCase implements UseCase<List<Menu>, GetVisibleMenusParams> {
  final MenuRepository _menuRepository;
  
  GetVisibleMenusUseCase(this._menuRepository);
  
  @override
  Future<List<Menu>> call(GetVisibleMenusParams params) async {
    try {
      return await _menuRepository.getVisibleMenus(params.enterpriseLocalId);
    } catch (e) {
      throw Exception('Failed to get visible menus: ${e.toString()}');
    }
  }
}