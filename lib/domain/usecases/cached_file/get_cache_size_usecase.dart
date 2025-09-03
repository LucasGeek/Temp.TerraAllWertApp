import '../../repositories/cached_file_repository.dart';
import '../usecase.dart';

class GetCacheSizeUseCase implements NoParamsUseCase<int> {
  final CachedFileRepository _repository;
  
  GetCacheSizeUseCase(this._repository);
  
  @override
  Future<int> call() async {
    try {
      return await _repository.getTotalCacheSize();
    } catch (e) {
      throw Exception('Failed to get cache size: ${e.toString()}');
    }
  }
}