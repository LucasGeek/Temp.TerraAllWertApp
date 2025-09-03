import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/widgets/atoms/menu_toggle_button.dart';
import '../../../features/dashboard/widgets/organisms/search_modal.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';

/// Header da aplicação com AppBar configurável
/// Implementa atomic design com validação e prevenção de erros
class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showMenuButton;
  final bool showBackButton;
  final String? currentRoute;

  const AppHeader({
    super.key,
    this.actions,
    this.showMenuButton = true,
    this.showBackButton = false,
    this.currentRoute,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      return AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurface,
        elevation: LayoutConstants.elevationXs,
        leading: showMenuButton ? const AppMenuButton() : null,
        automaticallyImplyLeading: false,
        actions: _buildActions(context),
      );
    } catch (e) {
      debugPrint('AppHeader: Error building header - $e');
      return _buildFallbackAppBar();
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final defaultActions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => SearchModal.show(context),
        tooltip: 'Buscar Pavimentação',
        splashRadius: LayoutConstants.iconSplashRadius,
      ),
    ];

    if (actions != null) {
      return [...actions!, ...defaultActions];
    }

    return defaultActions;
  }

  AppBar _buildFallbackAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.onSurface,
      title: const Text('Terra Allwert'),
      automaticallyImplyLeading: false,
    );
  }
}
