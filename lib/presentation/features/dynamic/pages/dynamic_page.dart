import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../layout/design_system/app_theme.dart';
import '../../../providers/navigation_provider.dart';

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
    final navigationItem = navigationItems.where((item) => item.route == route).firstOrNull;

    final itemTitle = title ?? navigationItem?.label ?? 'Página Dinâmica';

    return _buildDefaultPage(context, itemTitle);
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