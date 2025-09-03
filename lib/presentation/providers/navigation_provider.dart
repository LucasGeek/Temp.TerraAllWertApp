import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/menu.dart';
import 'menu_provider.dart';

/// Modelo básico para item de navegação
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final bool isVisible;
  final int order;
  final String? parentId;
  final IconData? selectedIcon;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.isVisible = true,
    required this.order,
    this.parentId,
    this.selectedIcon,
  });
}

/// Helper function para converter Menu em NavigationItem
NavigationItem _menuToNavigationItem(Menu menu) {
  // Mapear ScreenType para ícone
  IconData icon;
  switch (menu.screenType) {
    case ScreenType.carousel:
      icon = Icons.photo_library;
      break;
    case ScreenType.pin:
      icon = Icons.location_on;
      break;
    case ScreenType.floorplan:
      icon = Icons.architecture;
      break;
  }

  // Criar slug para a rota dinâmica baseado no título
  final routeSlug = menu.title.toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  
  return NavigationItem(
    id: menu.localId,
    label: menu.title,
    icon: icon,
    route: '/dynamic/$routeSlug?title=${Uri.encodeComponent(menu.title)}',
    isVisible: menu.isVisible,
    order: menu.position,
    parentId: menu.parentMenuLocalId,
    selectedIcon: icon,
  );
}

/// Provider para itens de navegação baseado nos menus
final navigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  final menuState = ref.watch(menuProvider);
  
  // Se não há menus ou está carregando/erro, retorna lista vazia
  if (menuState.status != MenuStatus.loaded || menuState.menus.isEmpty) {
    return [];
  }

  // Converter menus em NavigationItems
  return menuState.menus
      .map(_menuToNavigationItem)
      .toList();
});

/// Provider para itens de navegação visíveis
final visibleNavigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  final items = ref.watch(navigationItemsProvider);
  return items.where((item) => item.isVisible).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
});