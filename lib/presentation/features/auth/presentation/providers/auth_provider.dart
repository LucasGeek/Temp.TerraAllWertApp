import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/user.dart';
import '../../../../../domain/repositories/auth_repository.dart';
import '../../../../../domain/usecases/login_usecase.dart';
import '../../../../../domain/usecases/logout_usecase.dart';
import '../../../../../data/repositories/auth_repository_impl.dart';
import '../../../../utils/error_handler.dart';
import '../../../../providers/connectivity_provider.dart';
import '../../../../providers/post_login_sync_provider.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../../../../domain/services/post_login_sync_service.dart';

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

// Provider para verificar se o usuário pode acessar o app (autenticado ou offline)
final canAccessAppProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(authControllerProvider);
  final isOnline = ref.watch(isOnlineProvider);
  final isWeb = ref.watch(isWebProvider);
  
  return userAsync.when(
    data: (user) {
      // Se há usuário autenticado, sempre pode acessar
      if (user != null) return true;
      
      // Se não há usuário:
      // - Web sempre exige autenticação
      // - Mobile offline permite acesso apenas para visualização
      // - Mobile online exige autenticação
      if (isWeb) return false; // Web sempre exige login
      
      return !isOnline; // Mobile só permite sem login quando offline
    },
    loading: () => true, // Durante loading, permitir acesso
    error: (_, _) => !isOnline && !isWeb, // Em caso de erro, offline mobile pode acessar
  );
});

// Provider para verificar se deve forçar login
final shouldForceLoginProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(authControllerProvider);
  final isOnline = ref.watch(isOnlineProvider);
  final isWeb = ref.watch(isWebProvider);
  
  return userAsync.when(
    data: (user) {
      // Se já tem usuário, não forçar login
      if (user != null) return false;
      
      // Forçar login se:
      // - É web (sempre)
      // - É mobile e está online
      return isWeb || (isOnline && !isWeb);
    },
    loading: () => false, // Durante loading, não forçar login ainda
    error: (_, _) => isWeb || (isOnline && !isWeb), // Em caso de erro, mesma regra
  );
});

// Auth Controller
class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final Ref _ref;

  AuthController({
    required AuthRepository repository,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required Ref ref,
  })  : _repository = repository,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _ref = ref,
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
          debugPrint('[AUTH] Valid tokens found during init, attempting to get user data');
        }
        try {
          final user = await _repository.getCurrentUser();
          if (user != null) {
            if (kDebugMode) {
              debugPrint('[AUTH] User data retrieved successfully during init');
            }
            state = AsyncValue.data(user);
            return;
          } else {
            if (kDebugMode) {
              debugPrint('[AUTH] getCurrentUser returned null during init');
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
              debugPrint('[AUTH] Created minimal user for null user data during init');
            }
            
            state = AsyncValue.data(minimalUser);
            return;
          }
        } catch (userError) {
          // If user fetch fails but we have valid tokens, create minimal user
          if (kDebugMode) {
            debugPrint('[AUTH] Valid token found but user fetch failed during init: $userError');
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
            debugPrint('[AUTH] Created minimal user for valid token during init');
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
          debugPrint('[AUTH] Login succeeded and user data retrieved');
        }
        state = AsyncValue.data(user);
        
        // Executar sincronização pós-login em background
        _executePostLoginSync(user);
        
      } else {
        // If user data is null, create minimal user for successful login
        if (kDebugMode) {
          debugPrint('[AUTH] Login succeeded but getCurrentUser returned null');
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
          debugPrint('[AUTH] Created minimal user for successful login with null user data');
        }
        
        state = AsyncValue.data(minimalUser);
        
        // Executar sincronização pós-login também para usuário minimal
        _executePostLoginSync(minimalUser);
      }
    } catch (error, _) {
      // Criar uma exceção mais específica baseada no erro original
      final friendlyMessage = ErrorHandler.getAuthErrorMessage(error);
      final friendlyError = Exception(friendlyMessage);
      
      // Log apenas em modo debug, sem stack trace para erros de autenticação
      if (kDebugMode) {
        debugPrint('[AUTH] Login failed: $friendlyMessage');
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

  /// Executa a sincronização pós-login em background
  void _executePostLoginSync(User user) {
    // Executar em background sem bloquear o login
    Future.microtask(() {
      try {
        if (kDebugMode) {
          debugPrint('[AUTH] Starting post-login sync for user: ${user.email}');
        }
        
        // Disparar sincronização através do provider
        final syncNotifier = _ref.read(postLoginSyncNotifierProvider.notifier);
        syncNotifier.executeSync(user).then((result) {
          // Se a sincronização foi bem-sucedida e trouxe menus da API
          final syncResult = _ref.read(syncResultProvider);
          if (syncResult?.success == true && syncResult?.menuResult.success == true && 
              syncResult?.menuResult.source == MenuSyncSource.api) {
            
            // Recarregar os menus no NavigationProvider
            try {
              final navigationNotifier = _ref.read(navigationItemsProvider.notifier);
              navigationNotifier.reloadFromStorage().catchError((e) {
                if (kDebugMode) {
                  debugPrint('[AUTH] Failed to reload navigation after sync: $e');
                }
              });
              
              if (kDebugMode) {
                debugPrint('[AUTH] Post-login sync completed successfully, navigation reloaded');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[AUTH] Failed to trigger navigation reload: $e');
              }
            }
          }
        }).catchError((e) {
          if (kDebugMode) {
            debugPrint('[AUTH] Post-login sync failed: $e');
          }
          // Não falhar o login se a sincronização falhar
        });
        
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AUTH] Failed to start post-login sync: $e');
        }
        // Não falhar o login se não conseguir iniciar a sincronização
      }
    });
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
    ref: ref,
  );
});