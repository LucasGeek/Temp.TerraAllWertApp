import '../../repositories/offline_event_repository.dart';

class SyncOfflineEventsUseCase {
  final OfflineEventRepository _repository;
  
  SyncOfflineEventsUseCase(this._repository);
  
  Future<int> call() async {
    try {
      // Get pending events
      final pendingEvents = await _repository.getPending();
      
      if (pendingEvents.isEmpty) {
        return 0;
      }
      
      // Sync to remote
      await _repository.syncToRemote();
      
      // Process events in batches
      int processedCount = 0;
      const batchSize = 10;
      
      for (int i = 0; i < pendingEvents.length; i += batchSize) {
        final batch = pendingEvents.skip(i).take(batchSize).toList();
        
        for (final event in batch) {
          try {
            await _repository.markAsProcessed(event.localId);
            processedCount++;
          } catch (e) {
            await _repository.markAsFailed(event.localId, e.toString());
          }
        }
      }
      
      return processedCount;
    } catch (e) {
      throw Exception('Failed to sync offline events: ${e.toString()}');
    }
  }
  
  Future<void> retryFailedEvents() async {
    try {
      await _repository.retryFailed();
    } catch (e) {
      throw Exception('Failed to retry failed events: ${e.toString()}');
    }
  }
}