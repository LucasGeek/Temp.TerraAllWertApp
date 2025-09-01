import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/user.dart';
import '../../../../../domain/repositories/auth_repository.dart';
import '../../../../../domain/usecases/login_usecase.dart';
import '../../../../../domain/usecases/logout_usecase.dart';
import '../../../../../data/repositories/auth_repository_impl.dart';
import '../../../../utils/error_handler.dart';

// Use Cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

// Auth State Providers
final authStateProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.watchAuthState();
});

final currentUserProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.watchCurrentUser();
});

final isAuthenticatedProvider = FutureProvider<bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.isAuthenticated();
});

// Auth Controller
class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthController({
    required AuthRepository repository,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _repository = repository,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    try {
      // Check for stored tokens first
      final isAuthenticated = await _repository.isAuthenticated();
      
      if (isAuthenticated) {
        // Try to get user data if we have valid tokens
        if (kDebugMode) {
          print('[AUTH] Valid tokens found during init, attempting to get user data');
        }
        try {
          final user = await _repository.getCurrentUser();
          if (user != null) {
            if (kDebugMode) {
              print('[AUTH] User data retrieved successfully during init');
            }
            state = AsyncValue.data(user);
            return;
          } else {
            if (kDebugMode) {
              print('[AUTH] getCurrentUser returned null during init');
            }
            
            // If we have valid tokens but no user data, create minimal user
            final minimalUser = User(
              id: 'authenticated_user',
              email: 'user@app.com',
              name: 'User',
              avatar: null,
              isActive: true,
              role: UserRole(id: '1', name: 'Admin', code: 'ADMIN'),
            );
            
            if (kDebugMode) {
              print('[AUTH] Created minimal user for null user data during init');
            }
            
            state = AsyncValue.data(minimalUser);
            return;
          }
        } catch (userError) {
          // If user fetch fails but we have valid tokens, create minimal user
          if (kDebugMode) {
            print('[AUTH] Valid token found but user fetch failed during init: $userError');
          }
          
          // Create minimal user for valid tokens
          final minimalUser = User(
            id: 'authenticated_user',
            email: 'user@app.com',
            name: 'User',
            avatar: null,
            isActive: true,
            role: UserRole(id: '1', name: 'Admin', code: 'ADMIN'),
          );
          
          if (kDebugMode) {
            print('[AUTH] Created minimal user for valid token during init');
          }
          
          state = AsyncValue.data(minimalUser);
          return;
        }
      }
      
      // No valid authentication
      state = const AsyncValue.data(null);
    } catch (error, _) {
      // Em modo desenvolvimento, retorna null (não autenticado)
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _loginUseCase(email: email, password: password);
      
      // Try to get user data, but don't fail login if user fetch fails
      final user = await _repository.getCurrentUser();
      if (user != null) {
        if (kDebugMode) {
          print('[AUTH] Login succeeded and user data retrieved');
        }
        state = AsyncValue.data(user);
      } else {
        // If user data is null, create minimal user for successful login
        if (kDebugMode) {
          print('[AUTH] Login succeeded but getCurrentUser returned null');
        }
        
        final minimalUser = User(
          id: 'authenticated_user',
          email: email,
          name: email.split('@')[0],
          avatar: null,
          isActive: true,
          role: UserRole(id: '1', name: 'User', code: 'USER'),
        );
        
        if (kDebugMode) {
          print('[AUTH] Created minimal user for successful login with null user data');
        }
        
        state = AsyncValue.data(minimalUser);
      }
    } catch (error, _) {
      // Criar uma exceção mais específica baseada no erro original
      final friendlyMessage = ErrorHandler.getAuthErrorMessage(error);
      final friendlyError = Exception(friendlyMessage);
      
      // Log apenas em modo debug, sem stack trace para erros de autenticação
      if (kDebugMode) {
        print('[AUTH] Login failed: $friendlyMessage');
      }
      
      state = AsyncValue.error(friendlyError, StackTrace.empty);
      throw friendlyError; // Propaga o erro amigável
    }
  }
  

  Future<void> logout() async {
    try {
      await _logoutUseCase();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final logoutUseCase = ref.watch(logoutUseCaseProvider);
  
  return AuthController(
    repository: repository,
    loginUseCase: loginUseCase,
    logoutUseCase: logoutUseCase,
  );
});