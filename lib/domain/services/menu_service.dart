import '../entities/menu_types.dart';
import '../repositories/menu_repository.dart';

/// Interface do serviço de Menu que implementa as regras de negócio
abstract class MenuService {
  /// Busca todos os menus com hierarquia
  Future<List<Menu>> getAllMenus();
  
  /// Busca um menu específico por ID
  Future<Menu?> getMenuById(String id);
  
  /// Busca menus por tipo
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela});
  
  /// Busca submenus de um menu pai
  Future<List<Menu>> getSubmenus(String menuPaiId);
  
  /// Cria um novo menu com validações
  Future<Menu> createMenu({
    required String title,
    String? description,
    String? icon,
    String? route,
    bool isActive = true,
    required TipoMenu tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  });
  
  /// Atualiza um menu existente
  Future<Menu> updateMenu(String id, {
    String? title,
    String? description,
    String? icon,
    String? route,
    bool? isActive,
    TipoMenu? tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  });
  
  /// Remove um menu
  Future<bool> deleteMenu(String id);
  
  /// Reordena menus
  Future<bool> reorderMenus(List<MenuOrder> orders);
  
  /// Busca configuração específica de pavimento
  Future<MenuFloor?> getMenuFloor(String menuId);
  
  /// Atualiza configuração de pavimento
  Future<MenuFloor> updateMenuFloor(String menuId, MenuFloorInput input);
  
  /// Busca configuração específica de carrossel
  Future<MenuCarousel?> getMenuCarousel(String menuId);
  
  /// Atualiza configuração de carrossel
  Future<MenuCarousel> updateMenuCarousel(String menuId, MenuCarouselInput input);
  
  /// Busca configuração específica de pins
  Future<MenuPin?> getMenuPin(String menuId);
  
  /// Atualiza configuração de pins
  Future<MenuPin> updateMenuPin(String menuId, MenuPinInput input);
  
  /// Gera URL baseada no tipo e hierarquia do menu
  String generateMenuUrl(Menu menu);
  
  /// Valida se a estrutura do menu é válida
  bool validateMenuStructure(Menu menu);
}

/// Implementação do serviço de Menu
class MenuServiceImpl implements MenuService {
  final MenuRepository _repository;
  
  const MenuServiceImpl(this._repository);
  
  @override
  Future<Menu> createMenu({
    required String title,
    String? description,
    String? icon,
    String? route,
    bool isActive = true,
    required TipoMenu tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  }) async {
    // Validação 1: Se tipo_menu = "Padrao", exigir tipo_tela
    if (tipoMenu == TipoMenu.padrao && tipoTela == null) {
      throw MenuValidationException(
        'Menu do tipo "Padrao" deve ter um tipo_tela especificado'
      );
    }
    
    // Validação 2: Se tipo_menu = "Com Submenu", não permitir tipo_tela
    if (tipoMenu == TipoMenu.comSubmenu && tipoTela != null) {
      throw MenuValidationException(
        'Menu do tipo "Com Submenu" não pode ter tipo_tela'
      );
    }
    
    // Validação 3: Se menuPaiId fornecido, validar que é "Com Submenu"
    if (menuPaiId != null) {
      final menuPai = await getMenuById(menuPaiId);
      if (menuPai == null) {
        throw MenuValidationException('Menu pai não encontrado: $menuPaiId');
      }
      
      if (menuPai.tipoMenu != TipoMenu.comSubmenu) {
        throw MenuValidationException(
          'Menu pai deve ser do tipo "Com Submenu"'
        );
      }
      
      // Validação 4: Só menus "Padrao" podem ter menu pai
      if (tipoMenu != TipoMenu.padrao) {
        throw MenuValidationException(
          'Apenas menus do tipo "Padrao" podem ter menu pai'
        );
      }
    }
    
    // Criar o menu
    final menu = Menu(
      id: _generateUUID(),
      title: title,
      description: description,
      icon: icon,
      route: route,
      isActive: isActive,
      tipoMenu: tipoMenu,
      tipoTela: tipoTela,
      menuPaiId: menuPaiId,
      posicao: posicao,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Salvar menu (TODO: implementar com repository)
    // final savedMenu = await _menuRepository.save(menu);
    
    // Se for menu "Padrao" com tipo_tela, criar registro na tabela específica
    if (tipoMenu == TipoMenu.padrao && tipoTela != null) {
      await _createTypeSpecificRecord(menu.id, tipoTela);
    }
    
    return menu;
  }
  
  @override
  String generateMenuUrl(Menu menu) {
    final List<String> segments = [];
    
    // Adicionar título do menu pai se existir
    if (menu.menuPai != null) {
      segments.add(_sanitizeForUrl(menu.menuPai!.title));
    }
    
    // Adicionar prefixo baseado no tipo de tela
    segments.add('menus');
    
    if (menu.tipoTela != null) {
      switch (menu.tipoTela!) {
        case TipoTela.pavimento:
          segments.add('floor');
          break;
        case TipoTela.padrao:
          segments.add('carousel');
          break;
        case TipoTela.pins:
          segments.add('pin');
          break;
      }
    }
    
    // Adicionar título do menu atual
    segments.add(_sanitizeForUrl(menu.title));
    
    return '/${segments.join('/')}';
  }
  
  @override
  bool validateMenuStructure(Menu menu) {
    // Validação 1: tipo_menu e tipo_tela
    if (menu.tipoMenu == TipoMenu.padrao && menu.tipoTela == null) {
      return false;
    }
    
    if (menu.tipoMenu == TipoMenu.comSubmenu && menu.tipoTela != null) {
      return false;
    }
    
    // Validação 2: menu_pai_id
    if (menu.menuPaiId != null && menu.tipoMenu != TipoMenu.padrao) {
      return false;
    }
    
    return true;
  }
  
  /// Cria registro específico baseado no tipo de tela
  Future<void> _createTypeSpecificRecord(String menuId, TipoTela tipoTela) async {
    switch (tipoTela) {
      case TipoTela.pavimento:
        // TODO: Criar registro na tabela menu_floor
        break;
      case TipoTela.padrao:
        // TODO: Criar registro na tabela menu_carousel
        break;
      case TipoTela.pins:
        // TODO: Criar registro na tabela menu_pin
        break;
    }
  }
  
  /// Sanitiza string para URL
  String _sanitizeForUrl(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }
  
  /// Gera UUID (implementação temporária)
  String _generateUUID() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  // Implementações dos outros métodos usando repository
  @override
  Future<List<Menu>> getAllMenus() async {
    return await _repository.getAllMenus();
  }
  
  @override
  Future<Menu?> getMenuById(String id) async {
    return await _repository.getMenuById(id);
  }
  
  @override
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela}) async {
    return await _repository.getMenusByType(tipoMenu, tipoTela: tipoTela);
  }
  
  @override
  Future<List<Menu>> getSubmenus(String menuPaiId) async {
    return await _repository.getSubmenus(menuPaiId);
  }
  
  @override
  Future<Menu> updateMenu(String id, {
    String? title,
    String? description,
    String? icon,
    String? route,
    bool? isActive,
    TipoMenu? tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  }) async {
    return await _repository.updateMenu(
      id,
      title: title,
      description: description,
      icon: icon,
      route: route,
      isActive: isActive,
      tipoMenu: tipoMenu,
      tipoTela: tipoTela,
      menuPaiId: menuPaiId,
      posicao: posicao,
    );
  }
  
  @override
  Future<bool> deleteMenu(String id) async {
    return await _repository.deleteMenu(id);
  }
  
  @override
  Future<bool> reorderMenus(List<MenuOrder> orders) async {
    return await _repository.reorderMenus(orders);
  }
  
  @override
  Future<MenuFloor?> getMenuFloor(String menuId) async {
    return await _repository.getMenuFloor(menuId);
  }
  
  @override
  Future<MenuFloor> updateMenuFloor(String menuId, MenuFloorInput input) async {
    return await _repository.updateMenuFloor(menuId, input);
  }
  
  @override
  Future<MenuCarousel?> getMenuCarousel(String menuId) async {
    return await _repository.getMenuCarousel(menuId);
  }
  
  @override
  Future<MenuCarousel> updateMenuCarousel(String menuId, MenuCarouselInput input) async {
    return await _repository.updateMenuCarousel(menuId, input);
  }
  
  @override
  Future<MenuPin?> getMenuPin(String menuId) async {
    return await _repository.getMenuPin(menuId);
  }
  
  @override
  Future<MenuPin> updateMenuPin(String menuId, MenuPinInput input) async {
    return await _repository.updateMenuPin(menuId, input);
  }
}

/// Classes auxiliares
class MenuValidationException implements Exception {
  final String message;
  MenuValidationException(this.message);
  
  @override
  String toString() => 'MenuValidationException: $message';
}