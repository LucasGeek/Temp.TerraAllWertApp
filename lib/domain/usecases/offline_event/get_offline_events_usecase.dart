import '../../entities/offline_event.dart';
import '../../repositories/offline_event_repository.dart';

class GetOfflineEventsUseCase {
  final OfflineEventRepository _repository;
  
  GetOfflineEventsUseCase(this._repository);
  
  Future<List<OfflineEvent>> call({
    String? status,
    String? entityType,
    int? limit,
  }) async {
    try {
      if (status == 'pending') {
        return await _repository.getPending();
      }
      
      if (status == 'processed') {
        return await _repository.getProcessed();
      }
      
      if (status == 'failed') {
        return await _repository.getFailed();
      }
      
      if (entityType != null) {
        return await _repository.getByEntityType(entityType);
      }
      
      if (limit != null) {
        return await _repository.getNextBatch(limit);
      }
      
      return await _repository.getAll();
    } catch (e) {
      throw Exception('Failed to get offline events: ${e.toString()}');
    }
  }
}