import '../../repositories/download_queue_repository.dart';
import '../usecase.dart';

class UpdateDownloadProgressParams {
  final String localId;
  final double progress;
  final int? downloadedBytes;
  
  UpdateDownloadProgressParams({
    required this.localId,
    required this.progress,
    this.downloadedBytes,
  });
}

class UpdateDownloadProgressUseCase implements VoidUseCase<UpdateDownloadProgressParams> {
  final DownloadQueueRepository _repository;
  
  UpdateDownloadProgressUseCase(this._repository);
  
  @override
  Future<void> call(UpdateDownloadProgressParams params) async {
    try {
      // Validate progress
      if (params.progress < 0.0 || params.progress > 1.0) {
        throw Exception('Progress must be between 0.0 and 1.0');
      }
      
      if (params.downloadedBytes != null && params.downloadedBytes! < 0) {
        throw Exception('Downloaded bytes must be non-negative');
      }
      
      await _repository.updateProgress(params.localId, params.progress);
    } catch (e) {
      throw Exception('Failed to update download progress: ${e.toString()}');
    }
  }
}