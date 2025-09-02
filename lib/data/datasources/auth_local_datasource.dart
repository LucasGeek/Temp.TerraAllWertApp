import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/auth_response.dart';
import '../models/user_dto.dart';

abstract class AuthLocalDataSource {
  Future<void> storeAuthToken(AuthResponse authResponse);
  Future<AuthResponse?> getStoredAuthToken();
  Future<void> clearAuthToken();
  Future<void> storeUser(UserDto user);
  Future<UserDto?> getStoredUser();
  Future<void> clearUser();
  Future<bool> isAuthenticated();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  AuthLocalDataSourceImpl(this._secureStorage);

  static const String _authTokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  @override
  Future<void> storeAuthToken(AuthResponse authResponse) async {
    final jsonString = json.encode(authResponse.toStorageJson());
    await _secureStorage.write(key: _authTokenKey, value: jsonString);
  }

  @override
  Future<AuthResponse?> getStoredAuthToken() async {
    final jsonString = await _secureStorage.read(key: _authTokenKey);
    if (jsonString == null) return null;
    
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AuthResponse.fromJson(jsonMap);
    } catch (e) {
      await clearAuthToken();
      return null;
    }
  }

  @override
  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _authTokenKey);
  }

  @override
  Future<void> storeUser(UserDto user) async {
    final jsonString = json.encode(user.toStorageJson());
    await _secureStorage.write(key: _userKey, value: jsonString);
  }

  @override
  Future<UserDto?> getStoredUser() async {
    final jsonString = await _secureStorage.read(key: _userKey);
    if (jsonString == null) return null;
    
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return UserDto.fromJson(jsonMap);
    } catch (e) {
      await clearUser();
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await _secureStorage.delete(key: _userKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getStoredAuthToken();
    if (token == null) return false;
    
    return DateTime.now().isBefore(token.expiresAt);
  }
}