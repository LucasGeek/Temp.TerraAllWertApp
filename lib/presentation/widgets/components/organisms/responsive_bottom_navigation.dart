import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';

class ResponsiveBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  
  const ResponsiveBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.business_outlined),
      activeIcon: Icon(Icons.business),
      label: 'Torres',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.apartment_outlined),
      activeIcon: Icon(Icons.apartment),
      label: 'Apartamentos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite_outline),
      activeIcon: Icon(Icons.favorite),
      label: 'Favoritos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  static const List<String> _routes = [
    '/dashboard',
    '/towers', 
    '/apartments',
    '/favorites',
    '/profile'
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondary,
      backgroundColor: Colors.white,
      elevation: LayoutConstants.elevationHigh,
      items: _items,
      onTap: (index) {
        onTap(index);
        context.go(_routes[index]);
      },
    );
  }
}