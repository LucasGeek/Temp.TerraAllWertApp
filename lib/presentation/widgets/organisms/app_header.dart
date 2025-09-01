import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../notification/snackbar_notification.dart';
import '../../responsive/breakpoints.dart';
import '../atoms/menu_toggle_button.dart';

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
    final defaultActions = <Widget>[_buildNotificationButton(), _buildSpacing(context)];

    if (actions != null) {
      return [...actions!, ...defaultActions];
    }

    return defaultActions;
  }

  Widget _buildNotificationButton() {
    return IconButton(
      onPressed: _handleNotificationTap,
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Notificações',
      color: AppTheme.onSurface,
      splashRadius: LayoutConstants.iconSplashRadius,
    );
  }

  Widget _buildSpacing(BuildContext context) {
    return SizedBox(
      width: context.responsive<double>(
        xs: LayoutConstants.paddingXs,
        sm: LayoutConstants.paddingSm,
        md: LayoutConstants.paddingMd,
      ),
    );
  }

  void _handleNotificationTap() {
    try {
      SnackbarNotification.showInfo('Notificações em desenvolvimento');
    } catch (e) {
      debugPrint('AppHeader: Error showing notification - $e');
    }
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
