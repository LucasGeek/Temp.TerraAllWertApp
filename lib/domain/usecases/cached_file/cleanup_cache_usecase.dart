import '../../repositories/cached_file_repository.dart';
import '../usecase.dart';

class CleanupCacheParams {
  final int maxSizeBytes;
  
  CleanupCacheParams({required this.maxSizeBytes});
}

class CleanupCacheUseCase implements VoidUseCase<CleanupCacheParams> {
  final CachedFileRepository _repository;
  
  CleanupCacheUseCase(this._repository);
  
  @override
  Future<void> call(CleanupCacheParams params) async {
    try {
      // Validate max size
      if (params.maxSizeBytes < 0) {
        throw Exception('Max size must be non-negative');
      }
      
      // Clear expired files first
      await _repository.clearExpired();
      
      // Then cleanup by size if needed
      await _repository.cleanupCache(params.maxSizeBytes);
    } catch (e) {
      throw Exception('Failed to cleanup cache: ${e.toString()}');
    }
  }
}