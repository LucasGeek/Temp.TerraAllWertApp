import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../usecase.dart';

class UpdateProfileParams {
  final String name;
  final String? avatarUrl;
  
  UpdateProfileParams({
    required this.name,
    this.avatarUrl,
  });
}

class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final UserRepository _userRepository;
  
  UpdateProfileUseCase(this._userRepository);
  
  @override
  Future<User> call(UpdateProfileParams params) async {
    try {
      // Get current user
      final currentUser = await _userRepository.getCurrentUserLocal();
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }
      
      // Update user with new information
      final updatedUser = currentUser.copyWith(
        name: params.name,
        avatarUrl: params.avatarUrl ?? currentUser.avatarUrl,
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Update profile
      final result = await _userRepository.updateProfile(updatedUser);
      
      // Save locally
      await _userRepository.saveUserLocal(result);
      
      return result;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}