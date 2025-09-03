import '../../../infra/http/rest_client.dart';
import '../../models/data_version_dto.dart';

abstract class DataVersionRemoteDataSource {
  Future<List<DataVersionDto>> getAll();
  Future<DataVersionDto> getById(String id);
  Future<List<DataVersionDto>> getOutdated();
  Future<List<DataVersionDto>> getByEntityType(String entityType);
  Future<DataVersionDto?> getLatestByEntityType(String entityType);
  Future<DataVersionDto> create(DataVersionDto dataVersion);
  Future<DataVersionDto> update(String id, DataVersionDto dataVersion);
  Future<void> delete(String id);
  Future<void> markAsLatest(String id);
  Future<void> incrementVersion(String entityType);
}

class DataVersionRemoteDataSourceImpl implements DataVersionRemoteDataSource {
  final RestClient _client;
  
  DataVersionRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<DataVersionDto>> getAll() async {
    try {
      final response = await _client.get('/data-versions');
      final List<dynamic> data = response.data;
      return data.map((json) => DataVersionDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get data versions: ${e.toString()}');
    }
  }
  
  @override
  Future<DataVersionDto> getById(String id) async {
    try {
      final response = await _client.get('/data-versions/$id');
      return DataVersionDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get data version: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DataVersionDto>> getOutdated() async {
    try {
      final response = await _client.get('/data-versions/outdated');
      final List<dynamic> data = response.data;
      return data.map((json) => DataVersionDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get outdated versions: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DataVersionDto>> getByEntityType(String entityType) async {
    try {
      final response = await _client.get('/data-versions/entity-type/$entityType');
      final List<dynamic> data = response.data;
      return data.map((json) => DataVersionDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get versions by entity type: ${e.toString()}');
    }
  }
  
  @override
  Future<DataVersionDto?> getLatestByEntityType(String entityType) async {
    try {
      final response = await _client.get('/data-versions/latest/$entityType');
      return DataVersionDto.fromJson(response.data);
    } catch (e) {
      // Return null if not found (404)
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Failed to get latest version: ${e.toString()}');
    }
  }
  
  @override
  Future<DataVersionDto> create(DataVersionDto dataVersion) async {
    try {
      final response = await _client.post(
        '/data-versions',
        data: dataVersion.toJson(),
      );
      return DataVersionDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create data version: ${e.toString()}');
    }
  }
  
  @override
  Future<DataVersionDto> update(String id, DataVersionDto dataVersion) async {
    try {
      final response = await _client.put(
        '/data-versions/$id',
        data: dataVersion.toJson(),
      );
      return DataVersionDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update data version: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/data-versions/$id');
    } catch (e) {
      throw Exception('Failed to delete data version: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsLatest(String id) async {
    try {
      await _client.put('/data-versions/$id/mark-latest');
    } catch (e) {
      throw Exception('Failed to mark as latest: ${e.toString()}');
    }
  }
  
  @override
  Future<void> incrementVersion(String entityType) async {
    try {
      await _client.post('/data-versions/increment/$entityType');
    } catch (e) {
      throw Exception('Failed to increment version: ${e.toString()}');
    }
  }
}