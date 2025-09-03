import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../utils/notification/snackbar_notification.dart';
import '../utils/errors/api_error_handler.dart';

/// Estado de autenticação
enum AuthStatus { initial, loading, authenticated, unauthenticated }

/// Classe para representar o estado de autenticação
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
}

/// Provider para LoginUseCase
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return GetIt.instance<LoginUseCase>();
});

/// Provider para LogoutUseCase
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return GetIt.instance<LogoutUseCase>();
});

/// Provider para GetCurrentUserUseCase
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetIt.instance<GetCurrentUserUseCase>();
});

/// Notifier para gerenciar o estado de autenticação
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthNotifier(this._loginUseCase, this._logoutUseCase, this._getCurrentUserUseCase) 
      : super(const AuthState(status: AuthStatus.initial));

  /// Verifica se o usuário está logado
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final user = await _getCurrentUserUseCase();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      // Se não conseguir obter usuário atual, considera não autenticado
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login do usuário usando use case
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final user = await _loginUseCase.execute(email: email, password: password);
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
      
      // Sucesso - mostrar notificação de boas-vindas
      SnackbarNotification.showSuccess('Bem-vindo(a), ${user.name}!');
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: null, // Não mantém erro no estado, usa Snackbar
      );
      
      // Erro - mostrar notificação global
      SnackbarNotification.showError(errorMessage);
    }
  }

  /// Logout do usuário usando use case
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      await _logoutUseCase.execute();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      // Mesmo com erro, efetua logout localmente
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Extrai mensagem de erro amigável usando ApiErrorHandler
  String _getErrorMessage(dynamic error) {
    return ApiErrorHandler.extractErrorMessage(error);
  }
}

/// Provider de autenticação
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(loginUseCaseProvider),
    ref.read(logoutUseCaseProvider),
    ref.read(getCurrentUserUseCaseProvider),
  );
});

/// Provider que expõe apenas o status de autenticação
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

/// Provider que expõe o usuário atual
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});