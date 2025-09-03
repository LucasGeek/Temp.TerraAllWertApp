import '../../repositories/download_queue_repository.dart';
import '../usecase.dart';

class RetryFailedDownloadsUseCase implements NoParamsUseCase<void> {
  final DownloadQueueRepository _repository;
  
  RetryFailedDownloadsUseCase(this._repository);
  
  @override
  Future<void> call() async {
    try {
      await _repository.retryFailed();
    } catch (e) {
      throw Exception('Failed to retry failed downloads: ${e.toString()}');
    }
  }
}