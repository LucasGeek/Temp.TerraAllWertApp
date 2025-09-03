import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';
import '../atoms/primary_button.dart';

/// Sistema centralizado de dialogs padrão do app
/// Implementa Atomic Design com validação e design responsivo
class AppDialog {
  /// Obtém largura responsiva para dialogs
  static double _getResponsiveWidth(BuildContext context) {
    return context.responsive<double>(
      xs: MediaQuery.of(context).size.width * 0.9, // 90% no mobile
      sm: 400,
      md: 500,
      lg: 600,
      xl: 650,
      xxl: 700,
    );
  }

  /// Dialog de confirmação padrão
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData? icon,
    Color? iconColor,
    Color? confirmButtonColor,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        confirmButtonColor: confirmButtonColor,
        isDangerous: isDangerous,
      ),
    );
  }

  /// Dialog de input/formulário padrão
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmText = 'Salvar',
    String cancelText = 'Cancelar',
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _InputDialog(
        title: title,
        message: message,
        initialValue: initialValue,
        hintText: hintText,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        keyboardType: keyboardType,
        validator: validator,
        isRequired: isRequired,
      ),
    );
  }

  /// Dialog informativo padrão
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _InfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  /// Dialog de erro padrão
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    String? details,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        details: details,
      ),
    );
  }

  /// Dialog de sucesso padrão
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }

  /// Dialog personalizado com widget customizado
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: _getResponsiveWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Dialog de confirmação interna
class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? iconColor;
  final Color? confirmButtonColor;
  final bool isDangerous;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.icon,
    this.iconColor,
    this.confirmButtonColor,
    required this.isDangerous,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? (isDangerous ? AppTheme.errorColor : AppTheme.primaryColor),
              size: LayoutConstants.iconLarge,
            ),
            SizedBox(width: LayoutConstants.paddingMd),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDialog._getResponsiveWidth(context),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: TextStyle(
              color: AppTheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(width: LayoutConstants.paddingSm),
        AppButton.primary(
          text: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
        ),
      ],
    );
  }
}

/// Dialog de input interno
class _InputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? initialValue;
  final String? hintText;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isRequired;

  const _InputDialog({
    required this.title,
    this.message,
    this.initialValue,
    this.hintText,
    required this.confirmText,
    required this.cancelText,
    this.icon,
    required this.keyboardType,
    this.validator,
    required this.isRequired,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  String? _validateInput(String? value) {
    if (widget.isRequired && (value == null || value.trim().isEmpty)) {
      return 'Este campo é obrigatório';
    }
    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: AppTheme.primaryColor,
              size: LayoutConstants.iconLarge,
            ),
            SizedBox(width: LayoutConstants.paddingMd),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDialog._getResponsiveWidth(context),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message != null) ...[
                Text(
                  widget.message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: LayoutConstants.paddingMd),
              ],
              TextFormField(
                controller: _controller,
                keyboardType: widget.keyboardType,
                validator: _validateInput,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: LayoutConstants.paddingMd,
                    vertical: LayoutConstants.paddingMd,
                  ),
                ),
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.cancelText,
            style: TextStyle(
              color: AppTheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(width: LayoutConstants.paddingSm),
        AppButton.primary(
          text: widget.confirmText,
          onPressed: _handleSubmit,
          isFullWidth: false,
        ),
      ],
    );
  }
}

/// Dialog informativo interno
class _InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData? icon;
  final Color? iconColor;

  const _InfoDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? AppTheme.primaryColor,
              size: LayoutConstants.iconLarge,
            ),
            SizedBox(width: LayoutConstants.paddingMd),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDialog._getResponsiveWidth(context),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
      actions: [
        AppButton.primary(
          text: buttonText,
          onPressed: () => Navigator.of(context).pop(),
          isFullWidth: false,
        ),
      ],
    );
  }
}

/// Dialog de erro interno
class _ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final String? details;

  const _ErrorDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: LayoutConstants.iconLarge,
          ),
          SizedBox(width: LayoutConstants.paddingMd),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDialog._getResponsiveWidth(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (details != null) ...[
              SizedBox(height: LayoutConstants.paddingMd),
              Container(
                padding: EdgeInsets.all(LayoutConstants.paddingMd),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  details!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurface.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton.primary(
          text: buttonText,
          onPressed: () => Navigator.of(context).pop(),
          isFullWidth: false,
        ),
      ],
    );
  }
}

/// Dialog de sucesso interno
class _SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;

  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      title: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: LayoutConstants.iconLarge,
          ),
          SizedBox(width: LayoutConstants.paddingMd),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDialog._getResponsiveWidth(context),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
      actions: [
        AppButton.primary(
          text: buttonText,
          onPressed: () => Navigator.of(context).pop(),
          isFullWidth: false,
        ),
      ],
    );
  }
}