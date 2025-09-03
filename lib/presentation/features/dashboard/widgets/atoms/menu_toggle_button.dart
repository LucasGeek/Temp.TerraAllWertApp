import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../providers/sidebar_provider.dart';

/// Atom: Botão de menu responsivo seguindo SOLID principles
/// Single Responsibility: Apenas renderizar botão de menu
/// Open/Closed: Extensível via callbacks e configurações
class AppMenuButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;
  final MenuButtonType type;
  final double? splashRadius;

  const AppMenuButton({
    super.key,
    this.onPressed,
    this.color,
    this.tooltip,
    this.type = MenuButtonType.auto,
    this.splashRadius,
  });

  /// Factory para botão de drawer (mobile)
  factory AppMenuButton.drawer({
    Key? key,
    VoidCallback? onPressed,
    Color? color,
    String? tooltip,
  }) => AppMenuButton(
    key: key,
    onPressed: onPressed,
    color: color,
    tooltip: tooltip ?? 'Abrir menu',
    type: MenuButtonType.drawer,
  );

  /// Factory para botão de sidebar (desktop)
  factory AppMenuButton.sidebar({
    Key? key,
    VoidCallback? onPressed,
    Color? color,
    String? tooltip,
  }) => AppMenuButton(
    key: key,
    onPressed: onPressed,
    color: color,
    tooltip: tooltip,
    type: MenuButtonType.sidebar,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveType = _getEffectiveType(context);
    final onPressedCallback = onPressed ?? _getDefaultCallback(context, ref, effectiveType);

    return IconButton(
      onPressed: onPressedCallback,
      icon: _buildIcon(ref, effectiveType),
      color: color ?? AppTheme.onSurface,
      tooltip: _getTooltip(ref, effectiveType),
      splashRadius: splashRadius ?? LayoutConstants.iconSplashRadius,
    );
  }

  MenuButtonType _getEffectiveType(BuildContext context) {
    if (type != MenuButtonType.auto) return type;

    final isMobile = context.isMobile || (context.isTablet && context.isXs);
    return isMobile ? MenuButtonType.drawer : MenuButtonType.sidebar;
  }

  Widget _buildIcon(WidgetRef ref, MenuButtonType effectiveType) {
    switch (effectiveType) {
      case MenuButtonType.drawer:
        return const Icon(Icons.menu);
      case MenuButtonType.sidebar:
        final isExpanded = ref.watch(sidebarNotifierProvider);
        return Icon(isExpanded ? Icons.menu_open : Icons.menu);
      case MenuButtonType.auto:
        return const Icon(Icons.menu);
    }
  }

  String _getTooltip(WidgetRef ref, MenuButtonType effectiveType) {
    if (tooltip != null) return tooltip!;

    switch (effectiveType) {
      case MenuButtonType.drawer:
        return 'Abrir menu';
      case MenuButtonType.sidebar:
        final isExpanded = ref.watch(sidebarNotifierProvider);
        return isExpanded ? 'Recolher menu' : 'Expandir menu';
      case MenuButtonType.auto:
        return 'Menu';
    }
  }

  VoidCallback? _getDefaultCallback(
    BuildContext context,
    WidgetRef ref,
    MenuButtonType effectiveType,
  ) {
    switch (effectiveType) {
      case MenuButtonType.drawer:
        return () {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold?.hasDrawer == true) {
            scaffold!.openDrawer();
          }
        };
      case MenuButtonType.sidebar:
        return () => ref.read(sidebarNotifierProvider.notifier).toggle();
      case MenuButtonType.auto:
        return null;
    }
  }
}

/// Enum para tipos de botão de menu - Open/Closed Principle
enum MenuButtonType { auto, drawer, sidebar }

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppMenuButton ao invés de MenuToggleButton')
typedef MenuToggleButton = AppMenuButton;
