import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/navigation_item.dart';
import '../../infra/storage/menu_storage_service.dart';
import '../../infra/graphql/menu_service.dart';
import '../../infra/logging/app_logger.dart';
import 'connectivity_provider.dart';

/// Estado do gerenciamento de menus
class MenuManagementState {
  final List<NavigationItem> items;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final DateTime? lastSync;

  const MenuManagementState({
    this.items = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.lastSync,
  });

  MenuManagementState copyWith({
    List<NavigationItem>? items,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    DateTime? lastSync,
  }) {
    return MenuManagementState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error ?? this.error,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

/// Provider para gerenciamento completo de menus
class MenuManagementNotifier extends StateNotifier<MenuManagementState> {
  final MenuStorageService _storageService;
  final MenuGraphQLService _graphqlService;
  final Ref _ref;

  MenuManagementNotifier({
    required MenuStorageService storageService,
    required MenuGraphQLService graphqlService,
    required Ref ref,
  })  : _storageService = storageService,
        _graphqlService = graphqlService,
        _ref = ref,
        super(const MenuManagementState()) {
    _initialize();
  }

  /// Inicializa o provider carregando menus locais
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      AppLogger.debug('Initializing menu management provider', tag: 'MenuManagement');
      
      // Carregar menus do storage local
      final localMenus = await _storageService.loadNavigationItems();
      
      state = state.copyWith(
        items: localMenus,
        isLoading: false,
        error: null,
      );
      
      AppLogger.info('Loaded ${localMenus.length} menus from local storage', tag: 'MenuManagement');
      
      // Tentar sincronizar com API em background se online
      final isOnline = _ref.read(isOnlineProvider);
      if (isOnline) {
        _syncWithApiInBackground();
      }
      
    } catch (e) {
      AppLogger.error('Failed to initialize menu management: $e', tag: 'MenuManagement');
      state = state.copyWith(
        isLoading: false,
        error: 'Falha ao carregar menus: $e',
      );
    }
  }

  /// Adiciona novo menu
  Future<NavigationItem?> addMenu(NavigationItem menu) async {
    try {
      AppLogger.info('Adding new menu: ${menu.label}', tag: 'MenuManagement');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // Salvar localmente primeiro (offline-first)
      final updatedItems = List<NavigationItem>.from(state.items)..add(menu);
      await _storageService.saveNavigationItems(updatedItems);
      
      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );
      
      AppLogger.info('Menu added locally: ${menu.id}', tag: 'MenuManagement');
      
      // Sincronizar com API em background se online
      final isOnline = _ref.read(isOnlineProvider);
      if (isOnline) {
        _syncMenuWithApi(menu);
      }
      
      return menu;
      
    } catch (e) {
      AppLogger.error('Failed to add menu: $e', tag: 'MenuManagement');
      state = state.copyWith(
        isLoading: false,
        error: 'Falha ao adicionar menu: $e',
      );
      return null;
    }
  }

  /// Atualiza menu existente
  Future<NavigationItem?> updateMenu(NavigationItem menu) async {
    try {
      AppLogger.info('Updating menu: ${menu.id}', tag: 'MenuManagement');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // Atualizar localmente primeiro
      final updatedItems = state.items.map((item) {
        return item.id == menu.id ? menu : item;
      }).toList();
      
      await _storageService.saveNavigationItems(updatedItems);
      
      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );
      
      AppLogger.info('Menu updated locally: ${menu.id}', tag: 'MenuManagement');
      
      // Sincronizar com API em background se online
      final isOnline = _ref.read(isOnlineProvider);
      if (isOnline) {
        _updateMenuInApi(menu);
      }
      
      return menu;
      
    } catch (e) {
      AppLogger.error('Failed to update menu: $e', tag: 'MenuManagement');
      state = state.copyWith(
        isLoading: false,
        error: 'Falha ao atualizar menu: $e',
      );
      return null;
    }
  }

  /// Remove menu
  Future<bool> deleteMenu(String menuId) async {
    try {
      AppLogger.info('Deleting menu: $menuId', tag: 'MenuManagement');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // Remover localmente primeiro
      final updatedItems = state.items.where((item) => item.id != menuId).toList();
      await _storageService.saveNavigationItems(updatedItems);
      
      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );
      
      AppLogger.info('Menu deleted locally: $menuId', tag: 'MenuManagement');
      
      // Sincronizar com API em background se online
      final isOnline = _ref.read(isOnlineProvider);
      if (isOnline) {
        _deleteMenuInApi(menuId);
      }
      
      return true;
      
    } catch (e) {
      AppLogger.error('Failed to delete menu: $e', tag: 'MenuManagement');
      state = state.copyWith(
        isLoading: false,
        error: 'Falha ao deletar menu: $e',
      );
      return false;
    }
  }

  /// Reordena menus
  Future<void> reorderMenus(List<NavigationItem> orderedItems) async {
    try {
      AppLogger.info('Reordering ${orderedItems.length} menus', tag: 'MenuManagement');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // Atualizar ordem localmente
      await _storageService.saveNavigationItems(orderedItems);
      
      state = state.copyWith(
        items: orderedItems,
        isLoading: false,
      );
      
      AppLogger.info('Menus reordered locally', tag: 'MenuManagement');
      
      // Sincronizar com API em background se online
      final isOnline = _ref.read(isOnlineProvider);
      if (isOnline) {
        _reorderMenusInApi(orderedItems);
      }
      
    } catch (e) {
      AppLogger.error('Failed to reorder menus: $e', tag: 'MenuManagement');
      state = state.copyWith(
        isLoading: false,
        error: 'Falha ao reordenar menus: $e',
      );
    }
  }

  /// Sincronização manual com API
  Future<void> syncWithApi() async {
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) {
      state = state.copyWith(error: 'Sem conexão com internet');
      return;
    }

    state = state.copyWith(isSyncing: true, error: null);
    
    try {
      AppLogger.info('Starting manual sync with API', tag: 'MenuManagement');
      
      // Buscar menus da API
      final apiMenus = await _graphqlService.getMenus(routeId: 'main');
      
      if (apiMenus.isNotEmpty) {
        // Mesclar com menus locais (prioridade para API)
        final mergedMenus = _mergeMenus(state.items, apiMenus);
        
        // Salvar resultado mesclado
        await _storageService.saveNavigationItems(mergedMenus);
        
        state = state.copyWith(
          items: mergedMenus,
          isSyncing: false,
          lastSync: DateTime.now(),
        );
        
        AppLogger.info('Sync completed: ${mergedMenus.length} menus', tag: 'MenuManagement');
      } else {
        state = state.copyWith(isSyncing: false);
        AppLogger.debug('No menus received from API', tag: 'MenuManagement');
      }
      
    } catch (e) {
      AppLogger.error('Failed to sync with API: $e', tag: 'MenuManagement');
      state = state.copyWith(
        isSyncing: false,
        error: 'Falha na sincronização: $e',
      );
    }
  }

  /// Sincronização em background com API
  void _syncWithApiInBackground() {
    Future.microtask(() async {
      try {
        await syncWithApi();
      } catch (e) {
        AppLogger.warning('Background sync failed: $e', tag: 'MenuManagement');
        // Não atualizar estado de erro para sync em background
      }
    });
  }

  /// Sincroniza menu específico com API
  void _syncMenuWithApi(NavigationItem menu) {
    Future.microtask(() async {
      try {
        AppLogger.debug('Syncing menu with API: ${menu.id}', tag: 'MenuManagement');
        await _graphqlService.createMenu(menu);
        AppLogger.info('Menu synced with API: ${menu.id}', tag: 'MenuManagement');
      } catch (e) {
        AppLogger.warning('Failed to sync menu with API: $e', tag: 'MenuManagement');
      }
    });
  }

  /// Atualiza menu na API
  void _updateMenuInApi(NavigationItem menu) {
    Future.microtask(() async {
      try {
        AppLogger.debug('Updating menu in API: ${menu.id}', tag: 'MenuManagement');
        await _graphqlService.updateMenu(menu);
        AppLogger.info('Menu updated in API: ${menu.id}', tag: 'MenuManagement');
      } catch (e) {
        AppLogger.warning('Failed to update menu in API: $e', tag: 'MenuManagement');
      }
    });
  }

  /// Remove menu da API
  void _deleteMenuInApi(String menuId) {
    Future.microtask(() async {
      try {
        AppLogger.debug('Deleting menu in API: $menuId', tag: 'MenuManagement');
        await _graphqlService.deleteMenu(menuId);
        AppLogger.info('Menu deleted in API: $menuId', tag: 'MenuManagement');
      } catch (e) {
        AppLogger.warning('Failed to delete menu in API: $e', tag: 'MenuManagement');
      }
    });
  }

  /// Reordena menus na API
  void _reorderMenusInApi(List<NavigationItem> orderedItems) {
    Future.microtask(() async {
      try {
        AppLogger.debug('Reordering menus in API', tag: 'MenuManagement');
        await _graphqlService.reorderMenus(orderedItems);
        AppLogger.info('Menus reordered in API', tag: 'MenuManagement');
      } catch (e) {
        AppLogger.warning('Failed to reorder menus in API: $e', tag: 'MenuManagement');
      }
    });
  }

  /// Mescla menus locais com menus da API
  List<NavigationItem> _mergeMenus(List<NavigationItem> localMenus, List<NavigationItem> apiMenus) {
    final Map<String, NavigationItem> merged = {};
    
    // Adicionar menus locais primeiro
    for (final menu in localMenus) {
      merged[menu.id] = menu;
    }
    
    // Sobrescrever/adicionar menus da API (prioridade para API)
    for (final menu in apiMenus) {
      merged[menu.id] = menu;
    }
    
    return merged.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Limpa erros
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Recarrega menus do storage local
  Future<void> reload() async {
    await _initialize();
  }
}

// Providers
final menuManagementProvider = StateNotifierProvider<MenuManagementNotifier, MenuManagementState>((ref) {
  final storageService = ref.watch(menuStorageServiceProvider);
  final graphqlService = ref.watch(menuGraphQLServiceProvider);
  
  return MenuManagementNotifier(
    storageService: storageService,
    graphqlService: graphqlService,
    ref: ref,
  );
});

// Providers de conveniência
final menusProvider = Provider<List<NavigationItem>>((ref) {
  return ref.watch(menuManagementProvider).items;
});

final isMenusLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(menuManagementProvider);
  return state.isLoading || state.isSyncing;
});

final menuErrorProvider = Provider<String?>((ref) {
  return ref.watch(menuManagementProvider).error;
});