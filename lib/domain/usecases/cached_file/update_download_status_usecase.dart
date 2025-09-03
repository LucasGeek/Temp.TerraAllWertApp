import '../../repositories/cached_file_repository.dart';
import '../usecase.dart';

class UpdateDownloadStatusParams {
  final String localId;
  final bool isDownloaded;
  final String? localPath;
  
  UpdateDownloadStatusParams({
    required this.localId,
    required this.isDownloaded,
    this.localPath,
  });
}

class UpdateDownloadStatusUseCase implements VoidUseCase<UpdateDownloadStatusParams> {
  final CachedFileRepository _repository;
  
  UpdateDownloadStatusUseCase(this._repository);
  
  @override
  Future<void> call(UpdateDownloadStatusParams params) async {
    try {
      // Validate that if downloaded, local path is provided
      if (params.isDownloaded && (params.localPath?.trim().isEmpty ?? true)) {
        throw Exception('Local path is required when file is downloaded');
      }
      
      await _repository.updateDownloadStatus(
        params.localId,
        params.isDownloaded,
        params.localPath,
      );
    } catch (e) {
      throw Exception('Failed to update download status: ${e.toString()}');
    }
  }
}