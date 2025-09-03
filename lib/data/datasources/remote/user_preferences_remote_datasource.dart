import '../../../infra/http/rest_client.dart';
import '../../models/user_preferences_dto.dart';

abstract class UserPreferencesRemoteDataSource {
  Future<List<UserPreferencesDto>> getAll();
  Future<UserPreferencesDto> getById(String id);
  Future<UserPreferencesDto?> getByUserId(String userId);
  Future<UserPreferencesDto> create(UserPreferencesDto preferences);
  Future<UserPreferencesDto> update(String id, UserPreferencesDto preferences);
  Future<void> delete(String id);
  Future<UserPreferencesDto> updatePreference(String id, String key, dynamic value);
}

class UserPreferencesRemoteDataSourceImpl implements UserPreferencesRemoteDataSource {
  final RestClient _client;
  
  UserPreferencesRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<UserPreferencesDto>> getAll() async {
    try {
      final response = await _client.get('/user-preferences');
      final List<dynamic> data = response.data;
      return data.map((json) => UserPreferencesDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferencesDto> getById(String id) async {
    try {
      final response = await _client.get('/user-preferences/$id');
      return UserPreferencesDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferencesDto?> getByUserId(String userId) async {
    try {
      final response = await _client.get('/user-preferences/user/$userId');
      return UserPreferencesDto.fromJson(response.data);
    } catch (e) {
      // Return null if not found (404) - preferences might not exist yet
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Failed to get user preferences by user: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferencesDto> create(UserPreferencesDto preferences) async {
    try {
      final response = await _client.post(
        '/user-preferences',
        data: preferences.toJson(),
      );
      return UserPreferencesDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferencesDto> update(String id, UserPreferencesDto preferences) async {
    try {
      final response = await _client.put(
        '/user-preferences/$id',
        data: preferences.toJson(),
      );
      return UserPreferencesDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/user-preferences/$id');
    } catch (e) {
      throw Exception('Failed to delete user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferencesDto> updatePreference(String id, String key, dynamic value) async {
    try {
      final response = await _client.patch(
        '/user-preferences/$id/preference',
        data: {
          'key': key,
          'value': value,
        },
      );
      return UserPreferencesDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update preference: ${e.toString()}');
    }
  }
}