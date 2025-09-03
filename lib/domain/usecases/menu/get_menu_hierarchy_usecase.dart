import '../../entities/menu.dart';
import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class GetMenuHierarchyParams {
  final String enterpriseLocalId;
  
  GetMenuHierarchyParams({required this.enterpriseLocalId});
}

class GetMenuHierarchyUseCase implements UseCase<List<Menu>, GetMenuHierarchyParams> {
  final MenuRepository _menuRepository;

  GetMenuHierarchyUseCase(this._menuRepository);

  @override
  Future<List<Menu>> call(GetMenuHierarchyParams params) async {
    try {
      return await _menuRepository.buildHierarchy(params.enterpriseLocalId);
    } catch (e) {
      throw Exception('Failed to get menu hierarchy: ${e.toString()}');
    }
  }
}