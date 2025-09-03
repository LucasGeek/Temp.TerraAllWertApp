import '../../../infra/http/rest_client.dart';
import '../../models/search_cache_dto.dart';

abstract class SearchCacheRemoteDataSource {
  Future<List<SearchCacheDto>> getAll();
  Future<SearchCacheDto> getById(String id);
  Future<List<SearchCacheDto>> getBySearchType(String searchType);
  Future<SearchCacheDto?> getBySearchHash(String searchHash);
  Future<List<SearchCacheDto>> getActive();
  Future<List<SearchCacheDto>> getExpired();
  Future<SearchCacheDto> create(SearchCacheDto searchCache);
  Future<SearchCacheDto> update(String id, SearchCacheDto searchCache);
  Future<void> delete(String id);
  Future<void> deleteExpired();
  Future<void> updateLastAccessed(String id);
}

class SearchCacheRemoteDataSourceImpl implements SearchCacheRemoteDataSource {
  final RestClient _client;
  
  SearchCacheRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<SearchCacheDto>> getAll() async {
    try {
      final response = await _client.get('/search-cache');
      final List<dynamic> data = response.data;
      return data.map((json) => SearchCacheDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get search cache: ${e.toString()}');
    }
  }
  
  @override
  Future<SearchCacheDto> getById(String id) async {
    try {
      final response = await _client.get('/search-cache/$id');
      return SearchCacheDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get search cache item: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SearchCacheDto>> getBySearchType(String searchType) async {
    try {
      final response = await _client.get('/search-cache/type/$searchType');
      final List<dynamic> data = response.data;
      return data.map((json) => SearchCacheDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get cache by search type: ${e.toString()}');
    }
  }
  
  @override
  Future<SearchCacheDto?> getBySearchHash(String searchHash) async {
    try {
      final response = await _client.get('/search-cache/hash/$searchHash');
      return SearchCacheDto.fromJson(response.data);
    } catch (e) {
      // Return null if not found (404)
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Failed to get cache by hash: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SearchCacheDto>> getActive() async {
    try {
      final response = await _client.get('/search-cache/active');
      final List<dynamic> data = response.data;
      return data.map((json) => SearchCacheDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get active cache: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SearchCacheDto>> getExpired() async {
    try {
      final response = await _client.get('/search-cache/expired');
      final List<dynamic> data = response.data;
      return data.map((json) => SearchCacheDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get expired cache: ${e.toString()}');
    }
  }
  
  @override
  Future<SearchCacheDto> create(SearchCacheDto searchCache) async {
    try {
      final response = await _client.post(
        '/search-cache',
        data: searchCache.toJson(),
      );
      return SearchCacheDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create search cache: ${e.toString()}');
    }
  }
  
  @override
  Future<SearchCacheDto> update(String id, SearchCacheDto searchCache) async {
    try {
      final response = await _client.put(
        '/search-cache/$id',
        data: searchCache.toJson(),
      );
      return SearchCacheDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update search cache: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/search-cache/$id');
    } catch (e) {
      throw Exception('Failed to delete search cache: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteExpired() async {
    try {
      await _client.delete('/search-cache/expired');
    } catch (e) {
      throw Exception('Failed to delete expired cache: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateLastAccessed(String id) async {
    try {
      await _client.put('/search-cache/$id/accessed');
    } catch (e) {
      throw Exception('Failed to update last accessed: ${e.toString()}');
    }
  }
}