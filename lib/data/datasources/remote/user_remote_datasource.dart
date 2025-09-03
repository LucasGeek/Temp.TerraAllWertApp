import '../../../infra/http/rest_client.dart';
import '../../models/user_dto.dart';
import '../../models/auth_response_dto.dart';

abstract class UserRemoteDataSource {
  // Auth operations
  Future<AuthResponseDto> login(String email, String password);
  Future<AuthResponseDto> refreshToken(String refreshToken);
  Future<void> logout();
  
  // User operations
  Future<List<UserDto>> getAll();
  Future<UserDto> getById(String id);
  Future<UserDto> getByEmail(String email);
  Future<UserDto> create(UserDto user);
  Future<UserDto> update(String id, UserDto user);
  Future<void> delete(String id);
  Future<void> updateAvatar(String userId, String avatarUrl);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final RestClient _client;
  
  UserRemoteDataSourceImpl(this._client);
  
  @override
  Future<AuthResponseDto> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to login: ${e.toString()}');
    }
  }
  
  @override
  Future<AuthResponseDto> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );
      return AuthResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to refresh token: ${e.toString()}');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (e) {
      throw Exception('Failed to logout: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    try {
      await _client.patch(
        '/users/$userId/avatar',
        data: {'avatarUrl': avatarUrl},
      );
    } catch (e) {
      throw Exception('Failed to update avatar: ${e.toString()}');
    }
  }
  
  @override
  Future<List<UserDto>> getAll() async {
    try {
      final response = await _client.get('/users');
      final List<dynamic> data = response.data;
      return data.map((json) => UserDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get users: ${e.toString()}');
    }
  }
  
  @override
  Future<UserDto> getById(String id) async {
    try {
      final response = await _client.get('/users/$id');
      return UserDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }
  
  @override
  Future<UserDto> getByEmail(String email) async {
    try {
      final response = await _client.get('/users/by-email/$email');
      return UserDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get user by email: ${e.toString()}');
    }
  }
  
  @override
  Future<UserDto> create(UserDto user) async {
    try {
      final response = await _client.post(
        '/users',
        data: user.toJson(),
      );
      return UserDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }
  
  @override
  Future<UserDto> update(String id, UserDto user) async {
    try {
      final response = await _client.put(
        '/users/$id',
        data: user.toJson(),
      );
      return UserDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/users/$id');
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }
}