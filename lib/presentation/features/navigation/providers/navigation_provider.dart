import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/navigation_item.dart';
import '../../../../infra/storage/menu_storage_service.dart';

final navigationItemsProvider = StateNotifierProvider<NavigationNotifier, List<NavigationItem>>(
  (ref) => NavigationNotifier(ref.read(menuStorageServiceProvider)),
);

class NavigationNotifier extends StateNotifier<List<NavigationItem>> {
  final MenuStorageService _storageService;
  
  NavigationNotifier(this._storageService) : super([]) {
    _loadItemsFromStorage();
  }

  /// Carrega itens do armazenamento local na inicialização
  Future<void> _loadItemsFromStorage() async {
    try {
      final items = await _storageService.loadNavigationItems();
      state = items;
    } catch (e) {
      // Fallback para itens padrão em caso de erro
      state = _getDefaultNavigationItems();
    }
  }

  static List<NavigationItem> _getDefaultNavigationItems() {
    return [
      const NavigationItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/dashboard',
        order: 0,
        description: 'Painel principal da aplicação',
      ),
    ];
  }

  /// Adiciona um novo item de navegação
  Future<void> addNavigationItem(NavigationItem item) async {
    try {
      await _storageService.addNavigationItem(item);
      state = [...state, item]..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      // Fallback para state apenas se storage falhar
      state = [...state, item]..sort((a, b) => a.order.compareTo(b.order));
      rethrow;
    }
  }

  /// Remove um item de navegação pelo ID
  Future<void> removeNavigationItem(String id) async {
    try {
      await _storageService.removeNavigationItem(id);
      state = state.where((item) => item.id != id).toList();
    } catch (e) {
      // Fallback para state apenas se storage falhar
      state = state.where((item) => item.id != id).toList();
      rethrow;
    }
  }

  /// Atualiza um item de navegação existente
  Future<void> updateNavigationItem(NavigationItem updatedItem) async {
    try {
      await _storageService.updateNavigationItem(updatedItem);
      state = state.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList()..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      // Fallback para state apenas se storage falhar
      state = state.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList()..sort((a, b) => a.order.compareTo(b.order));
      rethrow;
    }
  }

  /// Reordena os itens de navegação
  Future<void> reorderNavigationItems(List<NavigationItem> reorderedItems) async {
    try {
      await _storageService.reorderNavigationItems(reorderedItems);
      final updatedItems = reorderedItems.asMap().entries.map((entry) {
        return entry.value.copyWith(order: entry.key);
      }).toList();
      state = updatedItems;
    } catch (e) {
      // Fallback para state apenas se storage falhar
      final updatedItems = reorderedItems.asMap().entries.map((entry) {
        return entry.value.copyWith(order: entry.key);
      }).toList();
      state = updatedItems;
      rethrow;
    }
  }

  /// Ativa/desativa um item de navegação
  Future<void> toggleNavigationItem(String id, {bool? isVisible, bool? isEnabled}) async {
    final updatedState = state.map((item) {
      if (item.id == id) {
        return item.copyWith(
          isVisible: isVisible ?? item.isVisible,
          isEnabled: isEnabled ?? item.isEnabled,
        );
      }
      return item;
    }).toList();

    try {
      await _storageService.saveNavigationItems(updatedState);
      state = updatedState;
    } catch (e) {
      // Fallback para state apenas se storage falhar
      state = updatedState;
      rethrow;
    }
  }

  /// Obtém itens visíveis e habilitados
  List<NavigationItem> getVisibleItems() {
    return state.where((item) => item.isVisible && item.isEnabled).toList();
  }

  /// Encontra um item pelo ID
  NavigationItem? findItemById(String id) {
    try {
      return state.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Encontra um item pela rota
  NavigationItem? findItemByRoute(String route) {
    try {
      return state.firstWhere((item) => item.route == route);
    } catch (e) {
      return null;
    }
  }

  /// Reseta para os itens padrão
  Future<void> resetToDefault() async {
    try {
      await _storageService.resetToDefault();
      state = _getDefaultNavigationItems();
    } catch (e) {
      // Fallback para state apenas se storage falhar
      state = _getDefaultNavigationItems();
      rethrow;
    }
  }

  /// Força reload dos itens do storage
  Future<void> reloadFromStorage() async {
    try {
      final items = await _storageService.loadNavigationItems();
      state = items;
    } catch (e) {
      // Mantém state atual se reload falhar
      rethrow;
    }
  }
}

/// Provider para obter apenas itens visíveis
final visibleNavigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  final allItems = ref.watch(navigationItemsProvider);
  return allItems.where((item) => item.isVisible && item.isEnabled).toList();
});

/// Provider para obter o índice selecionado baseado na rota atual
final selectedNavigationIndexProvider = Provider.family<int, String>((ref, currentRoute) {
  final visibleItems = ref.watch(visibleNavigationItemsProvider);

  for (int i = 0; i < visibleItems.length; i++) {
    if (visibleItems[i].route == currentRoute) {
      return i;
    }
  }

  return 0; // Default to first item if route not found
});
