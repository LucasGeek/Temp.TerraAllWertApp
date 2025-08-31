import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de campo de texto com validação integrada
class ValidatedTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool autofocus;
  final String? Function(String?)? validator;

  const ValidatedTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.controller,
    this.autofocus = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            border: const OutlineInputBorder(),
            enabled: enabled,
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          autofocus: autofocus,
          validator: validator,
        ),
      ],
    );
  }
}

/// Widget especializado para campo de email
class EmailTextField extends StatelessWidget {
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool autofocus;

  const EmailTextField({
    super.key,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: 'Email',
      hint: 'Digite seu email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      initialValue: initialValue,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      focusNode: focusNode,
      controller: controller,
      autofocus: autofocus,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // Remove espaços
      ],
    );
  }
}

/// Widget especializado para campo de senha
class PasswordTextField extends StatelessWidget {
  final String? initialValue;
  final String? errorText;
  final String label;
  final String? hint;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool autofocus;
  final bool showVisibilityToggle;

  const PasswordTextField({
    super.key,
    this.initialValue,
    this.errorText,
    this.label = 'Senha',
    this.hint = 'Digite sua senha',
    this.obscureText = true,
    this.onToggleVisibility,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.controller,
    this.autofocus = false,
    this.showVisibilityToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: label,
      hint: hint,
      prefixIcon: Icons.lock_outline,
      suffixIcon: showVisibilityToggle
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleVisibility,
            )
          : null,
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      initialValue: initialValue,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      focusNode: focusNode,
      controller: controller,
      autofocus: autofocus,
    );
  }
}

/// Widget para campo de telefone com formatação
class PhoneTextField extends StatelessWidget {
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  const PhoneTextField({
    super.key,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValidatedTextField(
      label: 'Telefone',
      hint: '(XX) XXXXX-XXXX',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      initialValue: initialValue,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      focusNode: focusNode,
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _PhoneInputFormatter(),
      ],
      maxLength: 15,
    );
  }
}

/// Formatador personalizado para telefone
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.length <= 2) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 6) {
      return newValue.copyWith(
        text: '(${text.substring(0, 2)}) ${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 3),
      );
    } else if (text.length <= 10) {
      return newValue.copyWith(
        text: '(${text.substring(0, 2)}) ${text.substring(2, 6)}-${text.substring(6)}',
        selection: TextSelection.collapsed(offset: text.length + 4),
      );
    } else {
      return newValue.copyWith(
        text: '(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7, 11)}',
        selection: TextSelection.collapsed(offset: 15),
      );
    }
  }
}