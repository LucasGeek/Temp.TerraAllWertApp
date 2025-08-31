/// Estado base para formulários de login
class LoginFormState {
  final String email;
  final String password;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool isValid;
  final String? emailError;
  final String? passwordError;
  final String? submitError;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.obscurePassword = false,
    this.isSubmitting = false,
    this.isValid = false,
    this.emailError,
    this.passwordError,
    this.submitError,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? isSubmitting,
    bool? isValid,
    Object? emailError = _sentinel,
    Object? passwordError = _sentinel,
    Object? submitError = _sentinel,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValid: isValid ?? this.isValid,
      emailError: emailError == _sentinel ? this.emailError : emailError as String?,
      passwordError: passwordError == _sentinel ? this.passwordError : passwordError as String?,
      submitError: submitError == _sentinel ? this.submitError : submitError as String?,
    );
  }

  static const _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginFormState &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password &&
          obscurePassword == other.obscurePassword &&
          isSubmitting == other.isSubmitting &&
          isValid == other.isValid &&
          emailError == other.emailError &&
          passwordError == other.passwordError &&
          submitError == other.submitError;

  @override
  int get hashCode =>
      email.hashCode ^
      password.hashCode ^
      obscurePassword.hashCode ^
      isSubmitting.hashCode ^
      isValid.hashCode ^
      emailError.hashCode ^
      passwordError.hashCode ^
      submitError.hashCode;
}