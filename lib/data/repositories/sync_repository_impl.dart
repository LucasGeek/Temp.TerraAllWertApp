import '../../domain/entities/sync_queue.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/sync_queue_local_datasource.dart';
import 'package:uuid/uuid.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncQueueLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();
  bool _autoSyncActive = false;
  
  SyncRepositoryImpl(this._localDataSource);
  
  @override
  Future<void> addToQueue(SyncQueue item) async {
    try {
      final queueItem = item.copyWith(
        localId: _uuid.v7(),
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(queueItem);
    } catch (e) {
      throw Exception('Failed to add item to sync queue: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncQueue>> getPendingItems() async {
    try {
      final allItems = await _localDataSource.getAll();
      return allItems.where((item) => 
        item.status == QueueStatus.pending || 
        item.status == QueueStatus.failed
      ).toList();
    } catch (e) {
      throw Exception('Failed to get pending items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateQueueStatus(int id, QueueStatus status) async {
    try {
      final item = await _localDataSource.getById(id.toString());
      if (item != null) {
        final updatedItem = item.copyWith(
          status: status,
          lastModifiedAt: DateTime.now(),
          processedAt: status == QueueStatus.completed ? DateTime.now() : null,
        );
        await _localDataSource.save(updatedItem);
      }
    } catch (e) {
      throw Exception('Failed to update queue status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearQueue() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear sync queue: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncAll() async {
    try {
      final pendingItems = await getPendingItems();
      
      for (final item in pendingItems) {
        try {
          await syncEntity(item.entityType, item.entityLocalId);
          await updateQueueStatus(int.parse(item.localId), QueueStatus.completed);
        } catch (e) {
          await updateQueueStatus(int.parse(item.localId), QueueStatus.failed);
        }
      }
    } catch (e) {
      throw Exception('Failed to sync all items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncEntity(String entityType, String entityLocalId) async {
    try {
      // This would implement specific sync logic for each entity type
      // For now, we'll just mark it as processed
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      throw Exception('Failed to sync entity: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> hasConflicts() async {
    try {
      final allItems = await _localDataSource.getAll();
      return allItems.any((item) => item.status == QueueStatus.conflict);
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<void> resolveConflict(int conflictId, String resolution) async {
    try {
      final item = await _localDataSource.getById(conflictId.toString());
      if (item != null) {
        final updatedItem = item.copyWith(
          status: QueueStatus.completed,
          lastModifiedAt: DateTime.now(),
          processedAt: DateTime.now(),
        );
        await _localDataSource.save(updatedItem);
      }
    } catch (e) {
      throw Exception('Failed to resolve conflict: ${e.toString()}');
    }
  }
  
  @override
  Future<DateTime?> getLastSyncTime(String tableName) async {
    try {
      final allItems = await _localDataSource.getAll();
      final completedItems = allItems.where((item) => 
        item.entityType == tableName && 
        item.status == QueueStatus.completed &&
        item.processedAt != null
      ).toList();
      
      if (completedItems.isEmpty) return null;
      
      completedItems.sort((a, b) => b.processedAt!.compareTo(a.processedAt!));
      return completedItems.first.processedAt;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> updateLastSyncTime(String tableName, DateTime time) async {
    try {
      // This would typically be stored in metadata
      // For now, we'll create a sync item to track this
      final syncItem = SyncQueue(
        localId: _uuid.v7(),
        entityType: tableName,
        entityLocalId: 'metadata',
        operation: SyncOperation.update,
        payload: {'last_sync': time.toIso8601String()},
        status: QueueStatus.completed,
        createdAt: time,
        lastModifiedAt: time,
        processedAt: time,
      );
      
      await _localDataSource.save(syncItem);
    } catch (e) {
      throw Exception('Failed to update last sync time: ${e.toString()}');
    }
  }
  
  @override
  Future<int> getPendingChangesCount() async {
    try {
      final pendingItems = await getPendingItems();
      return pendingItems.length;
    } catch (e) {
      return 0;
    }
  }
  
  @override
  Stream<bool> watchConnectivityStatus() {
    // This would typically use connectivity_plus package
    // For now, return a simple stream that indicates online status
    return Stream.periodic(const Duration(seconds: 5), (count) => true);
  }
  
  @override
  Future<bool> isOnline() async {
    try {
      // This would check actual network connectivity
      // For now, assume we're always online
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    if (_autoSyncActive) return;
    
    _autoSyncActive = true;
    
    // This would typically use a Timer.periodic
    // For now, we'll just set the flag
  }
  
  @override
  void stopAutoSync() {
    _autoSyncActive = false;
  }
}