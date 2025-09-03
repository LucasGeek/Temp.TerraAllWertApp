import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../layout/widgets/organisms/navigation_header.dart';
import '../../../../layout/widgets/organisms/navigation_footer.dart';
import '../../../../providers/navigation_provider.dart' as nav_provider;
import '../../../../../domain/entities/user.dart';
import '../molecules/navigation_item.dart';

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
      final navigationItems = ref.watch(nav_provider.visibleNavigationItemsProvider);

      return Drawer(
        backgroundColor: AppTheme.primaryColor,
        child: Column(
          children: [
            const NavigationHeader(),
            _buildNavigationList(context, navigationItems),
            NavigationFooter(onLogoutTap: onLogoutTap, shouldCloseDrawer: true),
          ],
        ),
      );
    } catch (e) {
      debugPrint('MainNavigationDrawer: Error building drawer - $e');
      return _buildFallbackDrawer();
    }
  }

  Widget _buildNavigationList(BuildContext context, List<nav_provider.NavigationItem> navigationItems) {
    try {
      // Estado vazio com feedback melhorado
      if (navigationItems.isEmpty) {
        return _buildEmptyState();
      }

      return Expanded(
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: LayoutConstants.paddingXs,
            horizontal: LayoutConstants.paddingXs,
          ),
          itemCount: navigationItems.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final item = navigationItems[index];

            // Improved active route detection baseado no sistema legado
            final isSelected = _isRouteActive(item.route, currentRoute);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: AppNavigationItem.sidebar(
                icon: item.icon,
                selectedIcon: null, // NavigationItem não tem selectedIcon
                label: item.label,
                isSelected: isSelected,
                onTap: () => _handleNavigation(context, _cleanRoute(item.route)),
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('MainNavigationDrawer: Error building navigation list - $e');
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
      // Sempre fechar drawer em não-desktop quando clicar em item de navegação
      if (!context.isDesktop) {
        Navigator.of(context).pop();
      }
      context.go(route);
    } catch (e) {
      debugPrint('MainNavigationDrawer: Navigation error - $e');
    }
  }

  Widget _buildFallbackDrawer() {
    return Drawer(
      backgroundColor: AppTheme.primaryColor,
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
