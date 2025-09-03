import '../../entities/menu.dart';
import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class UpdateMenuParams {
  final String localId;
  final String? name;
  final String? description;
  final String? iconUrl;
  final Map<String, dynamic>? configuration;
  final bool? isActive;
  
  UpdateMenuParams({
    required this.localId,
    this.name,
    this.description,
    this.iconUrl,
    this.configuration,
    this.isActive,
  });
}

class UpdateMenuUseCase implements UseCase<Menu, UpdateMenuParams> {
  final MenuRepository _menuRepository;
  
  UpdateMenuUseCase(this._menuRepository);
  
  @override
  Future<Menu> call(UpdateMenuParams params) async {
    try {
      // Get current menu
      final currentMenu = await _menuRepository.getByIdLocal(params.localId);
      if (currentMenu == null) {
        throw Exception('Menu not found');
      }
      
      // Update menu with new information
      final updatedMenu = currentMenu.copyWith(
        name: params.name?.trim() ?? currentMenu.name,
        description: params.description?.trim() ?? currentMenu.description,
        iconUrl: params.iconUrl ?? currentMenu.iconUrl,
        configuration: params.configuration ?? currentMenu.configuration,
        isActive: params.isActive ?? currentMenu.isActive,
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Validate updated menu
      if (updatedMenu.name?.trim().isEmpty == true) {
        throw Exception('Menu name cannot be empty');
      }
      
      // Save locally
      await _menuRepository.saveLocal(updatedMenu);
      
      return updatedMenu;
    } catch (e) {
      throw Exception('Failed to update menu: ${e.toString()}');
    }
  }
}