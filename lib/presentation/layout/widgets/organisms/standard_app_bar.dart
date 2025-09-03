import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';

/// Organism: AppBar padrão da aplicação
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showDrawerButton;

  const StandardAppBar({
    super.key,
    required this.title,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showDrawerButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? AppTheme.onPrimary,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation ?? LayoutConstants.elevationMedium,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: _buildLeading(context),
      actions: actions,
      toolbarHeight: LayoutConstants.appBarHeight,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    // Se foi fornecido um leading customizado, usar ele
    if (leading != null) {
      return leading;
    }

    // Se não deve mostrar leading automaticamente, retornar null
    if (!automaticallyImplyLeading) {
      return null;
    }

    // Se deve mostrar botão do drawer e tem drawer disponível
    if (showDrawerButton && Scaffold.of(context).hasDrawer) {
      return _buildDrawerButton(context);
    }

    // Se pode fazer pop (tem rota anterior), mostrar botão de voltar
    if (Navigator.of(context).canPop()) {
      return _buildBackButton(context);
    }

    return null;
  }

  Widget _buildDrawerButton(BuildContext context) {
    return IconButton(
      onPressed: () => Scaffold.of(context).openDrawer(),
      icon: const Icon(Icons.menu),
      tooltip: 'Abrir menu',
      iconSize: context.responsive<double>(
        xs: LayoutConstants.iconMedium,
        md: LayoutConstants.iconLarge,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Voltar',
      iconSize: context.responsive<double>(
        xs: LayoutConstants.iconMedium,
        md: LayoutConstants.iconLarge,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(LayoutConstants.appBarHeight);
}
