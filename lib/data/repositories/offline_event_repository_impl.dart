import '../../domain/entities/offline_event.dart';
import '../../domain/repositories/offline_event_repository.dart';
import '../datasources/local/offline_event_local_datasource.dart';
import '../datasources/remote/offline_event_remote_datasource.dart';
import '../models/offline_event_dto.dart';
import 'package:uuid/uuid.dart';

class OfflineEventRepositoryImpl implements OfflineEventRepository {
  final OfflineEventLocalDataSource _localDataSource;
  final OfflineEventRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  OfflineEventRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<OfflineEvent> create(OfflineEvent event) async {
    try {
      final localEvent = event.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localEvent);
      return localEvent;
    } catch (e) {
      throw Exception('Failed to create offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<OfflineEvent> update(OfflineEvent event) async {
    try {
      final updatedEvent = event.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedEvent);
      return updatedEvent;
    } catch (e) {
      throw Exception('Failed to update offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final event = await _localDataSource.getById(localId);
      if (event == null) return;
      
      final deletedEvent = event.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(deletedEvent);
    } catch (e) {
      throw Exception('Failed to delete offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<OfflineEvent?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get offline event by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all offline events: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getPending() async {
    try {
      return await _localDataSource.getPending();
    } catch (e) {
      throw Exception('Failed to get pending events: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getProcessed() async {
    try {
      return await _localDataSource.getProcessed();
    } catch (e) {
      throw Exception('Failed to get processed events: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getFailed() async {
    try {
      return await _localDataSource.getFailed();
    } catch (e) {
      throw Exception('Failed to get failed events: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getByEntityType(String entityType) async {
    try {
      return await _localDataSource.getByEntityType(entityType);
    } catch (e) {
      throw Exception('Failed to get events by entity type: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getBySessionId(String sessionId) async {
    try {
      return await _localDataSource.getBySessionId(sessionId);
    } catch (e) {
      throw Exception('Failed to get events by session id: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      // Offline events are typically created locally and pushed to remote
      // This would pull any server-side events if needed
      final remoteDtos = await _remoteDataSource.getAll();
      final localEvents = <OfflineEvent>[];
      
      for (final dto in remoteDtos) {
        final localEvent = dto.toEntity(_uuid.v7());
        localEvents.add(localEvent);
      }
      
      await _localDataSource.saveAll(localEvents);
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote() async {
    try {
      final modifiedEvents = await _localDataSource.getModified();
      
      for (final event in modifiedEvents) {
        try {
          final dto = event.toDto();
          
          if (event.remoteId == null) {
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(event.localId, remoteDto.id);
          } else {
            await _remoteDataSource.update(event.remoteId!, dto);
            await _localDataSource.updateSyncStatus(event.localId, event.remoteId!);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to sync to remote: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getModified() async {
    try {
      return await _localDataSource.getModified();
    } catch (e) {
      throw Exception('Failed to get modified events: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local events: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local event: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearProcessed() async {
    try {
      await _localDataSource.clearProcessed();
    } catch (e) {
      throw Exception('Failed to clear processed events: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsProcessed(String localId) async {
    try {
      await _localDataSource.markAsProcessed(localId);
    } catch (e) {
      throw Exception('Failed to mark event as processed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsFailed(String localId, String error) async {
    try {
      await _localDataSource.markAsFailed(localId, error);
    } catch (e) {
      throw Exception('Failed to mark event as failed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> retryFailed() async {
    try {
      await _localDataSource.retryFailed();
    } catch (e) {
      throw Exception('Failed to retry failed events: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEvent>> getNextBatch(int limit) async {
    try {
      return await _localDataSource.getNextBatch(limit);
    } catch (e) {
      throw Exception('Failed to get next batch: ${e.toString()}');
    }
  }
}