import '../../../domain/entities/sync_queue.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class SyncQueueLocalDataSource {
  Future<List<SyncQueue>> getAll();
  Future<SyncQueue?> getById(String id);
  Future<List<SyncQueue>> getPending();
  Future<List<SyncQueue>> getFailed();
  Future<void> save(SyncQueue item);
  Future<void> saveAll(List<SyncQueue> items);
  Future<void> delete(String id);
  Future<void> clear();
  Future<void> updateStatus(String localId, QueueStatus status);
  Future<void> updateRetryCount(String localId, int retryCount);
}

class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'sync_queue';
  
  SyncQueueLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<SyncQueue>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => SyncQueue.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<SyncQueue?> getById(String id) async {
    try {
      final items = await getAll();
      return items.where((item) => item.localId == id || item.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<SyncQueue>> getPending() async {
    try {
      final items = await getAll();
      return items.where((item) => item.status == QueueStatus.pending).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<SyncQueue>> getFailed() async {
    try {
      final items = await getAll();
      return items.where((item) => item.status == QueueStatus.failed).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(SyncQueue item) async {
    try {
      final items = await getAll();
      final index = items.indexWhere((i) => i.localId == item.localId);
      
      if (index >= 0) {
        items[index] = item;
      } else {
        items.add(item);
      }
      
      final jsonList = items.map((item) => item.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save sync queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<SyncQueue> items) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save sync queue items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final items = await getAll();
      items.removeWhere((item) => item.localId == id || item.remoteId == id);
      
      final jsonList = items.map((item) => item.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete sync queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear sync queue: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateStatus(String localId, QueueStatus status) async {
    try {
      final item = await getById(localId);
      if (item != null) {
        final updatedItem = item.copyWith(
          status: status,
          lastModifiedAt: DateTime.now(),
        );
        await save(updatedItem);
      }
    } catch (e) {
      throw Exception('Failed to update status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateRetryCount(String localId, int retryCount) async {
    try {
      final item = await getById(localId);
      if (item != null) {
        final updatedItem = item.copyWith(
          retryCount: retryCount,
          lastModifiedAt: DateTime.now(),
        );
        await save(updatedItem);
      }
    } catch (e) {
      throw Exception('Failed to update retry count: ${e.toString()}');
    }
  }
}