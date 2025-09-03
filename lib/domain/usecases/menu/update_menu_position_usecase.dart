import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class UpdateMenuPositionParams {
  final String localId;
  final int newPosition;
  
  UpdateMenuPositionParams({
    required this.localId,
    required this.newPosition,
  });
}

class UpdateMenuPositionUseCase implements VoidUseCase<UpdateMenuPositionParams> {
  final MenuRepository _menuRepository;
  
  UpdateMenuPositionUseCase(this._menuRepository);
  
  @override
  Future<void> call(UpdateMenuPositionParams params) async {
    try {
      // Validate position
      if (params.newPosition < 0) {
        throw Exception('Position must be non-negative');
      }
      
      // Get current menu
      final menu = await _menuRepository.getByIdLocal(params.localId);
      if (menu == null) {
        throw Exception('Menu not found');
      }
      
      // Update position
      final updatedMenu = menu.copyWith(
        position: params.newPosition,
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Save locally
      await _menuRepository.saveLocal(updatedMenu);
    } catch (e) {
      throw Exception('Failed to update menu position: ${e.toString()}');
    }
  }
}