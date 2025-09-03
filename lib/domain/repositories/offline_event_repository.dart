import '../entities/offline_event.dart';

abstract class OfflineEventRepository {
  // Basic CRUD operations
  Future<OfflineEvent> create(OfflineEvent event);
  Future<OfflineEvent> update(OfflineEvent event);
  Future<void> delete(String localId);
  Future<OfflineEvent?> getById(String localId);
  Future<List<OfflineEvent>> getAll();
  
  // Business-specific queries
  Future<List<OfflineEvent>> getPending();
  Future<List<OfflineEvent>> getProcessed();
  Future<List<OfflineEvent>> getFailed();
  Future<List<OfflineEvent>> getByEntityType(String entityType);
  Future<List<OfflineEvent>> getBySessionId(String sessionId);
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<OfflineEvent>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  Future<void> clearProcessed();
  
  // Event processing
  Future<void> markAsProcessed(String localId);
  Future<void> markAsFailed(String localId, String error);
  Future<void> retryFailed();
  Future<List<OfflineEvent>> getNextBatch(int limit);
}