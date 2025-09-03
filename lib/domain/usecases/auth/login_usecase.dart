import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

class LoginUseCase {
  final UserRepository _repository;

  LoginUseCase(this._repository);

  Future<User> execute({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email address');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    try {
      // Attempt login
      final user = await _repository.login(email, password);
      
      // Save user locally for offline access
      await _repository.saveUserLocal(user);
      
      // Save tokens
      if (user.accessToken != null && user.refreshToken != null) {
        await _repository.saveTokens(user.accessToken!, user.refreshToken!);
      }
      
      return user;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }
}