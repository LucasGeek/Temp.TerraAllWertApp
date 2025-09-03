import '../entities/user.dart';

abstract class UserRepository {
  // Auth operations
  Future<User> login(String email, String password);
  Future<User> refreshToken(String refreshToken);
  Future<void> logout();
  
  // User operations
  Future<User?> getCurrentUser();
  Future<User> updateProfile(User user);
  Future<void> updateAvatar(String avatarUrl);
  
  // Local operations
  Future<User?> getCurrentUserLocal();
  Future<void> saveUserLocal(User user);
  Future<void> clearUserLocal();
  
  // Token management
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clearTokens();
  
  // Session management
  Future<bool> isAuthenticated();
  Stream<User?> watchCurrentUser();
}