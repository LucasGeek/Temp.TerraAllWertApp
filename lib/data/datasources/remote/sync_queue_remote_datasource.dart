import '../../../infra/http/rest_client.dart';
import '../../models/sync_queue_dto.dart';

abstract class SyncQueueRemoteDataSource {
  Future<List<SyncQueueDto>> getAll();
  Future<SyncQueueDto> getById(String id);
  Future<List<SyncQueueDto>> getPending();
  Future<List<SyncQueueDto>> getByEntityType(String entityType);
  Future<SyncQueueDto> create(SyncQueueDto syncQueue);
  Future<SyncQueueDto> update(String id, SyncQueueDto syncQueue);
  Future<void> delete(String id);
  Future<void> markAsProcessed(String id);
  Future<void> markAsFailed(String id, String error);
}

class SyncQueueRemoteDataSourceImpl implements SyncQueueRemoteDataSource {
  final RestClient _client;
  
  SyncQueueRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<SyncQueueDto>> getAll() async {
    try {
      final response = await _client.get('/sync-queue');
      final List<dynamic> data = response.data;
      return data.map((json) => SyncQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get sync queue: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncQueueDto> getById(String id) async {
    try {
      final response = await _client.get('/sync-queue/$id');
      return SyncQueueDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get sync queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncQueueDto>> getPending() async {
    try {
      final response = await _client.get('/sync-queue/pending');
      final List<dynamic> data = response.data;
      return data.map((json) => SyncQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pending sync items: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncQueueDto>> getByEntityType(String entityType) async {
    try {
      final response = await _client.get('/sync-queue/entity-type/$entityType');
      final List<dynamic> data = response.data;
      return data.map((json) => SyncQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get sync queue by entity type: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncQueueDto> create(SyncQueueDto syncQueue) async {
    try {
      final response = await _client.post(
        '/sync-queue',
        data: syncQueue.toJson(),
      );
      return SyncQueueDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create sync queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncQueueDto> update(String id, SyncQueueDto syncQueue) async {
    try {
      final response = await _client.put(
        '/sync-queue/$id',
        data: syncQueue.toJson(),
      );
      return SyncQueueDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update sync queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/sync-queue/$id');
    } catch (e) {
      throw Exception('Failed to delete sync queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsProcessed(String id) async {
    try {
      await _client.put('/sync-queue/$id/processed');
    } catch (e) {
      throw Exception('Failed to mark as processed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsFailed(String id, String error) async {
    try {
      await _client.put(
        '/sync-queue/$id/failed',
        data: {'error': error},
      );
    } catch (e) {
      throw Exception('Failed to mark as failed: ${e.toString()}');
    }
  }
}