import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infra/graphql/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GraphQLAuthService _authService;

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  final StreamController<User?> _userController = StreamController<User?>.broadcast();

  AuthRepositoryImpl({
    required GraphQLAuthService authService,
  }) : _authService = authService;

  @override
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    try {
      final authToken = await _authService.login(
        email: email,
        password: password,
      );

      final user = await _authService.getCurrentUser();
      if (user != null) {
        _userController.add(user);
      }

      _authStateController.add(true);
      return authToken;
    } catch (e) {
      _authStateController.add(false);
      rethrow;
    }
  }

  @override
  Future<AuthToken> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final authToken = await _authService.signup(
        email: email,
        password: password,
        name: name,
      );

      final user = await _authService.getCurrentUser();
      if (user != null) {
        _userController.add(user);
      }

      _authStateController.add(true);
      return authToken;
    } catch (e) {
      _authStateController.add(false);
      rethrow;
    }
  }

  @override
  Future<AuthToken> refreshToken(String refreshToken) async {
    try {
      final authToken = await _authService.refreshToken();
      _authStateController.add(true);
      return authToken;
    } catch (e) {
      await clearToken();
      _authStateController.add(false);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      // Continue even if remote logout fails
    } finally {
      _authStateController.add(false);
      _userController.add(null);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    // First try to get stored user data
    final storedUser = await _authService.getStoredUser();
    if (storedUser != null) {
      _userController.add(storedUser);
      return storedUser;
    }

    // If no stored user, try to fetch from server
    try {
      final user = await _authService.getCurrentUser();
      _userController.add(user);
      return user;
    } catch (e) {
      // If server fetch fails, throw exception to allow AuthController to handle
      _userController.add(null);
      rethrow; // Rethrow to let AuthController create minimal user
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final isAuth = await _authService.hasValidToken();
    _authStateController.add(isAuth);
    return isAuth;
  }

  @override
  Future<AuthToken?> getStoredToken() async {
    final token = await _authService.getStoredAccessToken();
    if (token == null) return null;
    
    // Return minimal token for validation purposes
    return AuthToken(
      accessToken: token,
      refreshToken: '',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
      tokenType: 'Bearer',
    );
  }

  @override
  Future<void> storeToken(AuthToken token) async {
    // This would require converting back to response format
    // For now, this is handled in login/refresh methods
  }

  @override
  Future<void> clearToken() async {
    await _authService.logout();
  }

  @override
  Stream<bool> watchAuthState() {
    return _authStateController.stream;
  }

  @override
  Stream<User?> watchCurrentUser() {
    return _userController.stream;
  }

  void dispose() {
    _authStateController.close();
    _userController.close();
  }
}

// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(graphQLAuthServiceProvider);
  return AuthRepositoryImpl(authService: authService);
});