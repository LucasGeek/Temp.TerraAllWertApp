import '../../repositories/download_queue_repository.dart';
import '../usecase.dart';

class GetDownloadProgressUseCase implements NoParamsUseCase<double> {
  final DownloadQueueRepository _repository;
  
  GetDownloadProgressUseCase(this._repository);
  
  @override
  Future<double> call() async {
    try {
      return await _repository.getTotalProgress();
    } catch (e) {
      throw Exception('Failed to get download progress: ${e.toString()}');
    }
  }
}