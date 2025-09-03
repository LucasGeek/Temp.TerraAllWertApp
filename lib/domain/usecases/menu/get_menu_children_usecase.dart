import '../../entities/menu.dart';
import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class GetMenuChildrenParams {
  final String parentMenuLocalId;
  
  GetMenuChildrenParams({required this.parentMenuLocalId});
}

class GetMenuChildrenUseCase implements UseCase<List<Menu>, GetMenuChildrenParams> {
  final MenuRepository _menuRepository;
  
  GetMenuChildrenUseCase(this._menuRepository);
  
  @override
  Future<List<Menu>> call(GetMenuChildrenParams params) async {
    try {
      return await _menuRepository.getChildrenLocal(params.parentMenuLocalId);
    } catch (e) {
      throw Exception('Failed to get menu children: ${e.toString()}');
    }
  }
}