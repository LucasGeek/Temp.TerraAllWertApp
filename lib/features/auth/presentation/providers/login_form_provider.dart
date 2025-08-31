import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/forms/form_state.dart';
import '../../../../core/validators/form_validators.dart';

/// Provedor do estado do formulário de login
final loginFormProvider = StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});

/// Notifier para gerenciar o estado do formulário de login
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(const LoginFormState());

  /// Atualiza o email e valida
  void updateEmail(String email) {
    final emailError = FormValidators.email(email);
    state = state.copyWith(
      email: email,
      emailError: emailError,
      isValid: _isFormValid(email: email, emailError: emailError),
    );
  }

  /// Atualiza a senha e valida
  void updatePassword(String password) {
    final passwordError = FormValidators.password(password);
    state = state.copyWith(
      password: password,
      passwordError: passwordError,
      isValid: _isFormValid(password: password, passwordError: passwordError),
    );
  }

  /// Alterna a visibilidade da senha
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Inicia o processo de submissão
  void startSubmitting() {
    state = state.copyWith(
      isSubmitting: true,
      submitError: null,
    );
  }

  /// Finaliza a submissão com sucesso
  void submitSuccess() {
    state = state.copyWith(
      isSubmitting: false,
      submitError: null,
    );
  }

  /// Finaliza a submissão com erro
  void submitError(String error) {
    state = state.copyWith(
      isSubmitting: false,
      submitError: error,
    );
  }

  /// Limpa o formulário
  void clear() {
    state = const LoginFormState();
  }

  /// Valida todo o formulário
  void validate() {
    final emailError = FormValidators.email(state.email);
    final passwordError = FormValidators.password(state.password);
    
    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
      isValid: _isFormValid(
        email: state.email,
        password: state.password,
        emailError: emailError,
        passwordError: passwordError,
      ),
    );
  }

  /// Verifica se o formulário é válido
  bool _isFormValid({
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
  }) {
    final currentEmail = email ?? state.email;
    final currentPassword = password ?? state.password;
    final currentEmailError = emailError ?? state.emailError;
    final currentPasswordError = passwordError ?? state.passwordError;

    return currentEmail.isNotEmpty &&
           currentPassword.isNotEmpty &&
           currentEmailError == null &&
           currentPasswordError == null;
  }
}

/// Provedor que expõe apenas se o formulário é válido
final isLoginFormValidProvider = Provider<bool>((ref) {
  final formState = ref.watch(loginFormProvider);
  return formState.isValid;
});

/// Provedor que expõe se o formulário está sendo submetido
final isLoginFormSubmittingProvider = Provider<bool>((ref) {
  final formState = ref.watch(loginFormProvider);
  return formState.isSubmitting;
});

/// Provedor que expõe o erro de submissão
final loginFormSubmitErrorProvider = Provider<String?>((ref) {
  final formState = ref.watch(loginFormProvider);
  return formState.submitError;
});