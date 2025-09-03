import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';
import '../atoms/primary_button.dart';

/// Sistema centralizado de bottom sheets padrão do app
/// Implementa Atomic Design com validação e design responsivo
class AppBottomSheet {
  /// Obtém altura máxima responsiva para bottom sheets
  static double _getMaxHeight(BuildContext context) {
    return context.responsive<double>(
      xs: MediaQuery.of(context).size.height * 0.9, // 90% no mobile
      sm: MediaQuery.of(context).size.height * 0.8, // 80% em tablets
      md: MediaQuery.of(context).size.height * 0.7, // 70% em desktop
      lg: MediaQuery.of(context).size.height * 0.6,
      xl: MediaQuery.of(context).size.height * 0.5,
      xxl: MediaQuery.of(context).size.height * 0.4,
    );
  }

  /// Bottom sheet de opções/menu padrão
  static Future<T?> showOptions<T>({
    required BuildContext context,
    required String title,
    required List<BottomSheetOption<T>> options,
    String? message,
    IconData? titleIcon,
    bool showCancel = true,
    String cancelText = 'Cancelar',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      builder: (context) => _OptionsBottomSheet<T>(
        title: title,
        options: options,
        message: message,
        titleIcon: titleIcon,
        showCancel: showCancel,
        cancelText: cancelText,
      ),
    );
  }

  /// Bottom sheet de confirmação padrão
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData? icon,
    bool isDangerous = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      builder: (context) => _ConfirmationBottomSheet(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        isDangerous: isDangerous,
      ),
    );
  }

  /// Bottom sheet de formulário/input padrão
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
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      builder: (context) => _InputBottomSheet(
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

  /// Bottom sheet customizado com widget personalizado
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: _getMaxHeight(context),
        ),
        child: child,
      ),
    );
  }

  /// Adaptativo: usa Dialog em desktop e BottomSheet em mobile
  static Future<T?> showAdaptive<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(LayoutConstants.radiusMedium),
          ),
        ),
        builder: (context) => Container(
          constraints: BoxConstraints(
            maxHeight: _getMaxHeight(context),
          ),
          child: child,
        ),
      );
    } else {
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
              maxWidth: context.responsive<double>(
                xs: MediaQuery.of(context).size.width * 0.9,
                sm: 400,
                md: 500,
                lg: 600,
                xl: 650,
                xxl: 700,
              ),
            ),
            child: child,
          ),
        ),
      );
    }
  }
}

/// Modelo de dados para opções do bottom sheet
class BottomSheetOption<T> {
  final String label;
  final IconData? icon;
  final T value;
  final bool isDangerous;
  final bool isEnabled;

  const BottomSheetOption({
    required this.label,
    required this.value,
    this.icon,
    this.isDangerous = false,
    this.isEnabled = true,
  });
}

/// Bottom sheet de opções interno
class _OptionsBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<BottomSheetOption<T>> options;
  final String? message;
  final IconData? titleIcon;
  final bool showCancel;
  final String cancelText;

  const _OptionsBottomSheet({
    required this.title,
    required this.options,
    this.message,
    this.titleIcon,
    required this.showCancel,
    required this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: AppBottomSheet._getMaxHeight(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual do bottom sheet
          Container(
            margin: EdgeInsets.only(top: LayoutConstants.paddingSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(LayoutConstants.paddingLg),
            child: Column(
              children: [
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(
                        titleIcon,
                        color: AppTheme.primaryColor,
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
                if (message != null) ...[
                  SizedBox(height: LayoutConstants.paddingSm),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Opções
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options[index];
                return ListTile(
                  enabled: option.isEnabled,
                  leading: option.icon != null
                      ? Icon(
                          option.icon,
                          color: option.isDangerous && option.isEnabled
                              ? AppTheme.errorColor
                              : option.isEnabled
                                  ? AppTheme.onSurface
                                  : AppTheme.onSurface.withValues(alpha: 0.4),
                        )
                      : null,
                  title: Text(
                    option.label,
                    style: TextStyle(
                      color: option.isDangerous && option.isEnabled
                          ? AppTheme.errorColor
                          : option.isEnabled
                              ? AppTheme.onSurface
                              : AppTheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: option.isDangerous && option.isEnabled
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: option.isEnabled
                      ? () => Navigator.of(context).pop(option.value)
                      : null,
                );
              },
            ),
          ),

          // Botão cancelar
          if (showCancel) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(LayoutConstants.paddingMd),
              child: AppButton.secondary(
                text: cancelText,
                onPressed: () => Navigator.of(context).pop(),
                isFullWidth: true,
              ),
            ),
          ],
          
          // Padding do bottom para safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Bottom sheet de confirmação interno
class _ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final bool isDangerous;

  const _ConfirmationBottomSheet({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.icon,
    required this.isDangerous,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: AppBottomSheet._getMaxHeight(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Container(
            margin: EdgeInsets.only(top: LayoutConstants.paddingSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(LayoutConstants.paddingLg),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: isDangerous ? AppTheme.errorColor : AppTheme.primaryColor,
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
                
                SizedBox(height: LayoutConstants.paddingMd),
                
                // Mensagem
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                
                SizedBox(height: LayoutConstants.paddingXl),
                
                // Botões
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        text: cancelText,
                        onPressed: () => Navigator.of(context).pop(false),
                        isFullWidth: true,
                      ),
                    ),
                    SizedBox(width: LayoutConstants.paddingMd),
                    Expanded(
                      child: AppButton.primary(
                        text: confirmText,
                        onPressed: () => Navigator.of(context).pop(true),
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Padding do bottom para safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Bottom sheet de input interno
class _InputBottomSheet extends StatefulWidget {
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

  const _InputBottomSheet({
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
  State<_InputBottomSheet> createState() => _InputBottomSheetState();
}

class _InputBottomSheetState extends State<_InputBottomSheet> {
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: AppBottomSheet._getMaxHeight(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Container(
            margin: EdgeInsets.only(top: LayoutConstants.paddingSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(LayoutConstants.paddingLg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
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
                    
                    if (widget.message != null) ...[
                      SizedBox(height: LayoutConstants.paddingSm),
                      Text(
                        widget.message!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: LayoutConstants.paddingLg),
                    
                    // Campo de input
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
                    
                    SizedBox(height: LayoutConstants.paddingXl),
                    
                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            text: widget.cancelText,
                            onPressed: () => Navigator.of(context).pop(),
                            isFullWidth: true,
                          ),
                        ),
                        SizedBox(width: LayoutConstants.paddingMd),
                        Expanded(
                          child: AppButton.primary(
                            text: widget.confirmText,
                            onPressed: _handleSubmit,
                            isFullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Padding do bottom para safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}