import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import '../../domain/entities/menu_types.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_remote_datasource.dart';
import '../../infra/logging/app_logger.dart';

/// Implementação do repositório de menus usando get_storage para cache local
class MenuRepositoryImpl implements MenuRepository {
  final MenuRemoteDataSource _remoteDataSource;
  final GetStorage _storage;
  
  static const String _menusKey = 'cached_menus';
  static const String _lastSyncKey = 'menus_last_sync';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  final StreamController<List<Menu>> _menusController = StreamController<List<Menu>>.broadcast();

  MenuRepositoryImpl({
    required MenuRemoteDataSource remoteDataSource,
    required GetStorage storage,
  }) : _remoteDataSource = remoteDataSource,
       _storage = storage;

  @override
  Future<List<Menu>> getAllMenus() async {
    try {
      // OFFLINE FIRST: Get local data immediately
      final localMenus = await _getLocalMenus();
      
      // Return local data immediately for better UX
      if (localMenus.isNotEmpty) {
        _menusController.add(localMenus);
        
        // Check if cache is still valid
        if (await _isCacheValid()) {
          AppLogger.debug('Using valid cached menus', tag: 'MenuRepository');
          return localMenus;
        }
      }

      // Try to sync in background
      _syncInBackground();
      
      return localMenus;
    } catch (e) {
      AppLogger.error('Failed to get menus: $e', tag: 'MenuRepository');
      return [];
    }
  }

  @override
  Future<Menu?> getMenuById(String id) async {
    try {
      final menus = await getAllMenus();
      return menus.where((menu) => menu.id == id).firstOrNull;
    } catch (e) {
      AppLogger.error('Failed to get menu by id $id: $e', tag: 'MenuRepository');
      return null;
    }
  }

  @override
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela}) async {
    try {
      final menus = await getAllMenus();
      return menus.where((menu) {
        if (menu.tipoMenu != tipoMenu) return false;
        if (tipoTela != null && menu.tipoTela != tipoTela) return false;
        return true;
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get menus by type: $e', tag: 'MenuRepository');
      return [];
    }
  }

  @override
  Future<List<Menu>> getSubmenus(String menuPaiId) async {
    try {
      final menus = await getAllMenus();
      return menus.where((menu) => menu.menuPaiId == menuPaiId).toList();
    } catch (e) {
      AppLogger.error('Failed to get submenus: $e', tag: 'MenuRepository');
      return [];
    }
  }

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
    try {
      // Create menu object
      final menu = Menu(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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

      // Create remotely
      await _remoteDataSource.createMenu(
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
      
      // Update local cache
      final menus = await _getLocalMenus();
      menus.add(menu);
      await _saveLocalMenus(menus);
      
      _menusController.add(menus);
      AppLogger.info('Menu created: ${menu.id}', tag: 'MenuRepository');
      return menu;
    } catch (e) {
      AppLogger.error('Failed to create menu: $e', tag: 'MenuRepository');
      rethrow;
    }
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
    try {
      // Get current menu
      final currentMenu = await getMenuById(id);
      if (currentMenu == null) {
        throw Exception('Menu not found: $id');
      }

      // Create updated menu
      final updatedMenu = currentMenu.copyWith(
        title: title ?? currentMenu.title,
        description: description ?? currentMenu.description,
        icon: icon ?? currentMenu.icon,
        route: route ?? currentMenu.route,
        isActive: isActive ?? currentMenu.isActive,
        tipoMenu: tipoMenu ?? currentMenu.tipoMenu,
        tipoTela: tipoTela ?? currentMenu.tipoTela,
        menuPaiId: menuPaiId ?? currentMenu.menuPaiId,
        posicao: posicao ?? currentMenu.posicao,
        updatedAt: DateTime.now(),
      );

      // Update remotely - pass individual parameters
      await _remoteDataSource.updateMenu(
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
      
      // Update local cache
      final menus = await _getLocalMenus();
      final index = menus.indexWhere((m) => m.id == id);
      if (index != -1) {
        menus[index] = updatedMenu;
        await _saveLocalMenus(menus);
        _menusController.add(menus);
      }
      
      AppLogger.info('Menu updated: $id', tag: 'MenuRepository');
      return updatedMenu;
    } catch (e) {
      AppLogger.error('Failed to update menu: $e', tag: 'MenuRepository');
      rethrow;
    }
  }

  @override
  Future<bool> deleteMenu(String id) async {
    try {
      // Delete remotely
      await _remoteDataSource.deleteMenu(id);
      
      // Update local cache
      final menus = await _getLocalMenus();
      final initialLength = menus.length;
      menus.removeWhere((menu) => menu.id == id);
      
      if (menus.length < initialLength) {
        await _saveLocalMenus(menus);
        _menusController.add(menus);
        AppLogger.info('Menu deleted: $id', tag: 'MenuRepository');
        return true;
      } else {
        AppLogger.warning('Menu not found for deletion: $id', tag: 'MenuRepository');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to delete menu: $e', tag: 'MenuRepository');
      return false;
    }
  }

  @override
  Future<bool> reorderMenus(List<MenuOrder> orders) async {
    try {
      // Get current menus
      final menus = await _getLocalMenus();
      
      // Update positions based on orders
      for (final order in orders) {
        final menuIndex = menus.indexWhere((m) => m.id == order.id);
        if (menuIndex != -1) {
          menus[menuIndex] = menus[menuIndex].copyWith(posicao: order.posicao);
        }
      }
      
      // Sort by position
      menus.sort((a, b) => (a.posicao ?? 0).compareTo(b.posicao ?? 0));
      
      // Update remotely (convert to MenuOrder for remote call)
      await _remoteDataSource.reorderMenus(orders);
      
      // Update local cache
      await _saveLocalMenus(menus);
      _menusController.add(menus);
      
      AppLogger.info('Menus reordered', tag: 'MenuRepository');
      return true;
    } catch (e) {
      AppLogger.error('Failed to reorder menus: $e', tag: 'MenuRepository');
      return false;
    }
  }

  @override
  Future<MenuFloor?> getMenuFloor(String menuId) async {
    try {
      // For now, return null as this feature isn't implemented yet
      // In a real implementation, this would fetch from remote or local storage
      AppLogger.warning('getMenuFloor not implemented yet', tag: 'MenuRepository');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get menu floor: $e', tag: 'MenuRepository');
      return null;
    }
  }

  @override
  Future<MenuFloor> updateMenuFloor(String menuId, MenuFloorInput input) async {
    try {
      // For now, create a basic MenuFloor object
      // In a real implementation, this would update remote and local storage
      final menuFloor = MenuFloor(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        menuId: menuId,
        layoutJson: input.layoutJson,
        zoomDefault: input.zoomDefault ?? 1.0,
        allowZoom: input.allowZoom ?? true,
        showGrid: input.showGrid ?? false,
        gridSize: input.gridSize ?? 20,
        backgroundColor: input.backgroundColor ?? '#FFFFFF',
        floorCount: input.floorCount ?? 1,
        defaultFloor: input.defaultFloor ?? 0,
        floorLabels: input.floorLabels ?? [],
      );
      
      AppLogger.warning('updateMenuFloor not fully implemented yet', tag: 'MenuRepository');
      return menuFloor;
    } catch (e) {
      AppLogger.error('Failed to update menu floor: $e', tag: 'MenuRepository');
      rethrow;
    }
  }

  @override
  Future<MenuCarousel?> getMenuCarousel(String menuId) async {
    try {
      // For now, return null as this feature isn't implemented yet
      // In a real implementation, this would fetch from remote or local storage
      AppLogger.warning('getMenuCarousel not implemented yet', tag: 'MenuRepository');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get menu carousel: $e', tag: 'MenuRepository');
      return null;
    }
  }

  @override
  Future<MenuCarousel> updateMenuCarousel(String menuId, MenuCarouselInput input) async {
    try {
      // For now, create a basic MenuCarousel object
      // In a real implementation, this would update remote and local storage
      final menuCarousel = MenuCarousel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        menuId: menuId,
        images: input.images ?? [],
        transitionTime: input.transitionTime ?? 3000,
        transitionType: input.transitionType ?? 'slide',
        autoPlay: input.autoPlay ?? true,
        showIndicators: input.showIndicators ?? true,
        showArrows: input.showArrows ?? true,
        allowSwipe: input.allowSwipe ?? true,
        infiniteLoop: input.infiniteLoop ?? true,
        aspectRatio: input.aspectRatio ?? '16:9',
      );
      
      AppLogger.warning('updateMenuCarousel not fully implemented yet', tag: 'MenuRepository');
      return menuCarousel;
    } catch (e) {
      AppLogger.error('Failed to update menu carousel: $e', tag: 'MenuRepository');
      rethrow;
    }
  }

  @override
  Future<MenuPin?> getMenuPin(String menuId) async {
    try {
      // For now, return null as this feature isn't implemented yet
      // In a real implementation, this would fetch from remote or local storage
      AppLogger.warning('getMenuPin not implemented yet', tag: 'MenuRepository');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get menu pin: $e', tag: 'MenuRepository');
      return null;
    }
  }

  @override
  Future<MenuPin> updateMenuPin(String menuId, MenuPinInput input) async {
    try {
      // For now, create a basic MenuPin object
      // In a real implementation, this would update remote and local storage
      final menuPin = MenuPin(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        menuId: menuId,
        mapConfig: input.mapConfig,
        pinData: input.pinData ?? [],
        backgroundImageUrl: input.backgroundImageUrl,
        mapBounds: input.mapBounds,
        initialZoom: input.initialZoom ?? 1.0,
        minZoom: input.minZoom ?? 0.1,
        maxZoom: input.maxZoom ?? 5.0,
        enableClustering: input.enableClustering ?? false,
        clusterRadius: input.clusterRadius ?? 50,
        pinIconDefault: input.pinIconDefault,
        showPinLabels: input.showPinLabels ?? true,
        enableSearch: input.enableSearch ?? true,
        enableFilters: input.enableFilters ?? true,
      );
      
      AppLogger.warning('updateMenuPin not fully implemented yet', tag: 'MenuRepository');
      return menuPin;
    } catch (e) {
      AppLogger.error('Failed to update menu pin: $e', tag: 'MenuRepository');
      rethrow;
    }
  }

  @override
  Stream<List<Menu>> watchMenus() {
    // Trigger initial load
    getAllMenus();
    return _menusController.stream;
  }

  @override
  Stream<Menu?> watchMenuById(String id) {
    // Create a stream that filters for specific menu ID
    return watchMenus().map((menus) {
      try {
        return menus.where((menu) => menu.id == id).firstOrNull;
      } catch (e) {
        return null;
      }
    });
  }

  Future<void> syncMenus() async {
    try {
      AppLogger.info('Starting manual menu sync', tag: 'MenuRepository');
      
      final remoteMenus = await _remoteDataSource.getAllMenus();
      await _saveLocalMenus(remoteMenus);
      await _updateLastSync();
      
      _menusController.add(remoteMenus);
      AppLogger.info('Menu sync completed', tag: 'MenuRepository');
    } catch (e) {
      AppLogger.error('Failed to sync menus: $e', tag: 'MenuRepository');
      rethrow;
    }
  }

  Future<void> clearCache() async {
    try {
      await _storage.remove(_menusKey);
      await _storage.remove(_lastSyncKey);
      _menusController.add([]);
      AppLogger.info('Menu cache cleared', tag: 'MenuRepository');
    } catch (e) {
      AppLogger.error('Failed to clear menu cache: $e', tag: 'MenuRepository');
    }
  }

  // Private methods

  Future<List<Menu>> _getLocalMenus() async {
    try {
      final data = _storage.read(_menusKey);
      if (data == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Menu.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to read local menus: $e', tag: 'MenuRepository');
      return [];
    }
  }

  Future<void> _saveLocalMenus(List<Menu> menus) async {
    try {
      final jsonList = menus.map((menu) => menu.toJson()).toList();
      await _storage.write(_menusKey, jsonEncode(jsonList));
    } catch (e) {
      AppLogger.error('Failed to save local menus: $e', tag: 'MenuRepository');
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final lastSyncTimestamp = _storage.read(_lastSyncKey);
      if (lastSyncTimestamp == null) return false;
      
      final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
      final now = DateTime.now();
      
      return now.difference(lastSync) < _cacheValidityDuration;
    } catch (e) {
      AppLogger.error('Failed to check cache validity: $e', tag: 'MenuRepository');
      return false;
    }
  }

  Future<void> _updateLastSync() async {
    try {
      await _storage.write(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.error('Failed to update last sync timestamp: $e', tag: 'MenuRepository');
    }
  }

  void _syncInBackground() {
    // Run sync in background without blocking UI
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await syncMenus();
      } catch (e) {
        AppLogger.warning('Background sync failed: $e', tag: 'MenuRepository');
        // Don't rethrow - this is background sync
      }
    });
  }

  Future<void> dispose() async {
    await _menusController.close();
  }
}

/// Provider para GetStorage instance
final menuStorageProvider = Provider<GetStorage>((ref) {
  return GetStorage('menus');
});

/// Provider para MenuRepository
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(
    remoteDataSource: ref.watch(menuRemoteDataSourceProvider),
    storage: ref.watch(menuStorageProvider),
  );
});