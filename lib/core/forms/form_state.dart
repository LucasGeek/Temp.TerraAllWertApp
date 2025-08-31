import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_state.freezed.dart';

/// Estado base para qualquer formulário
@freezed
abstract class FormState with _$FormState {
  const factory FormState({
    @Default(false) bool isSubmitting,
    @Default(false) bool isValid,
    @Default({}) Map<String, String?> errors,
    @Default({}) Map<String, dynamic> values,
    String? submitError,
  }) = _FormState;
}

/// Estado específico para formulário de login
@freezed
abstract class LoginFormState with _$LoginFormState {
  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool obscurePassword,
    @Default(false) bool isSubmitting,
    @Default(false) bool isValid,
    String? emailError,
    String? passwordError,
    String? submitError,
  }) = _LoginFormState;
}