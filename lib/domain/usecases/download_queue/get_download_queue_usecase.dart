import '../../entities/download_queue.dart';
import '../../repositories/download_queue_repository.dart';
import '../usecase.dart';

class GetDownloadQueueParams {
  final int? limit;
  
  GetDownloadQueueParams({this.limit});
}

class GetDownloadQueueUseCase implements UseCase<List<DownloadQueue>, GetDownloadQueueParams> {
  final DownloadQueueRepository _repository;
  
  GetDownloadQueueUseCase(this._repository);
  
  @override
  Future<List<DownloadQueue>> call(GetDownloadQueueParams params) async {
    try {
      if (params.limit != null && params.limit! > 0) {
        return await _repository.getNextBatch(params.limit!);
      } else {
        return await _repository.getPending();
      }
    } catch (e) {
      throw Exception('Failed to get download queue: ${e.toString()}');
    }
  }
}