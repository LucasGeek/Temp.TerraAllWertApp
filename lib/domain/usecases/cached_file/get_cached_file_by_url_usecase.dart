import '../../entities/cached_file.dart';
import '../../repositories/cached_file_repository.dart';
import '../usecase.dart';

class GetCachedFileByUrlParams {
  final String originalUrl;
  
  GetCachedFileByUrlParams({required this.originalUrl});
}

class GetCachedFileByUrlUseCase implements UseCase<CachedFile?, GetCachedFileByUrlParams> {
  final CachedFileRepository _repository;
  
  GetCachedFileByUrlUseCase(this._repository);
  
  @override
  Future<CachedFile?> call(GetCachedFileByUrlParams params) async {
    try {
      return await _repository.getByUrl(params.originalUrl);
    } catch (e) {
      throw Exception('Failed to get cached file by URL: ${e.toString()}');
    }
  }
}