import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../domain/entities/menu_types.dart';

abstract class MenuLocalDataSource {
  Future<void> cacheMenus(List<Menu> menus);
  Future<void> cacheMenu(Menu menu);
  Future<List<Menu>> getAllMenus();
  Future<Menu?> getMenuById(String id);
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela});
  Future<List<Menu>> getSubmenus(String menuPaiId);
  Future<void> deleteMenu(String id);
  Future<void> clearAllMenus();
  
  Future<void> cacheMenuFloor(MenuFloor menuFloor);
  Future<MenuFloor?> getMenuFloor(String menuId);
  
  Future<void> cacheMenuCarousel(MenuCarousel menuCarousel);
  Future<MenuCarousel?> getMenuCarousel(String menuId);
  
  Future<void> cacheMenuPin(MenuPin menuPin);
  Future<MenuPin?> getMenuPin(String menuId);
}

class MenuLocalDataSourceImpl implements MenuLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  MenuLocalDataSourceImpl(this._secureStorage);

  static const String _menusKey = 'cached_menus';
  static const String _menuFloorPrefix = 'menu_floor_';
  static const String _menuCarouselPrefix = 'menu_carousel_';
  static const String _menuPinPrefix = 'menu_pin_';

  @override
  Future<void> cacheMenus(List<Menu> menus) async {
    final menusJson = menus.map((menu) => menu.toJson()).toList();
    final jsonString = json.encode(menusJson);
    await _secureStorage.write(key: _menusKey, value: jsonString);
  }

  @override
  Future<void> cacheMenu(Menu menu) async {
    final existingMenus = await getAllMenus();
    final updatedMenus = [...existingMenus];
    
    // Update existing or add new
    final existingIndex = updatedMenus.indexWhere((m) => m.id == menu.id);
    if (existingIndex >= 0) {
      updatedMenus[existingIndex] = menu;
    } else {
      updatedMenus.add(menu);
    }
    
    await cacheMenus(updatedMenus);
  }

  @override
  Future<List<Menu>> getAllMenus() async {
    final jsonString = await _secureStorage.read(key: _menusKey);
    if (jsonString == null) return [];
    
    try {
      final menusJsonList = json.decode(jsonString) as List<dynamic>;
      return menusJsonList.map((menuJson) => Menu.fromJson(menuJson)).toList();
    } catch (e) {
      await clearAllMenus();
      return [];
    }
  }

  @override
  Future<Menu?> getMenuById(String id) async {
    final menus = await getAllMenus();
    try {
      return menus.firstWhere((menu) => menu.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela}) async {
    final menus = await getAllMenus();
    return menus.where((menu) {
      if (menu.tipoMenu != tipoMenu) return false;
      if (tipoTela != null && menu.tipoTela != tipoTela) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Menu>> getSubmenus(String menuPaiId) async {
    final menus = await getAllMenus();
    return menus.where((menu) => menu.menuPaiId == menuPaiId).toList();
  }

  @override
  Future<void> deleteMenu(String id) async {
    final existingMenus = await getAllMenus();
    final filteredMenus = existingMenus.where((menu) => menu.id != id).toList();
    await cacheMenus(filteredMenus);
  }

  @override
  Future<void> clearAllMenus() async {
    await _secureStorage.delete(key: _menusKey);
  }

  @override
  Future<void> cacheMenuFloor(MenuFloor menuFloor) async {
    final jsonString = json.encode(menuFloor.toJson());
    await _secureStorage.write(
      key: '$_menuFloorPrefix${menuFloor.menuId}',
      value: jsonString,
    );
  }

  @override
  Future<MenuFloor?> getMenuFloor(String menuId) async {
    final jsonString = await _secureStorage.read(key: '$_menuFloorPrefix$menuId');
    if (jsonString == null) return null;
    
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return MenuFloor.fromJson(jsonMap);
    } catch (e) {
      await _secureStorage.delete(key: '$_menuFloorPrefix$menuId');
      return null;
    }
  }

  @override
  Future<void> cacheMenuCarousel(MenuCarousel menuCarousel) async {
    final jsonString = json.encode(menuCarousel.toJson());
    await _secureStorage.write(
      key: '$_menuCarouselPrefix${menuCarousel.menuId}',
      value: jsonString,
    );
  }

  @override
  Future<MenuCarousel?> getMenuCarousel(String menuId) async {
    final jsonString = await _secureStorage.read(key: '$_menuCarouselPrefix$menuId');
    if (jsonString == null) return null;
    
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return MenuCarousel.fromJson(jsonMap);
    } catch (e) {
      await _secureStorage.delete(key: '$_menuCarouselPrefix$menuId');
      return null;
    }
  }

  @override
  Future<void> cacheMenuPin(MenuPin menuPin) async {
    final jsonString = json.encode(menuPin.toJson());
    await _secureStorage.write(
      key: '$_menuPinPrefix${menuPin.menuId}',
      value: jsonString,
    );
  }

  @override
  Future<MenuPin?> getMenuPin(String menuId) async {
    final jsonString = await _secureStorage.read(key: '$_menuPinPrefix$menuId');
    if (jsonString == null) return null;
    
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return MenuPin.fromJson(jsonMap);
    } catch (e) {
      await _secureStorage.delete(key: '$_menuPinPrefix$menuId');
      return null;
    }
  }
}

// Provider
final menuLocalDataSourceProvider = Provider<MenuLocalDataSource>((ref) {
  const secureStorage = FlutterSecureStorage();
  return MenuLocalDataSourceImpl(secureStorage);
});