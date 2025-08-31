import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/layout_constants.dart';
import '../../../design_system/app_theme.dart';
import '../../../responsive/breakpoints.dart';
import '../molecules/navigation_menu_item.dart';
import 'navigation_header.dart';
import 'navigation_footer.dart';
import '../../../../domain/entities/user.dart';
import '../../../features/navigation/providers/navigation_provider.dart';

class NavigationSidebar extends ConsumerWidget {
  final String currentRoute;
  final User? user;
  final bool isLoading;
  final VoidCallback onLogoutTap;
  
  const NavigationSidebar({
    super.key,
    required this.currentRoute,
    required this.user,
    this.isLoading = false,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationItems = ref.watch(visibleNavigationItemsProvider);
    
    return Container(
      width: LayoutConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: LayoutConstants.opacityLight),
            blurRadius: LayoutConstants.shadowBlurMedium,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const NavigationHeader(),
          
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
          
          NavigationFooter(onLogoutTap: onLogoutTap),
        ],
      ),
    );
  }
}