import '../entities/sync_queue.dart';

abstract class SyncRepository {
  // Queue management
  Future<void> addToQueue(SyncQueue item);
  Future<List<SyncQueue>> getPendingItems();
  Future<void> updateQueueStatus(int id, QueueStatus status);
  Future<void> clearQueue();
  
  // Sync operations
  Future<void> syncAll();
  Future<void> syncEntity(String entityType, String entityLocalId);
  Future<bool> hasConflicts();
  Future<void> resolveConflict(int conflictId, String resolution);
  
  // Sync status
  Future<DateTime?> getLastSyncTime(String tableName);
  Future<void> updateLastSyncTime(String tableName, DateTime time);
  Future<int> getPendingChangesCount();
  
  // Network status
  Stream<bool> watchConnectivityStatus();
  Future<bool> isOnline();
  
  // Auto sync
  void startAutoSync({Duration interval = const Duration(minutes: 5)});
  void stopAutoSync();
}