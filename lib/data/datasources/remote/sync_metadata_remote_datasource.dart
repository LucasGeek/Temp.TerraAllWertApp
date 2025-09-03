import '../../../infra/http/rest_client.dart';
import '../../models/sync_metadata_dto.dart';

abstract class SyncMetadataRemoteDataSource {
  Future<List<SyncMetadataDto>> getAll();
  Future<List<SyncMetadataDto>> getByEntityType(String entityType);
  Future<SyncMetadataDto> getById(String id);
  Future<SyncMetadataDto> create(SyncMetadataDto metadata);
  Future<SyncMetadataDto> update(String id, SyncMetadataDto metadata);
  Future<void> delete(String id);
  Future<Map<String, int>> getVersions(List<String> entityIds);
  Future<List<SyncMetadataDto>> getUpdatedSince(DateTime lastSync);
}

class SyncMetadataRemoteDataSourceImpl implements SyncMetadataRemoteDataSource {
  final RestClient _client;
  
  SyncMetadataRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<SyncMetadataDto>> getAll() async {
    try {
      final response = await _client.get('/sync-metadata');
      final List<dynamic> data = response.data;
      return data.map((json) => SyncMetadataDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadataDto>> getByEntityType(String entityType) async {
    try {
      final response = await _client.get('/sync-metadata/entity-type/$entityType');
      final List<dynamic> data = response.data;
      return data.map((json) => SyncMetadataDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get sync metadata by entity type: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncMetadataDto> getById(String id) async {
    try {
      final response = await _client.get('/sync-metadata/$id');
      return SyncMetadataDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncMetadataDto> create(SyncMetadataDto metadata) async {
    try {
      final response = await _client.post(
        '/sync-metadata',
        data: metadata.toJson(),
      );
      return SyncMetadataDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncMetadataDto> update(String id, SyncMetadataDto metadata) async {
    try {
      final response = await _client.put(
        '/sync-metadata/$id',
        data: metadata.toJson(),
      );
      return SyncMetadataDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/sync-metadata/$id');
    } catch (e) {
      throw Exception('Failed to delete sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, int>> getVersions(List<String> entityIds) async {
    try {
      final response = await _client.post(
        '/sync-metadata/versions',
        data: {'entityIds': entityIds},
      );
      return Map<String, int>.from(response.data);
    } catch (e) {
      throw Exception('Failed to get versions: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadataDto>> getUpdatedSince(DateTime lastSync) async {
    try {
      final response = await _client.get(
        '/sync-metadata/updated-since',
        queryParameters: {'timestamp': lastSync.toIso8601String()},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => SyncMetadataDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get updated metadata: ${e.toString()}');
    }
  }
}