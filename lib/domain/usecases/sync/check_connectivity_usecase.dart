import '../../repositories/sync_repository.dart';
import '../usecase.dart';

class CheckConnectivityUseCase implements NoParamsUseCase<bool> {
  final SyncRepository _syncRepository;
  
  CheckConnectivityUseCase(this._syncRepository);
  
  @override
  Future<bool> call() async {
    try {
      return await _syncRepository.isOnline();
    } catch (e) {
      // Return false if unable to check connectivity
      return false;
    }
  }
}