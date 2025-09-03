import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/menu.dart';
import '../../../layout/design_system/app_theme.dart';
import '../../../providers/menu_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../widgets/templates/screen_types/pins/organisms/pin_map_presentation.dart';

/// Página dinâmica para rotas criadas pelo usuário
/// Apresenta diferentes tipos de conteúdo baseado no tipo de menu
class DynamicPage extends ConsumerWidget {
  final String route;
  final String? title;

  const DynamicPage({super.key, required this.route, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Buscar informações do item de navegação pela rota
    final navigationItems = ref.watch(navigationItemsProvider);
    // Comparar apenas o path, ignorando query parameters
    final navigationItem = navigationItems.where((item) {
      final itemUri = Uri.parse(item.route);
      final routeUri = Uri.parse(route);
      return itemUri.path == routeUri.path;
    }).firstOrNull;

    // Buscar o menu correspondente para saber o tipo de tela
    final menuState = ref.watch(menuProvider);
    Menu? menu;
    
    if (menuState.status == MenuStatus.loaded && navigationItem != null) {
      menu = menuState.menus.where((m) => m.localId == navigationItem.id).firstOrNull;
    }

    final itemTitle = title ?? navigationItem?.label ?? 'Página Dinâmica';

    // Se encontrou o menu, renderizar baseado no screenType
    if (menu != null) {
      return _buildScreenByType(context, menu, itemTitle);
    }

    return _buildDefaultPage(context, itemTitle);
  }

  /// Renderiza a tela apropriada baseada no tipo do menu
  Widget _buildScreenByType(BuildContext context, Menu menu, String pageTitle) {
    switch (menu.screenType) {
      case ScreenType.pin:
        return PinMapPresentation(
          title: pageTitle,
          route: route,
          backgroundImageUrl: menu.configuration?['backgroundImageUrl'] as String?,
          description: menu.description,
        );
      case ScreenType.carousel:
        // TODO: Implementar CarouselPresentation
        return _buildPlaceholderPage(context, pageTitle, 'Carousel', Icons.photo_library);
      case ScreenType.floorplan:
        // TODO: Implementar FloorplanPresentation
        return _buildPlaceholderPage(context, pageTitle, 'Planta Baixa', Icons.architecture);
    }
  }

  /// Página placeholder para tipos de tela não implementados ainda
  Widget _buildPlaceholderPage(BuildContext context, String pageTitle, String screenTypeName, IconData icon) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor.withValues(alpha: 0.05), AppTheme.backgroundColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '$screenTypeName em Desenvolvimento',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Este tipo de tela ($screenTypeName) será implementado em breve.',
                    style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Página padrão para quando não consegue determinar o tipo
  Widget _buildDefaultPage(BuildContext context, String pageTitle) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor.withValues(alpha: 0.05), AppTheme.backgroundColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction_outlined,
                    size: 64,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Página em Construção',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Esta página foi criada automaticamente para a rota:\n$route',
                    style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Conteúdo será implementado futuramente',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}