import '../../entities/offline_event.dart';
import '../../repositories/offline_event_repository.dart';
import '../usecase.dart';

class ProcessOfflineEventsParams {
  final int batchSize;
  
  ProcessOfflineEventsParams({this.batchSize = 10});
}

class ProcessOfflineEventsUseCase implements UseCase<List<OfflineEvent>, ProcessOfflineEventsParams> {
  final OfflineEventRepository _repository;
  
  ProcessOfflineEventsUseCase(this._repository);
  
  @override
  Future<List<OfflineEvent>> call(ProcessOfflineEventsParams params) async {
    try {
      // Validate batch size
      if (params.batchSize <= 0) {
        throw Exception('Batch size must be positive');
      }
      
      // Get next batch of events to process
      return await _repository.getNextBatch(params.batchSize);
    } catch (e) {
      throw Exception('Failed to process offline events: ${e.toString()}');
    }
  }
}