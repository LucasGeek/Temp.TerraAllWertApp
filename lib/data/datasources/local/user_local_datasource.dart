import '../../../domain/entities/user.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class UserLocalDataSource {
  Future<List<User>> getAll();
  Future<User?> getById(String id);
  Future<User?> getByEmail(String email);
  Future<void> save(User user);
  Future<void> saveAll(List<User> users);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<User>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
  
  // Token management
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clearTokens();
  
  // Current user management
  Future<User?> getCurrentUser();
  Future<void> saveCurrentUser(User user);
  Future<void> clearCurrentUser();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'users';
  
  UserLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<User>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => User.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<User?> getById(String id) async {
    try {
      final users = await getAll();
      return users.where((user) => user.localId == id || user.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<User?> getByEmail(String email) async {
    try {
      final users = await getAll();
      return users.where((user) => user.email == email).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> save(User user) async {
    try {
      final users = await getAll();
      final index = users.indexWhere((u) => u.localId == user.localId);
      
      if (index >= 0) {
        users[index] = user;
      } else {
        users.add(user);
      }
      
      final jsonList = users.map((user) => user.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save user: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<User> users) async {
    try {
      final jsonList = users.map((user) => user.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save users: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final users = await getAll();
      users.removeWhere((user) => user.localId == id || user.remoteId == id);
      
      final jsonList = users.map((user) => user.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear users: ${e.toString()}');
    }
  }
  
  @override
  Future<List<User>> getModified() async {
    try {
      final users = await getAll();
      return users.where((user) => user.isModified && user.deletedAt == null).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final user = await getById(localId);
      if (user != null) {
        final updatedUser = user.copyWith(
          remoteId: remoteId,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        await save(updatedUser);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storage.getSecure(LocalStorageAdapter.keyAccessToken);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.getSecure(LocalStorageAdapter.keyRefreshToken);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await Future.wait([
        _storage.saveSecure(LocalStorageAdapter.keyAccessToken, accessToken),
        _storage.saveSecure(LocalStorageAdapter.keyRefreshToken, refreshToken),
      ]);
    } catch (e) {
      throw Exception('Failed to save tokens: ${e.toString()}');
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.removeSecure(LocalStorageAdapter.keyAccessToken),
        _storage.removeSecure(LocalStorageAdapter.keyRefreshToken),
      ]);
    } catch (e) {
      throw Exception('Failed to clear tokens: ${e.toString()}');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final json = _storage.getJson(LocalStorageAdapter.keyCurrentUser);
      if (json != null) {
        return User.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveCurrentUser(User user) async {
    try {
      await _storage.saveJson(LocalStorageAdapter.keyCurrentUser, user.toJson());
    } catch (e) {
      throw Exception('Failed to save current user: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCurrentUser() async {
    try {
      await _storage.remove(LocalStorageAdapter.keyCurrentUser);
    } catch (e) {
      throw Exception('Failed to clear current user: ${e.toString()}');
    }
  }
}