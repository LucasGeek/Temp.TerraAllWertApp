import '../../entities/menu.dart';
import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class GetMenusByEnterpriseParams {
  final String enterpriseLocalId;
  
  GetMenusByEnterpriseParams({required this.enterpriseLocalId});
}

class GetMenusByEnterpriseUseCase implements UseCase<List<Menu>, GetMenusByEnterpriseParams> {
  final MenuRepository _menuRepository;
  
  GetMenusByEnterpriseUseCase(this._menuRepository);
  
  @override
  Future<List<Menu>> call(GetMenusByEnterpriseParams params) async {
    try {
      return await _menuRepository.getByEnterpriseIdLocal(params.enterpriseLocalId);
    } catch (e) {
      throw Exception('Failed to get menus by enterprise: ${e.toString()}');
    }
  }
}