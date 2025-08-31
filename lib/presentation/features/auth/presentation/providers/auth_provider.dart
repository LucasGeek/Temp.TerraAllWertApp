import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/user.dart';
import '../../../../../domain/repositories/auth_repository.dart';
import '../../../../../domain/usecases/login_usecase.dart';
import '../../../../../domain/usecases/logout_usecase.dart';
import '../../../../../data/repositories/auth_repository_impl.dart';

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
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
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
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (error, _) {
      // Em modo desenvolvimento, cria usuário mockado
      state = AsyncValue.data(_getMockUser());
    }
  }
  
  User _getMockUser() {
    return const User(
      id: 'dev-user-001',
      name: 'Desenvolvedor',
      email: 'dev@terraallwert.com',
      role: UserRole(
        id: 'admin',
        name: 'Administrator',
        code: 'ADMIN',
        permissions: [],
      ),
      avatar: null,
      createdAt: null,
      updatedAt: null,
      isActive: true,
    );
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