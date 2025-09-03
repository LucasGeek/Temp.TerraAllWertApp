import '../../entities/menu.dart';
import '../../repositories/menu_repository.dart';
import '../usecase.dart';

class CreateMenuParams {
  final String title;
  final String slug;
  final ScreenType screenType;
  final MenuType menuType;
  final String? parentMenuLocalId;
  final int position;
  final String enterpriseLocalId;
  final String? icon;
  final bool isVisible;
  
  CreateMenuParams({
    required this.title,
    required this.slug,
    required this.screenType,
    this.menuType = MenuType.standard,
    this.parentMenuLocalId,
    required this.position,
    required this.enterpriseLocalId,
    this.icon,
    this.isVisible = true,
  });
}

class CreateMenuUseCase implements UseCase<Menu, CreateMenuParams> {
  final MenuRepository _menuRepository;
  
  CreateMenuUseCase(this._menuRepository);
  
  @override
  Future<Menu> call(CreateMenuParams params) async {
    try {
      // Validate menu title
      if (params.title.trim().isEmpty) {
        throw Exception('Menu title cannot be empty');
      }
      
      if (params.slug.trim().isEmpty) {
        throw Exception('Menu slug cannot be empty');
      }
      
      // Create new menu
      final newMenu = Menu(
        localId: '', // Will be set by repository
        enterpriseLocalId: params.enterpriseLocalId,
        title: params.title.trim(),
        slug: params.slug.trim(),
        screenType: params.screenType,
        menuType: params.menuType,
        parentMenuLocalId: params.parentMenuLocalId,
        position: params.position,
        icon: params.icon,
        isVisible: params.isVisible,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Save locally and return
      await _menuRepository.saveLocal(newMenu);
      return newMenu;
    } catch (e) {
      throw Exception('Failed to create menu: ${e.toString()}');
    }
  }
}