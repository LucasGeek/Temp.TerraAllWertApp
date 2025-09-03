import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/widgets/atoms/app_text_field.dart';

/// Molecule: Campos de formulário aprimorados seguindo SOLID principles
/// Single Responsibility: Apenas renderizar campos de formulário específicos
/// Open/Closed: Extensível via factory methods e configurações
/// Interface Segregation: Campos específicos para diferentes tipos de entrada
class AppFormField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final FormFieldType type;
  final List<TextInputFormatter>? customFormatters;
  final IconData? customPrefixIcon;
  final Widget? customSuffixIcon;
  final bool showPasswordToggle;
  
  const AppFormField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    required this.type,
    this.customFormatters,
    this.customPrefixIcon,
    this.customSuffixIcon,
    this.showPasswordToggle = true,
  });

  /// Factory para campo de email
  factory AppFormField.email({
    Key? key,
    String? label,
    String? hint,
    String? initialValue,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
  }) => AppFormField(
    key: key,
    label: label ?? 'Email',
    hint: hint ?? 'example@email.com',
    initialValue: initialValue,
    errorText: errorText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
    autofocus: autofocus,
    type: FormFieldType.email,
  );

  /// Factory para campo de senha
  factory AppFormField.password({
    Key? key,
    String? label,
    String? hint,
    String? initialValue,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
    bool showPasswordToggle = true,
  }) => AppFormField(
    key: key,
    label: label ?? 'Senha',
    hint: hint ?? 'Digite sua senha',
    initialValue: initialValue,
    errorText: errorText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
    autofocus: autofocus,
    type: FormFieldType.password,
    showPasswordToggle: showPasswordToggle,
  );

  /// Factory para campo de texto genérico
  factory AppFormField.text({
    Key? key,
    required String label,
    String? hint,
    String? initialValue,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
    List<TextInputFormatter>? formatters,
  }) => AppFormField(
    key: key,
    label: label,
    hint: hint,
    initialValue: initialValue,
    errorText: errorText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
    autofocus: autofocus,
    type: FormFieldType.text,
    customPrefixIcon: prefixIcon,
    customSuffixIcon: suffixIcon,
    customFormatters: formatters,
  );

  /// Factory para campo de telefone
  factory AppFormField.phone({
    Key? key,
    String? label,
    String? hint,
    String? initialValue,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
  }) => AppFormField(
    key: key,
    label: label ?? 'Telefone',
    hint: hint ?? '(00) 00000-0000',
    initialValue: initialValue,
    errorText: errorText,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
    autofocus: autofocus,
    type: FormFieldType.phone,
  );

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      prefixIcon: _getPrefixIcon(),
      suffixIcon: _getSuffixIcon(),
      obscureText: _getObscureText(),
      keyboardType: _getKeyboardType(),
      textInputAction: _getTextInputAction(),
      inputFormatters: _getInputFormatters(),
      initialValue: widget.initialValue,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
    );
  }
  
  IconData? _getPrefixIcon() {
    if (widget.customPrefixIcon != null) return widget.customPrefixIcon;
    
    switch (widget.type) {
      case FormFieldType.email:
        return Icons.email_outlined;
      case FormFieldType.password:
        return Icons.lock_outline;
      case FormFieldType.phone:
        return Icons.phone_outlined;
      case FormFieldType.text:
        return null;
    }
  }
  
  Widget? _getSuffixIcon() {
    if (widget.customSuffixIcon != null) return widget.customSuffixIcon;
    
    if (widget.type == FormFieldType.password && widget.showPasswordToggle) {
      return IconButton(
        icon: Icon(
          _obscurePassword 
              ? Icons.visibility_outlined 
              : Icons.visibility_off_outlined,
          color: AppTheme.textHint,
          size: 20,
        ),
        onPressed: _togglePasswordVisibility,
        splashRadius: LayoutConstants.iconSplashRadius,
        tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
      );
    }
    
    return null;
  }
  
  bool _getObscureText() {
    return widget.type == FormFieldType.password && _obscurePassword;
  }
  
  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case FormFieldType.email:
        return TextInputType.emailAddress;
      case FormFieldType.password:
        return TextInputType.visiblePassword;
      case FormFieldType.phone:
        return TextInputType.phone;
      case FormFieldType.text:
        return TextInputType.text;
    }
  }
  
  TextInputAction _getTextInputAction() {
    switch (widget.type) {
      case FormFieldType.email:
      case FormFieldType.phone:
      case FormFieldType.text:
        return TextInputAction.next;
      case FormFieldType.password:
        return TextInputAction.done;
    }
  }
  
  List<TextInputFormatter>? _getInputFormatters() {
    if (widget.customFormatters != null) return widget.customFormatters;
    
    switch (widget.type) {
      case FormFieldType.email:
        return [
          FilteringTextInputFormatter.deny(RegExp(r'\s')), // Remove espaços
        ];
      case FormFieldType.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ];
      case FormFieldType.password:
      case FormFieldType.text:
        return null;
    }
  }
}

/// Enum para tipos de campo - Open/Closed Principle
enum FormFieldType {
  email,
  password,
  phone,
  text,
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppFormField.email() ao invés de EmailField')
typedef EmailField = AppFormField;

@Deprecated('Use AppFormField.password() ao invés de PasswordField')
typedef PasswordField = AppFormField;