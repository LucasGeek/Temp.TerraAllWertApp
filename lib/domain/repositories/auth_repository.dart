import '../entities/user.dart';
import '../entities/auth_token.dart';

abstract class AuthRepository {
  Future<AuthToken> login({
    required String email,
    required String password,
  });

  Future<AuthToken> signup({
    required String email,
    required String password,
    required String name,
  });

  Future<AuthToken> refreshToken(String refreshToken);

  Future<void> logout();

  Future<User?> getCurrentUser();

  Future<bool> isAuthenticated();

  Future<AuthToken?> getStoredToken();

  Future<void> storeToken(AuthToken token);

  Future<void> clearToken();

  Stream<bool> watchAuthState();

  Stream<User?> watchCurrentUser();
}