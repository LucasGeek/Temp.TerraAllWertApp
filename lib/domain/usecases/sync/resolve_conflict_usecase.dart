import '../../repositories/sync_repository.dart';
import '../usecase.dart';

class ResolveConflictParams {
  final int conflictId;
  final String resolution; // 'local', 'remote', 'merge'
  
  ResolveConflictParams({
    required this.conflictId,
    required this.resolution,
  });
}

class ResolveConflictUseCase implements VoidUseCase<ResolveConflictParams> {
  final SyncRepository _syncRepository;
  
  ResolveConflictUseCase(this._syncRepository);
  
  @override
  Future<void> call(ResolveConflictParams params) async {
    try {
      // Validate resolution type
      final validResolutions = ['local', 'remote', 'merge'];
      if (!validResolutions.contains(params.resolution)) {
        throw Exception('Invalid resolution type. Must be one of: ${validResolutions.join(", ")}');
      }
      
      await _syncRepository.resolveConflict(
        params.conflictId,
        params.resolution,
      );
    } catch (e) {
      throw Exception('Failed to resolve conflict: ${e.toString()}');
    }
  }
}