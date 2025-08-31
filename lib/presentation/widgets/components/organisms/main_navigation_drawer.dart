import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';
import '../molecules/navigation_menu_item.dart';
import 'navigation_header.dart';
import 'navigation_footer.dart';
import '../../../../domain/entities/user.dart';
import '../../../features/navigation/providers/navigation_provider.dart';

/// Drawer de navegação principal da aplicação
/// Versão sem conflito de nomes com NavigationDrawer do Flutter
class MainNavigationDrawer extends ConsumerWidget {
  final String currentRoute;
  final User? user;
  final bool isLoading;
  final VoidCallback onLogoutTap;
  
  const MainNavigationDrawer({
    super.key,
    required this.currentRoute,
    required this.user,
    this.isLoading = false,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final navigationItems = ref.watch(visibleNavigationItemsProvider);
      
      return Drawer(
        child: Column(
          children: [
            const NavigationHeader(),
            _buildNavigationList(context, navigationItems),
            NavigationFooter(onLogoutTap: onLogoutTap),
          ],
        ),
      );
    } catch (e) {
      debugPrint('MainNavigationDrawer: Error building drawer - $e');
      return _buildFallbackDrawer();
    }
  }


  Widget _buildNavigationList(BuildContext context, List<dynamic> navigationItems) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.symmetric(
          vertical: LayoutConstants.paddingXs,
        ),
        children: navigationItems.map((item) {
          final isSelected = item.route == currentRoute;
          
          return NavigationMenuItem(
            icon: item.icon,
            selectedIcon: item.selectedIcon,
            label: item.label,
            isSelected: isSelected,
            onTap: () => _handleNavigation(context, item.route),
          );
        }).toList(),
      ),
    );
  }


  void _handleNavigation(BuildContext context, String route) {
    try {
      if (context.isMobile || (context.isTablet && context.isXs)) {
        Navigator.of(context).pop();
      }
      context.go(route);
    } catch (e) {
      debugPrint('MainNavigationDrawer: Navigation error - $e');
    }
  }

  Widget _buildFallbackDrawer() {
    return Drawer(
      child: Column(
        children: [
          const NavigationHeader(),
          const Expanded(
            child: Center(
              child: Text(
                'Erro ao carregar navegação',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          NavigationFooter(onLogoutTap: () {}),
        ],
      ),
    );
  }
}