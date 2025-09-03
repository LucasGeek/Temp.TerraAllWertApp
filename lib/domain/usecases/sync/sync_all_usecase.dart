import '../../repositories/sync_repository.dart';
import '../usecase.dart';

class SyncAllUseCase implements NoParamsUseCase<void> {
  final SyncRepository _syncRepository;
  
  SyncAllUseCase(this._syncRepository);
  
  @override
  Future<void> call() async {
    try {
      await _syncRepository.syncAll();
    } catch (e) {
      throw Exception('Failed to sync all data: ${e.toString()}');
    }
  }
}