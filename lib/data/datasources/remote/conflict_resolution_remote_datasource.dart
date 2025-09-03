import '../../../infra/http/rest_client.dart';
import '../../models/conflict_resolution_dto.dart';

abstract class ConflictResolutionRemoteDataSource {
  Future<List<ConflictResolutionDto>> getAll();
  Future<ConflictResolutionDto> getById(String id);
  Future<List<ConflictResolutionDto>> getPending();
  Future<List<ConflictResolutionDto>> getResolved();
  Future<List<ConflictResolutionDto>> getByEntityType(String entityType);
  Future<ConflictResolutionDto> create(ConflictResolutionDto conflict);
  Future<ConflictResolutionDto> update(String id, ConflictResolutionDto conflict);
  Future<void> delete(String id);
  Future<void> resolveWithLocal(String id);
  Future<void> resolveWithRemote(String id);
  Future<void> resolveWithMerged(String id, Map<String, dynamic> mergedData);
}

class ConflictResolutionRemoteDataSourceImpl implements ConflictResolutionRemoteDataSource {
  final RestClient _client;
  
  ConflictResolutionRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<ConflictResolutionDto>> getAll() async {
    try {
      final response = await _client.get('/conflict-resolution');
      final List<dynamic> data = response.data;
      return data.map((json) => ConflictResolutionDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get conflict resolutions: ${e.toString()}');
    }
  }
  
  @override
  Future<ConflictResolutionDto> getById(String id) async {
    try {
      final response = await _client.get('/conflict-resolution/$id');
      return ConflictResolutionDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get conflict resolution: ${e.toString()}');
    }
  }
  
  @override
  Future<List<ConflictResolutionDto>> getPending() async {
    try {
      final response = await _client.get('/conflict-resolution/pending');
      final List<dynamic> data = response.data;
      return data.map((json) => ConflictResolutionDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pending conflicts: ${e.toString()}');
    }
  }
  
  @override
  Future<List<ConflictResolutionDto>> getResolved() async {
    try {
      final response = await _client.get('/conflict-resolution/resolved');
      final List<dynamic> data = response.data;
      return data.map((json) => ConflictResolutionDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get resolved conflicts: ${e.toString()}');
    }
  }
  
  @override
  Future<List<ConflictResolutionDto>> getByEntityType(String entityType) async {
    try {
      final response = await _client.get('/conflict-resolution/entity-type/$entityType');
      final List<dynamic> data = response.data;
      return data.map((json) => ConflictResolutionDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get conflicts by entity type: ${e.toString()}');
    }
  }
  
  @override
  Future<ConflictResolutionDto> create(ConflictResolutionDto conflict) async {
    try {
      final response = await _client.post(
        '/conflict-resolution',
        data: conflict.toJson(),
      );
      return ConflictResolutionDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create conflict resolution: ${e.toString()}');
    }
  }
  
  @override
  Future<ConflictResolutionDto> update(String id, ConflictResolutionDto conflict) async {
    try {
      final response = await _client.put(
        '/conflict-resolution/$id',
        data: conflict.toJson(),
      );
      return ConflictResolutionDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update conflict resolution: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/conflict-resolution/$id');
    } catch (e) {
      throw Exception('Failed to delete conflict resolution: ${e.toString()}');
    }
  }
  
  @override
  Future<void> resolveWithLocal(String id) async {
    try {
      await _client.put('/conflict-resolution/$id/resolve-local');
    } catch (e) {
      throw Exception('Failed to resolve with local: ${e.toString()}');
    }
  }
  
  @override
  Future<void> resolveWithRemote(String id) async {
    try {
      await _client.put('/conflict-resolution/$id/resolve-remote');
    } catch (e) {
      throw Exception('Failed to resolve with remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> resolveWithMerged(String id, Map<String, dynamic> mergedData) async {
    try {
      await _client.put(
        '/conflict-resolution/$id/resolve-merged',
        data: {'mergedData': mergedData},
      );
    } catch (e) {
      throw Exception('Failed to resolve with merged data: ${e.toString()}');
    }
  }
}