import '../../repositories/user_repository.dart';
import '../usecase.dart';

class UpdateAvatarParams {
  final String avatarUrl;
  
  UpdateAvatarParams({required this.avatarUrl});
}

class UpdateAvatarUseCase implements VoidUseCase<UpdateAvatarParams> {
  final UserRepository _userRepository;
  
  UpdateAvatarUseCase(this._userRepository);
  
  @override
  Future<void> call(UpdateAvatarParams params) async {
    try {
      // Validate avatar URL
      if (params.avatarUrl.isEmpty) {
        throw Exception('Avatar URL cannot be empty');
      }
      
      if (!_isValidUrl(params.avatarUrl)) {
        throw Exception('Invalid avatar URL format');
      }
      
      // Update avatar
      await _userRepository.updateAvatar(params.avatarUrl);
      
      // Update local user data
      final currentUser = await _userRepository.getCurrentUserLocal();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          avatarUrl: params.avatarUrl,
          lastModifiedAt: DateTime.now(),
          isModified: true,
        );
        await _userRepository.saveUserLocal(updatedUser);
      }
    } catch (e) {
      throw Exception('Failed to update avatar: ${e.toString()}');
    }
  }
  
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}