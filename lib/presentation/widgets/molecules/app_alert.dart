import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';

/// Sistema centralizado de alertas inline padrão do app
/// Implementa Atomic Design para alertas contextuais e informativos
class AppAlert extends StatelessWidget {
  final String message;
  final AlertType type;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback? onDismiss;
  final bool showDismissButton;
  final bool isInline;

  const AppAlert({
    super.key,
    required this.message,
    this.type = AlertType.info,
    this.icon,
    this.actionLabel,
    this.onActionPressed,
    this.onDismiss,
    this.showDismissButton = true,
    this.isInline = true,
  });

  /// Factory para alert de sucesso
  factory AppAlert.success({
    Key? key,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismiss,
    bool showDismissButton = true,
    bool isInline = true,
  }) => AppAlert(
    key: key,
    message: message,
    type: AlertType.success,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
    onDismiss: onDismiss,
    showDismissButton: showDismissButton,
    isInline: isInline,
  );

  /// Factory para alert de erro
  factory AppAlert.error({
    Key? key,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismiss,
    bool showDismissButton = true,
    bool isInline = true,
  }) => AppAlert(
    key: key,
    message: message,
    type: AlertType.error,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
    onDismiss: onDismiss,
    showDismissButton: showDismissButton,
    isInline: isInline,
  );

  /// Factory para alert de aviso
  factory AppAlert.warning({
    Key? key,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismiss,
    bool showDismissButton = true,
    bool isInline = true,
  }) => AppAlert(
    key: key,
    message: message,
    type: AlertType.warning,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
    onDismiss: onDismiss,
    showDismissButton: showDismissButton,
    isInline: isInline,
  );

  /// Factory para alert informativo
  factory AppAlert.info({
    Key? key,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismiss,
    bool showDismissButton = true,
    bool isInline = true,
  }) => AppAlert(
    key: key,
    message: message,
    type: AlertType.info,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
    onDismiss: onDismiss,
    showDismissButton: showDismissButton,
    isInline: isInline,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isInline ? EdgeInsets.all(LayoutConstants.paddingMd) : EdgeInsets.zero,
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(
          color: _getBackgroundColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícone
          Icon(
            icon ?? _getDefaultIcon(),
            color: _getIconColor(),
            size: LayoutConstants.iconMedium,
          ),
          
          SizedBox(width: LayoutConstants.paddingMd),
          
          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                
                // Botão de ação se existir
                if (actionLabel != null && onActionPressed != null) ...[
                  SizedBox(height: LayoutConstants.paddingSm),
                  GestureDetector(
                    onTap: onActionPressed,
                    child: Text(
                      actionLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getActionColor(),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Botão de fechar
          if (showDismissButton && onDismiss != null) ...[
            SizedBox(width: LayoutConstants.paddingSm),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                size: LayoutConstants.iconSmall,
                color: AppTheme.onSurface.withValues(alpha: 0.6),
              ),
              constraints: const BoxConstraints(
                minHeight: 24,
                minWidth: 24,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case AlertType.success:
        return Colors.green;
      case AlertType.error:
        return AppTheme.errorColor;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return AppTheme.primaryColor;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case AlertType.success:
        return Colors.green;
      case AlertType.error:
        return AppTheme.errorColor;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return AppTheme.primaryColor;
    }
  }

  Color _getActionColor() {
    switch (type) {
      case AlertType.success:
        return Colors.green.shade700;
      case AlertType.error:
        return AppTheme.errorColor;
      case AlertType.warning:
        return Colors.orange.shade700;
      case AlertType.info:
        return AppTheme.primaryColor;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.info:
        return Icons.info_outline;
    }
  }
}

/// Tipos de alert disponíveis
enum AlertType {
  success,
  error,
  warning,
  info,
}

/// Banner de alert que aparece no topo da tela
class AppAlertBanner extends StatelessWidget {
  final String message;
  final AlertType type;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback? onDismiss;
  final Duration? duration;

  const AppAlertBanner({
    super.key,
    required this.message,
    this.type = AlertType.info,
    this.icon,
    this.actionLabel,
    this.onActionPressed,
    this.onDismiss,
    this.duration,
  });

  /// Mostra um banner de alert no topo da tela
  static void show({
    required BuildContext context,
    required String message,
    AlertType type = AlertType.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: _getBannerBackgroundColor(type),
        content: Row(
          children: [
            Icon(
              icon ?? _getBannerDefaultIcon(type),
              color: Colors.white,
              size: LayoutConstants.iconMedium,
            ),
            SizedBox(width: LayoutConstants.paddingMd),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (actionLabel != null && onActionPressed != null)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                onActionPressed();
              },
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );

    // Auto-hide após duração especificada
    if (duration != null) {
      Future.delayed(duration, () {
        try {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          }
        } catch (e) {
          // Ignora erro se o banner já foi removido ou contexto inválido
        }
      });
    }
  }

  static Color _getBannerBackgroundColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Colors.green;
      case AlertType.error:
        return AppTheme.errorColor;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return AppTheme.primaryColor;
    }
  }

  static IconData _getBannerDefaultIcon(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: _getBannerBackgroundColor(type),
      content: Row(
        children: [
          Icon(
            icon ?? _getBannerDefaultIcon(type),
            color: Colors.white,
            size: LayoutConstants.iconMedium,
          ),
          SizedBox(width: LayoutConstants.paddingMd),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (actionLabel != null && onActionPressed != null)
          TextButton(
            onPressed: onActionPressed,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
      ],
    );
  }
}