import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class DeleteMenuParams {
  final String localId;
  
  DeleteMenuParams({required this.localId});
}

class DeleteMenuUseCase implements VoidUseCase<DeleteMenuParams> {
  final MenuRepository _menuRepository;
  
  DeleteMenuUseCase(this._menuRepository);
  
  @override
  Future<void> call(DeleteMenuParams params) async {
    try {
      // Check if menu exists
      final menu = await _menuRepository.getByIdLocal(params.localId);
      if (menu == null) {
        throw Exception('Menu not found');
      }
      
      // Check if menu has children
      final children = await _menuRepository.getChildrenLocal(params.localId);
      if (children.isNotEmpty) {
        throw Exception('Cannot delete menu with children. Please delete or move children first.');
      }
      
      // Delete menu
      await _menuRepository.deleteLocal(params.localId);
    } catch (e) {
      throw Exception('Failed to delete menu: ${e.toString()}');
    }
  }
}