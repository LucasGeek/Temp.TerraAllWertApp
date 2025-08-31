import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/layout_constants.dart';
import '../../../design_system/app_theme.dart';
import '../../../responsive/breakpoints.dart';
import '../molecules/navigation_menu_item.dart';
import '../molecules/user_profile_footer.dart';
import '../../../../domain/entities/user.dart';
import '../../../features/navigation/providers/navigation_provider.dart';

class NavigationDrawer extends ConsumerWidget {
  final String currentRoute;
  final User? user;
  final bool isLoading;
  final VoidCallback onLogoutTap;
  
  const NavigationDrawer({
    super.key,
    required this.currentRoute,
    required this.user,
    this.isLoading = false,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationItems = ref.watch(visibleNavigationItemsProvider);
    
    return Drawer(
      backgroundColor: AppTheme.primaryColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Row(
              children: [
                Container(
                  width: LayoutConstants.iconXLarge,
                  height: LayoutConstants.iconXLarge,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_work, // Ícone geométrico mais apropriado
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: LayoutConstants.marginSm),
                const Expanded(
                  child: Text(
                    'Terra Allwert',
                    style: TextStyle(
                      color: AppTheme.onPrimary,
                      fontSize: LayoutConstants.fontSizeXXLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
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
                  onTap: () {
                    if (context.isMobile || (context.isTablet && context.isXs)) {
                      Navigator.of(context).pop();
                    }
                    context.go(item.route);
                  },
                );
              }).toList(),
            ),
          ),
          
          UserProfileFooter(
            user: user,
            isLoading: isLoading,
            onLogoutTap: onLogoutTap,
          ),
        ],
      ),
    );
  }
}