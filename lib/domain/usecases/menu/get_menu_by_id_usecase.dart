import '../../entities/menu.dart';
import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class GetMenuByIdParams {
  final String localId;
  
  GetMenuByIdParams({required this.localId});
}

class GetMenuByIdUseCase implements UseCase<Menu?, GetMenuByIdParams> {
  final MenuRepository _menuRepository;
  
  GetMenuByIdUseCase(this._menuRepository);
  
  @override
  Future<Menu?> call(GetMenuByIdParams params) async {
    try {
      return await _menuRepository.getByIdLocal(params.localId);
    } catch (e) {
      throw Exception('Failed to get menu: ${e.toString()}');
    }
  }
}