import '../../repositories/user_repository.dart';
import '../../repositories/sync_repository.dart';

class LogoutUseCase {
  final UserRepository _userRepository;
  final SyncRepository _syncRepository;

  LogoutUseCase(this._userRepository, this._syncRepository);

  Future<void> execute() async {
    try {
      // Sync any pending changes before logout
      if (await _syncRepository.isOnline()) {
        await _syncRepository.syncAll();
      }
      
      // Logout from server
      await _userRepository.logout();
      
      // Clear local user data
      await _userRepository.clearUserLocal();
      
      // Clear tokens
      await _userRepository.clearTokens();
      
      // Clear sync queue
      await _syncRepository.clearQueue();
      
    } catch (e) {
      // Even if logout fails, clear local data
      await _userRepository.clearUserLocal();
      await _userRepository.clearTokens();
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
}