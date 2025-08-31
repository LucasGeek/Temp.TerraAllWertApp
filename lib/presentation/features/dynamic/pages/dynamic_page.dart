import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/enums/menu_presentation_type.dart';
import '../../../design_system/app_theme.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../widgets/organisms/presentations/image_carousel_presentation.dart';
import '../../../widgets/organisms/presentations/pin_map_presentation.dart';
import '../../../widgets/organisms/presentations/floor_plan_presentation.dart';

/// Página dinâmica para rotas criadas pelo usuário
/// Apresenta diferentes tipos de conteúdo baseado no tipo de menu
class DynamicPage extends ConsumerWidget {
  final String route;
  final String? title;

  const DynamicPage({
    super.key,
    required this.route,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Buscar informações do item de navegação pela rota
    final navigationNotifier = ref.read(navigationItemsProvider.notifier);
    final navigationItem = navigationNotifier.findItemByRoute(route);

    // Se não encontrou o item ou não tem tipo definido, mostra a página padrão
    if (navigationItem == null) {
      return _buildDefaultPage(context);
    }

    final menuType = navigationItem.menuType;
    final itemTitle = title ?? navigationItem.label;
    final description = navigationItem.description;

    // Determinar qual apresentação usar baseado no tipo de menu
    switch (menuType) {
      case MenuPresentationType.standard:
        return ImageCarouselPresentation(
          title: itemTitle,
          route: route,
          description: description,
        );
      
      case MenuPresentationType.pinMap:
        return PinMapPresentation(
          title: itemTitle,
          route: route,
          description: description,
        );
      
      case MenuPresentationType.floorPlan:
        return FloorPlanPresentation(
          title: itemTitle,
          route: route,
          description: description,
          floorNumber: _extractFloorNumber(itemTitle),
        );
    }
  }

  /// Página padrão para quando não consegue determinar o tipo
  Widget _buildDefaultPage(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.backgroundColor,
            ],
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
                    title ?? 'Página em Construção',
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
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Configure o tipo de menu para ativar a apresentação',
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.slideshow,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Sistema de apresentações dinâmicas ativo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Extrai número do pavimento do título se possível
  String? _extractFloorNumber(String title) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(title);
    return match?.group(1);
  }
}