import '../../../infra/http/rest_client.dart';
import '../../models/enterprise_dto.dart';

abstract class EnterpriseRemoteDataSource {
  Future<List<EnterpriseDto>> getAll();
  Future<EnterpriseDto> getById(String id);
  Future<EnterpriseDto> getBySlug(String slug);
  Future<List<EnterpriseDto>> search(String query);
  Future<EnterpriseDto> create(EnterpriseDto enterprise);
  Future<EnterpriseDto> update(String id, EnterpriseDto enterprise);
  Future<void> delete(String id);
}

class EnterpriseRemoteDataSourceImpl implements EnterpriseRemoteDataSource {
  final RestClient _client;
  
  EnterpriseRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<EnterpriseDto>> getAll() async {
    try {
      final response = await _client.get('/enterprises');
      final List<dynamic> data = response.data;
      return data.map((json) => EnterpriseDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get enterprises: ${e.toString()}');
    }
  }
  
  @override
  Future<EnterpriseDto> getById(String id) async {
    try {
      final response = await _client.get('/enterprises/$id');
      return EnterpriseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get enterprise: ${e.toString()}');
    }
  }
  
  @override
  Future<EnterpriseDto> getBySlug(String slug) async {
    try {
      final response = await _client.get('/enterprises/slug/$slug');
      return EnterpriseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get enterprise by slug: ${e.toString()}');
    }
  }
  
  @override
  Future<List<EnterpriseDto>> search(String query) async {
    try {
      final response = await _client.get(
        '/enterprises/search',
        queryParameters: {'q': query},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => EnterpriseDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search enterprises: ${e.toString()}');
    }
  }
  
  @override
  Future<EnterpriseDto> create(EnterpriseDto enterprise) async {
    try {
      final response = await _client.post(
        '/enterprises',
        data: enterprise.toJson(),
      );
      return EnterpriseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create enterprise: ${e.toString()}');
    }
  }
  
  @override
  Future<EnterpriseDto> update(String id, EnterpriseDto enterprise) async {
    try {
      final response = await _client.put(
        '/enterprises/$id',
        data: enterprise.toJson(),
      );
      return EnterpriseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update enterprise: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/enterprises/$id');
    } catch (e) {
      throw Exception('Failed to delete enterprise: ${e.toString()}');
    }
  }
}