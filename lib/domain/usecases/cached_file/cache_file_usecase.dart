import '../../entities/cached_file.dart';
import '../../repositories/cached_file_repository.dart';
import '../usecase.dart';

class CacheFileParams {
  final String originalUrl;
  final String fileName;
  final String mimeType;
  final DateTime? expiresAt;
  
  CacheFileParams({
    required this.originalUrl,
    required this.fileName,
    required this.mimeType,
    this.expiresAt,
  });
}

class CacheFileUseCase implements UseCase<CachedFile, CacheFileParams> {
  final CachedFileRepository _repository;
  
  CacheFileUseCase(this._repository);
  
  @override
  Future<CachedFile> call(CacheFileParams params) async {
    try {
      // Validate parameters
      if (params.originalUrl.trim().isEmpty) {
        throw Exception('Original URL cannot be empty');
      }
      
      if (params.fileName.trim().isEmpty) {
        throw Exception('File name cannot be empty');
      }
      
      if (params.mimeType.trim().isEmpty) {
        throw Exception('MIME type cannot be empty');
      }
      
      // Check if file already exists
      final existingFile = await _repository.getByUrl(params.originalUrl);
      if (existingFile != null) {
        return existingFile;
      }
      
      // Create new cached file entry
      final cachedFile = CachedFile(
        localId: '', // Will be set by repository
        fileType: _getFileTypeFromMimeType(params.mimeType),
        mimeType: params.mimeType.trim(),
        originalName: params.fileName.trim(),
        remoteUrl: params.originalUrl.trim(),
        fileSizeBytes: 0, // Will be set when file is downloaded
        expiresAt: params.expiresAt,
        createdAt: DateTime.now(),
      );
      
      return await _repository.create(cachedFile);
    } catch (e) {
      throw Exception('Failed to cache file: ${e.toString()}');
    }
  }
  
  String _getFileTypeFromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType == 'application/pdf') return 'document';
    if (mimeType.startsWith('text/')) return 'document';
    return 'file';
  }
}