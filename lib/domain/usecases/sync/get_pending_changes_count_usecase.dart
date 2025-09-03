import '../../repositories/sync_repository.dart';
import '../usecase.dart';

class GetPendingChangesCountUseCase implements NoParamsUseCase<int> {
  final SyncRepository _syncRepository;
  
  GetPendingChangesCountUseCase(this._syncRepository);
  
  @override
  Future<int> call() async {
    try {
      return await _syncRepository.getPendingChangesCount();
    } catch (e) {
      throw Exception('Failed to get pending changes count: ${e.toString()}');
    }
  }
}