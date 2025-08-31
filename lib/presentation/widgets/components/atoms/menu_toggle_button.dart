import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../features/navigation/providers/sidebar_provider.dart';
import '../../../responsive/breakpoints.dart';

/// Botão atômico para controlar menu/sidebar
/// Mobile: abre drawer do Scaffold
/// Desktop/Tablet: alterna estado da sidebar
class MenuToggleButton extends ConsumerWidget {
  const MenuToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Validação de contexto para prevenir erros
    try {
      final isMobile = context.isMobile || (context.isTablet && context.isXs);
      
      if (isMobile) {
        // Mobile: botão para abrir drawer
        return IconButton(
          onPressed: () {
            try {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold?.hasDrawer == true) {
                scaffold!.openDrawer();
              }
            } catch (e) {
              // Fallback silencioso se não houver drawer
              debugPrint('MenuToggleButton: No drawer available');
            }
          },
          icon: const Icon(Icons.menu),
          color: AppTheme.onSurface,
          tooltip: 'Abrir menu',
          splashRadius: LayoutConstants.iconSplashRadius,
        );
      } else {
        // Desktop/Tablet: botão para colapsar/expandir sidebar
        final isExpanded = ref.watch(sidebarNotifierProvider);
        return IconButton(
          onPressed: () {
            try {
              ref.read(sidebarNotifierProvider.notifier).toggle();
            } catch (e) {
              // Fallback silencioso
              debugPrint('MenuToggleButton: Error toggling sidebar');
            }
          },
          icon: Icon(isExpanded ? Icons.menu_open : Icons.menu),
          color: AppTheme.onSurface,
          tooltip: isExpanded ? 'Recolher menu' : 'Expandir menu',
          splashRadius: LayoutConstants.iconSplashRadius,
        );
      }
    } catch (e) {
      // Fallback completo - botão básico
      return IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu),
        color: AppTheme.onSurface,
        tooltip: 'Menu',
        splashRadius: LayoutConstants.iconSplashRadius,
      );
    }
  }
}