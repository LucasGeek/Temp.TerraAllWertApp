import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/user.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../features/navigation/providers/navigation_provider.dart';
import '../../../responsive/breakpoints.dart';
import '../molecules/navigation_item.dart';
import 'navigation_footer.dart';
import 'navigation_header.dart';

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
    try {
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

            _buildNavigationList(context, navigationItems),

            NavigationFooter(onLogoutTap: onLogoutTap, shouldCloseDrawer: true),
          ],
        ),
      );
    } catch (e) {
      debugPrint('NavigationSidebar: Error building sidebar - $e');
      return _buildFallbackSidebar();
    }
  }

  Widget _buildNavigationList(BuildContext context, List<dynamic> navigationItems) {
    try {
      debugPrint(
        'NavigationSidebar: Building navigation list with ${navigationItems.length} items',
      );

      // Estado vazio com feedback melhorado
      if (navigationItems.isEmpty) {
        return _buildEmptyState();
      }

      // Organizar items hierarquicamente
      final List<Widget> menuWidgets = [];
      
      // Primeiro, adicionar menus de nível raiz
      final rootItems = navigationItems.where((item) => item.parentId == null).toList();
      
      for (final rootItem in rootItems) {
        // Verificar se tem submenus
        final subItems = navigationItems.where((item) => item.parentId == rootItem.id).toList();
        
        if (subItems.isEmpty) {
          // Menu sem submenus - renderizar normalmente
          final isSelected = _isRouteActive(rootItem.route, currentRoute);
          menuWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: AppNavigationItem.sidebar(
                icon: rootItem.icon,
                selectedIcon: rootItem.selectedIcon,
                label: rootItem.label,
                isSelected: isSelected,
                onTap: () => _handleNavigation(context, _cleanRoute(rootItem.route)),
              ),
            ),
          );
        } else {
          // Menu com submenus - renderizar como expansível
          menuWidgets.add(
            _buildExpandableMenuItem(context, rootItem, subItems),
          );
        }
      }

      return Expanded(
        child: ListView(
          padding: EdgeInsets.symmetric(
            vertical: LayoutConstants.paddingXs,
            horizontal: LayoutConstants.paddingXs,
          ),
          physics: const BouncingScrollPhysics(),
          children: menuWidgets,
        ),
      );
    } catch (e) {
      debugPrint('NavigationSidebar: Error building navigation list - $e');
      return _buildErrorState();
    }
  }

  /// Estado vazio melhorado com ícone visual
  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu,
              size: LayoutConstants.iconXLarge,
              color: AppTheme.onPrimary.withValues(alpha: 0.4),
            ),
            SizedBox(height: LayoutConstants.marginMd),
            Text(
              'Nenhum item de navegação disponível',
              style: TextStyle(
                color: AppTheme.onPrimary.withValues(alpha: 0.7),
                fontSize: LayoutConstants.fontSizeMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: LayoutConstants.marginSm),
            Text(
              'Verifique sua conexão ou recarregue a página',
              style: TextStyle(
                color: AppTheme.onPrimary.withValues(alpha: 0.5),
                fontSize: LayoutConstants.fontSizeSmall,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Estado de erro melhorado com ação de retry
  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: LayoutConstants.iconXLarge,
              color: AppTheme.errorColor.withValues(alpha: 0.6),
            ),
            SizedBox(height: LayoutConstants.marginMd),
            Text(
              'Erro ao carregar navegação',
              style: TextStyle(
                color: AppTheme.onPrimary,
                fontSize: LayoutConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: LayoutConstants.marginSm),
            Text(
              'Toque para tentar novamente',
              style: TextStyle(
                color: AppTheme.onPrimary.withValues(alpha: 0.7),
                fontSize: LayoutConstants.fontSizeSmall,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Detecção melhorada de rota ativa baseada no sistema legado
  bool _isRouteActive(String itemRoute, String currentRoute) {
    // Limpar rotas para comparação
    final cleanItemRoute = _cleanRoute(itemRoute);
    final cleanCurrentRoute = _cleanRoute(currentRoute);
    
    // Exact match tem prioridade
    if (cleanCurrentRoute == cleanItemRoute) {
      return true;
    }
    
    // Para rotas nested, verificar se a rota atual contém a rota do item
    if (cleanCurrentRoute.isNotEmpty && cleanItemRoute.isNotEmpty) {
      // Verificar se é uma rota parent (ex: /torre1 ativo quando em /torre1/apartamentos)
      return cleanCurrentRoute.startsWith('$cleanItemRoute/') ||
             cleanCurrentRoute.contains(cleanItemRoute.replaceAll('/', ''));
    }
    
    return false;
  }

  /// Limpeza e normalização de rotas baseada no sistema legado
  String _cleanRoute(String route) {
    if (route.isEmpty) return route;
    
    // Remove múltiplas barras e normaliza
    String cleaned = route.replaceAll(RegExp(r'/+'), '/').trim();
    
    // Garante que comece com /
    if (!cleaned.startsWith('/')) {
      cleaned = '/$cleaned';
    }
    
    // Remove barra final se não for root
    if (cleaned.length > 1 && cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    return cleaned;
  }

  void _handleNavigation(BuildContext context, String route) {
    try {
      // Sempre fechar drawer em mobile/tablet quando clicar em item de navegação
      if (context.isMobile || (context.isTablet && context.isXs)) {
        Navigator.of(context).pop();
      }
      context.go(route);
    } catch (e) {
      debugPrint('NavigationSidebar: Navigation error - $e');
    }
  }

  Widget _buildExpandableMenuItem(BuildContext context, dynamic rootItem, List<dynamic> subItems) {
    final isAnySubItemActive = subItems.any((subItem) => _isRouteActive(subItem.route, currentRoute));
    final isRootActive = _isRouteActive(rootItem.route, currentRoute);
    final shouldExpand = isAnySubItemActive || isRootActive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ExpansionTile(
        initiallyExpanded: shouldExpand,
        leading: Icon(
          rootItem.icon,
          color: (isRootActive || isAnySubItemActive) 
              ? AppTheme.onPrimary 
              : AppTheme.onPrimary.withValues(alpha: 0.7),
          size: LayoutConstants.iconMedium,
        ),
        title: Text(
          rootItem.label,
          style: TextStyle(
            color: (isRootActive || isAnySubItemActive) 
                ? AppTheme.onPrimary 
                : AppTheme.onPrimary.withValues(alpha: 0.8),
            fontSize: LayoutConstants.fontSizeMedium,
            fontWeight: (isRootActive || isAnySubItemActive) 
                ? FontWeight.w600 
                : FontWeight.w400,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        childrenPadding: const EdgeInsets.only(left: 32.0),
        iconColor: AppTheme.onPrimary.withValues(alpha: 0.8),
        collapsedIconColor: AppTheme.onPrimary.withValues(alpha: 0.8),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        onExpansionChanged: (expanded) {
          // Opcional: lógica adicional quando expandir/recolher
        },
        children: subItems.map((subItem) {
          final isSubItemSelected = _isRouteActive(subItem.route, currentRoute);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0),
            child: AppNavigationItem.sidebar(
              icon: subItem.icon,
              selectedIcon: subItem.selectedIcon,
              label: subItem.label,
              isSelected: isSubItemSelected,
              isSubmenuItem: true,
              onTap: () => _handleNavigation(context, _cleanRoute(subItem.route)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFallbackSidebar() {
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
          const Expanded(
            child: Center(
              child: Text(
                'Erro ao carregar navegação',
                style: TextStyle(fontSize: 16, color: AppTheme.onPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          NavigationFooter(onLogoutTap: () {}, shouldCloseDrawer: true),
        ],
      ),
    );
  }
}
