import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';

/// Base dialog widget que se adapta entre Dialog (desktop/tablet) e BottomSheet (mobile)
/// Padroniza header, content e footer para todos os diálogos do app
class AppDialog extends ConsumerStatefulWidget {
  final String title;
  final IconData? titleIcon;
  final Widget? subtitle;
  final Widget content;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final double? width;
  final double? maxHeight;
  final bool showCloseButton;
  final bool isDismissible;
  final bool enableDrag;
  final Color? backgroundColor;
  
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.titleIcon,
    this.subtitle,
    this.actions,
    this.onClose,
    this.width,
    this.maxHeight,
    this.showCloseButton = true,
    this.isDismissible = true,
    this.enableDrag = true,
    this.backgroundColor,
  });

  /// Método estático para exibir o dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    IconData? titleIcon,
    Widget? subtitle,
    List<Widget>? actions,
    VoidCallback? onClose,
    double? width,
    double? maxHeight,
    bool showCloseButton = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      // Mobile: Usar BottomSheet
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        backgroundColor: Colors.transparent,
        builder: (context) => AppDialog(
          title: title,
          content: content,
          titleIcon: titleIcon,
          subtitle: subtitle,
          actions: actions,
          onClose: onClose,
          width: width,
          maxHeight: maxHeight,
          showCloseButton: showCloseButton,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          backgroundColor: backgroundColor,
        ),
      );
    } else {
      // Desktop/Tablet: Usar Dialog
      return showDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        builder: (context) => AppDialog(
          title: title,
          content: content,
          titleIcon: titleIcon,
          subtitle: subtitle,
          actions: actions,
          onClose: onClose,
          width: width,
          maxHeight: maxHeight,
          showCloseButton: showCloseButton,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  @override
  ConsumerState<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends ConsumerState<AppDialog> {
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      return _buildBottomSheet(context);
    } else {
      return _buildDialog(context);
    }
  }
  
  /// Build para BottomSheet (Mobile)
  Widget _buildBottomSheet(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = widget.maxHeight ?? screenHeight * 0.9;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minHeight: 0,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppTheme.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(LayoutConstants.radiusLarge),
          topRight: Radius.circular(LayoutConstants.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          if (widget.enableDrag)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          // Header
          _buildHeader(context),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: LayoutConstants.paddingMd,
              ),
              child: widget.content,
            ),
          ),
          // Actions
          if (widget.actions != null && widget.actions!.isNotEmpty)
            _buildActions(context),
          // Safe area for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
  
  /// Build para Dialog (Desktop/Tablet)
  Widget _buildDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Larguras responsivas
    final dialogWidth = widget.width ?? context.responsive<double>(
      xs: screenSize.width * 0.95,
      sm: screenSize.width * 0.85,
      md: 500,
      lg: 600,
      xl: 700,
      xxl: 800,
    );
    
    final maxHeight = widget.maxHeight ?? screenSize.height * 0.85;
    
    return Dialog(
      backgroundColor: widget.backgroundColor ?? AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: dialogWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LayoutConstants.paddingLg,
                ),
                child: widget.content,
              ),
            ),
            // Actions
            if (widget.actions != null && widget.actions!.isNotEmpty)
              _buildActions(context),
          ],
        ),
      ),
    );
  }
  
  /// Header padrão do dialog
  Widget _buildHeader(BuildContext context) {
    final isMobile = context.isMobile;
    
    return Container(
      padding: EdgeInsets.all(
        isMobile ? LayoutConstants.paddingMd : LayoutConstants.paddingLg,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            isMobile ? LayoutConstants.radiusLarge : LayoutConstants.radiusMedium,
          ),
          topRight: Radius.circular(
            isMobile ? LayoutConstants.radiusLarge : LayoutConstants.radiusMedium,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.titleIcon != null) ...[
                Icon(
                  widget.titleIcon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: LayoutConstants.marginSm),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (widget.showCloseButton)
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () {
                    widget.onClose?.call();
                    Navigator.of(context).pop();
                  },
                  splashRadius: LayoutConstants.iconSplashRadius,
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: LayoutConstants.marginXs),
            widget.subtitle!,
          ],
        ],
      ),
    );
  }
  
  /// Footer com actions padrão
  Widget _buildActions(BuildContext context) {
    final isMobile = context.isMobile;
    
    return Container(
      padding: EdgeInsets.all(
        isMobile ? LayoutConstants.paddingMd : LayoutConstants.paddingLg,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.actions != null)
            ...widget.actions!.map((action) => Padding(
              padding: const EdgeInsets.only(left: LayoutConstants.marginSm),
              child: action,
            )),
        ],
      ),
    );
  }
}

/// Extension para facilitar uso do AppDialog
extension AppDialogExtension on BuildContext {
  /// Exibe um dialog padrão do app
  Future<T?> showAppDialog<T>({
    required String title,
    required Widget content,
    IconData? titleIcon,
    Widget? subtitle,
    List<Widget>? actions,
    VoidCallback? onClose,
    double? width,
    double? maxHeight,
    bool showCloseButton = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    return AppDialog.show<T>(
      context: this,
      title: title,
      content: content,
      titleIcon: titleIcon,
      subtitle: subtitle,
      actions: actions,
      onClose: onClose,
      width: width,
      maxHeight: maxHeight,
      showCloseButton: showCloseButton,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
    );
  }
  
  /// Exibe um dialog de confirmação
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData? icon,
    bool isDangerous = false,
  }) {
    return showAppDialog<bool>(
      title: title,
      titleIcon: icon ?? Icons.help_outline,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: LayoutConstants.paddingMd),
        child: Text(
          message,
          style: Theme.of(this).textTheme.bodyLarge,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(this).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(this).pop(true),
          style: isDangerous
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
  
  /// Exibe um dialog de erro
  Future<void> showErrorDialog({
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showAppDialog<void>(
      title: title,
      titleIcon: Icons.error_outline,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: LayoutConstants.paddingMd),
        child: Text(
          message,
          style: Theme.of(this).textTheme.bodyLarge?.copyWith(
            color: AppTheme.errorColor,
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(this).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }
  
  /// Exibe um dialog de sucesso
  Future<void> showSuccessDialog({
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showAppDialog<void>(
      title: title,
      titleIcon: Icons.check_circle_outline,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: LayoutConstants.paddingMd),
        child: Text(
          message,
          style: Theme.of(this).textTheme.bodyLarge?.copyWith(
            color: AppTheme.successColor,
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(this).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}