import '../../../domain/entities/offline_event.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class OfflineEventLocalDataSource {
  Future<List<OfflineEvent>> getAll();
  Future<OfflineEvent?> getById(String id);
  Future<List<OfflineEvent>> getPending();
  Future<List<OfflineEvent>> getProcessed();
  Future<List<OfflineEvent>> getFailed();
  Future<List<OfflineEvent>> getByEntityType(String entityType);
  Future<List<OfflineEvent>> getBySessionId(String sessionId);
  Future<void> save(OfflineEvent event);
  Future<void> saveAll(List<OfflineEvent> events);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<OfflineEvent>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
  Future<List<OfflineEvent>> getNextBatch(int limit);
  Future<void> clearProcessed();
  Future<void> markAsProcessed(String id);
  Future<void> markAsFailed(String id, String error);
  Future<void> retryFailed();
}

class OfflineEventLocalDataSourceImpl implements OfflineEventLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'offline_events';
  
  OfflineEventLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<OfflineEvent>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => OfflineEvent.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<OfflineEvent?> getById(String id) async {
    try {
      final events = await getAll();
      return events.where((event) => event.localId == id || event.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<OfflineEvent>> getPending() async {
    try {
      final events = await getAll();
      return events.where((event) => !event.isSynced).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<OfflineEvent>> getProcessed() async {
    try {
      final events = await getAll();
      return events.where((event) => event.isSynced).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<OfflineEvent>> getFailed() async {
    try {
      final events = await getAll();
      return events.where((event) => event.syncedAt == null && event.isSynced == false).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<OfflineEvent>> getByEntityType(String entityType) async {
    try {
      final events = await getAll();
      return events.where((event) => event.entityType == entityType).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(OfflineEvent event) async {
    try {
      final events = await getAll();
      final index = events.indexWhere((e) => e.localId == event.localId);
      
      if (index >= 0) {
        events[index] = event;
      } else {
        events.add(event);
      }
      
      final jsonList = events.map((event) => event.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<OfflineEvent> events) async {
    try {
      final jsonList = events.map((event) => event.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save offline events: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final events = await getAll();
      events.removeWhere((event) => event.localId == id || event.remoteId == id);
      
      final jsonList = events.map((event) => event.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear offline events: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getModified() async {
    try {
      // OfflineEvent não tem campo isModified, retornar lista vazia
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final event = await getById(localId);
      if (event != null) {
        final updatedEvent = event.copyWith(
          isSynced: true,
          syncedAt: DateTime.now(),
        );
        await save(updatedEvent);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getNextBatch(int limit) async {
    try {
      final events = await getPending();
      events.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Process oldest first
      return events.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<OfflineEvent>> getBySessionId(String sessionId) async {
    try {
      final events = await getAll();
      return events.where((event) => event.sessionId == sessionId).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> clearProcessed() async {
    try {
      final events = await getAll();
      final notProcessed = events.where((event) => !event.isSynced).toList();
      final jsonList = notProcessed.map((event) => event.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to clear processed events: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsProcessed(String id) async {
    try {
      final event = await getById(id);
      if (event != null) {
        final processed = event.copyWith(isSynced: true, syncedAt: DateTime.now());
        await save(processed);
      }
    } catch (e) {
      throw Exception('Failed to mark as processed: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsFailed(String id, String error) async {
    try {
      final event = await getById(id);
      if (event != null) {
        // Since OfflineEvent doesn't have error field, we add to eventData
        final eventData = Map<String, dynamic>.from(event.eventData ?? {});
        eventData['error'] = error;
        eventData['failed_at'] = DateTime.now().toIso8601String();
        
        final failed = event.copyWith(eventData: eventData);
        await save(failed);
      }
    } catch (e) {
      throw Exception('Failed to mark as failed: ${e.toString()}');
    }
  }

  @override
  Future<void> retryFailed() async {
    try {
      final events = await getAll();
      for (final event in events) {
        final eventData = event.eventData ?? {};
        if (eventData.containsKey('error')) {
          // Remove error fields for retry
          eventData.remove('error');
          eventData.remove('failed_at');
          
          final retried = event.copyWith(
            eventData: eventData.isNotEmpty ? eventData : null,
            isSynced: false,
            syncedAt: null,
          );
          await save(retried);
        }
      }
    } catch (e) {
      throw Exception('Failed to retry failed events: ${e.toString()}');
    }
  }
}