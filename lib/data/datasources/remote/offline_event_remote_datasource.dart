import '../../../infra/http/rest_client.dart';
import '../../models/offline_event_dto.dart';

abstract class OfflineEventRemoteDataSource {
  Future<List<OfflineEventDto>> getAll();
  Future<List<OfflineEventDto>> getBySessionId(String sessionId);
  Future<OfflineEventDto> getById(String id);
  Future<OfflineEventDto> create(OfflineEventDto event);
  Future<OfflineEventDto> update(String id, OfflineEventDto event);
  Future<void> delete(String id);
  Future<List<OfflineEventDto>> bulkCreate(List<OfflineEventDto> events);
  Future<void> markAsProcessed(String id);
}

class OfflineEventRemoteDataSourceImpl implements OfflineEventRemoteDataSource {
  final RestClient _client;
  
  OfflineEventRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<OfflineEventDto>> getAll() async {
    try {
      final response = await _client.get('/offline-events');
      final List<dynamic> data = response.data;
      return data.map((json) => OfflineEventDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get offline events: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEventDto>> getBySessionId(String sessionId) async {
    try {
      final response = await _client.get('/offline-events/session/$sessionId');
      final List<dynamic> data = response.data;
      return data.map((json) => OfflineEventDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get offline events by session: ${e.toString()}');
    }
  }
  
  @override
  Future<OfflineEventDto> getById(String id) async {
    try {
      final response = await _client.get('/offline-events/$id');
      return OfflineEventDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<OfflineEventDto> create(OfflineEventDto event) async {
    try {
      final response = await _client.post(
        '/offline-events',
        data: event.toJson(),
      );
      return OfflineEventDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<OfflineEventDto> update(String id, OfflineEventDto event) async {
    try {
      final response = await _client.put(
        '/offline-events/$id',
        data: event.toJson(),
      );
      return OfflineEventDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/offline-events/$id');
    } catch (e) {
      throw Exception('Failed to delete offline event: ${e.toString()}');
    }
  }
  
  @override
  Future<List<OfflineEventDto>> bulkCreate(List<OfflineEventDto> events) async {
    try {
      final response = await _client.post(
        '/offline-events/bulk',
        data: {'events': events.map((e) => e.toJson()).toList()},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => OfflineEventDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to bulk create offline events: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsProcessed(String id) async {
    try {
      await _client.put(
        '/offline-events/$id/processed',
        data: {'processedAt': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      throw Exception('Failed to mark offline event as processed: ${e.toString()}');
    }
  }
}