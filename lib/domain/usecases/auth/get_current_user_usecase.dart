import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../usecase.dart';

class GetCurrentUserUseCase implements NoParamsUseCase<User?> {
  final UserRepository _userRepository;
  
  GetCurrentUserUseCase(this._userRepository);
  
  @override
  Future<User?> call() async {
    try {
      // Try to get current user from local first
      final localUser = await _userRepository.getCurrentUserLocal();
      if (localUser != null) {
        return localUser;
      }
      
      // Fallback to remote if not found locally
      return await _userRepository.getCurrentUser();
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }
}