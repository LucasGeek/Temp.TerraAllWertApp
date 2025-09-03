import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modelo básico para item de navegação
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final bool isVisible;
  final int order;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.isVisible = true,
    required this.order,
  });
}

/// Provider para itens de navegação (implementação básica temporária)
final navigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  // Lista básica de navegação para não quebrar o router
  return [
    const NavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard,
      route: '/dashboard',
      order: 1,
    ),
    const NavigationItem(
      id: 'search',
      label: 'Busca',
      icon: Icons.search,
      route: '/search',
      order: 2,
    ),
  ];
});

/// Provider para itens de navegação visíveis
final visibleNavigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  final items = ref.watch(navigationItemsProvider);
  return items.where((item) => item.isVisible).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
});