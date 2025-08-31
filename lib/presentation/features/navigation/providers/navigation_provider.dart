import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/navigation_item.dart';

final navigationItemsProvider = StateNotifierProvider<NavigationNotifier, List<NavigationItem>>(
  (ref) => NavigationNotifier(),
);

class NavigationNotifier extends StateNotifier<List<NavigationItem>> {
  NavigationNotifier() : super(_getDefaultNavigationItems());

  static List<NavigationItem> _getDefaultNavigationItems() {
    return [
      const NavigationItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/dashboard',
        order: 0,
      ),
      const NavigationItem(
        id: 'towers',
        label: 'Torres',
        icon: Icons.business_outlined,
        selectedIcon: Icons.business,
        route: '/towers',
        order: 1,
      ),
      const NavigationItem(
        id: 'apartments',
        label: 'Apartamentos',
        icon: Icons.apartment_outlined,
        selectedIcon: Icons.apartment,
        route: '/apartments',
        order: 2,
      ),
      const NavigationItem(
        id: 'favorites',
        label: 'Favoritos',
        icon: Icons.favorite_outline,
        selectedIcon: Icons.favorite,
        route: '/favorites',
        order: 3,
      ),
      const NavigationItem(
        id: 'profile',
        label: 'Perfil',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        route: '/profile',
        order: 4,
      ),
    ];
  }

  /// Adiciona um novo item de navegação
  void addNavigationItem(NavigationItem item) {
    state = [...state, item]..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Remove um item de navegação pelo ID
  void removeNavigationItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  /// Atualiza um item de navegação existente
  void updateNavigationItem(NavigationItem updatedItem) {
    state = state.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Reordena os itens de navegação
  void reorderNavigationItems(List<NavigationItem> reorderedItems) {
    final updatedItems = reorderedItems.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();
    
    state = updatedItems;
  }

  /// Ativa/desativa um item de navegação
  void toggleNavigationItem(String id, {bool? isVisible, bool? isEnabled}) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(
          isVisible: isVisible ?? item.isVisible,
          isEnabled: isEnabled ?? item.isEnabled,
        );
      }
      return item;
    }).toList();
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
  void resetToDefault() {
    state = _getDefaultNavigationItems();
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