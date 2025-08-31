import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';
import '../atoms/app_logo.dart';
import '../atoms/responsive_text.dart';
import '../atoms/menu_toggle_button.dart';

/// Molecule: Cabeçalho da aplicação seguindo SOLID principles
/// Single Responsibility: Apenas renderizar cabeçalho
/// Open/Closed: Extensível via factory methods e ações customizáveis
/// Interface Segregation: Diferentes layouts para diferentes contextos
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final HeaderVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final bool centerTitle;
  final Widget? customLogo;
  
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.variant = HeaderVariant.standard,
    this.actions,
    this.leading,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.centerTitle = false,
    this.customLogo,
  });

  /// Factory para cabeçalho de drawer
  factory AppHeader.drawer({
    Key? key,
    required String title,
    String? subtitle,
    bool showLogo = true,
    Widget? customLogo,
  }) => AppHeader(
    key: key,
    title: title,
    subtitle: subtitle,
    showLogo: showLogo,
    variant: HeaderVariant.drawer,
    customLogo: customLogo,
  );

  /// Factory para cabeçalho de AppBar
  factory AppHeader.appBar({
    Key? key,
    required String title,
    String? subtitle,
    bool showLogo = false,
    List<Widget>? actions,
    Widget? leading,
    bool showMenuButton = false,
    VoidCallback? onMenuPressed,
    bool centerTitle = true,
  }) => AppHeader(
    key: key,
    title: title,
    subtitle: subtitle,
    showLogo: showLogo,
    variant: HeaderVariant.appBar,
    actions: actions,
    leading: leading,
    showMenuButton: showMenuButton,
    onMenuPressed: onMenuPressed,
    centerTitle: centerTitle,
  );

  /// Factory para cabeçalho compacto
  factory AppHeader.compact({
    Key? key,
    required String title,
    bool showLogo = true,
    List<Widget>? actions,
  }) => AppHeader(
    key: key,
    title: title,
    showLogo: showLogo,
    variant: HeaderVariant.compact,
    actions: actions,
  );

  /// Factory para cabeçalho de página
  factory AppHeader.page({
    Key? key,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    Color? backgroundColor,
  }) => AppHeader(
    key: key,
    title: title,
    subtitle: subtitle,
    showLogo: false,
    variant: HeaderVariant.page,
    actions: actions,
    backgroundColor: backgroundColor,
  );

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case HeaderVariant.standard:
      case HeaderVariant.drawer:
        return _buildDrawerHeader(context);
      case HeaderVariant.appBar:
        return _buildAppBarHeader(context);
      case HeaderVariant.compact:
        return _buildCompactHeader(context);
      case HeaderVariant.page:
        return _buildPageHeader(context);
    }
  }
  
  Widget _buildDrawerHeader(BuildContext context) {
    final headerHeight = height ?? LayoutConstants.drawerHeaderHeight;
    
    return Container(
      height: headerHeight,
      padding: EdgeInsets.all(_getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (showLogo) ...[
                customLogo ?? AppLogo.small(),
                SizedBox(width: LayoutConstants.marginSm),
              ],
              Expanded(
                child: AppText.title(
                  title,
                  color: textColor ?? AppTheme.onPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            AppText.caption(
              subtitle!,
              color: (textColor ?? AppTheme.onPrimary).withValues(alpha: 0.8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAppBarHeader(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.title(
            title,
            color: textColor ?? AppTheme.onSurface,
          ),
          if (subtitle != null) ...[
            AppText.caption(
              subtitle!,
              color: (textColor ?? AppTheme.onSurface).withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
      backgroundColor: backgroundColor ?? AppTheme.surfaceColor,
      foregroundColor: textColor ?? AppTheme.onSurface,
      centerTitle: centerTitle,
      leading: _buildLeading(),
      actions: actions,
      elevation: 2,
    );
  }
  
  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      height: height ?? 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(
          color: AppTheme.outline,
          width: 1,
        )),
      ),
      child: Row(
        children: [
          if (showLogo) ...[
            customLogo ?? AppLogo.small(),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: AppText.body(
              title,
              color: textColor ?? AppTheme.onSurface,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
  
  Widget _buildPageHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.heading(
                      title,
                      color: textColor ?? AppTheme.onSurface,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      AppText.body(
                        subtitle!,
                        color: (textColor ?? AppTheme.onSurface).withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  children: actions!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget? _buildLeading() {
    if (leading != null) return leading;
    
    if (showMenuButton) {
      return AppMenuButton(
        onPressed: onMenuPressed,
      );
    }
    
    return null;
  }
  
  double _getResponsivePadding(BuildContext context) {
    return context.responsive<double>(
      xs: LayoutConstants.paddingMd,
      md: LayoutConstants.paddingMd,
      lg: LayoutConstants.paddingLg,
    );
  }
}

/// Enum para variantes do cabeçalho - Open/Closed Principle
enum HeaderVariant {
  standard,
  drawer,
  appBar,
  compact,
  page,
}