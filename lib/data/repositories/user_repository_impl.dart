import 'dart:async';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource.dart';
import '../datasources/remote/user_remote_datasource.dart';
import '../models/user_dto.dart';
import 'package:uuid/uuid.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  UserRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
    Future<List<User>> getAll() async {
    try {
      final remoteDtos = await _remoteDataSource.getAll();
      final users = remoteDtos.map((dto) => dto.toEntity(_uuid.v7())).toList();
      
      await _localDataSource.saveAll(users);
      return users;
    } catch (e) {
      final localUsers = await _localDataSource.getAll();
      if (localUsers.isNotEmpty) {
        return localUsers;
      }
      throw Exception('No data available offline: ${e.toString()}');
    }
  }
  
    Future<User?> getById(String id) async {
    try {
      final dto = await _remoteDataSource.getById(id);
      final user = dto.toEntity(_uuid.v7());
      
      await _localDataSource.save(user);
      return user;
    } catch (e) {
      return await _localDataSource.getById(id);
    }
  }
  
    Future<User?> getByEmail(String email) async {
    try {
      final dto = await _remoteDataSource.getByEmail(email);
      final user = dto.toEntity(_uuid.v7());
      
      await _localDataSource.save(user);
      return user;
    } catch (e) {
      return await _localDataSource.getByEmail(email);
    }
  }
  
    Future<User> create(User user) async {
    try {
      final localId = _uuid.v7();
      final localUser = user.copyWith(
        localId: localId,
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localUser);
      
      final dto = localUser.toDto();
      final remoteDto = await _remoteDataSource.create(dto);
      
      final syncedUser = remoteDto.toEntity(localId);
      await _localDataSource.save(syncedUser.copyWith(isModified: false));
      
      return syncedUser;
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }
  
    Future<User> update(User user) async {
    final updatedUser = user.copyWith(
      isModified: true,
      lastModifiedAt: DateTime.now(),
      syncVersion: user.syncVersion + 1,
    );

    try {
      await _localDataSource.save(updatedUser);
      
      if (user.remoteId != null) {
        final dto = updatedUser.toDto();
        final remoteDto = await _remoteDataSource.update(user.remoteId!, dto);
        
        final syncedUser = remoteDto.toEntity(user.localId);
        await _localDataSource.save(syncedUser.copyWith(isModified: false));
        
        return syncedUser;
      }
      
      return updatedUser;
    } catch (e) {
      return updatedUser;
    }
  }
  
    Future<void> delete(String id) async {
    try {
      await _remoteDataSource.delete(id);
      await _localDataSource.delete(id);
    } catch (e) {
      final user = await _localDataSource.getById(id);
      if (user != null) {
        await _localDataSource.save(user.copyWith(
          deletedAt: DateTime.now(),
          isModified: true,
        ));
      }
    }
  }
  
    Future<List<User>> getAllLocal() async {
    return await _localDataSource.getAll();
  }
  
    Future<User?> getByIdLocal(String localId) async {
    return await _localDataSource.getById(localId);
  }
  
    Future<void> saveLocal(User user) async {
    await _localDataSource.save(user);
  }
  
    Future<void> saveAllLocal(List<User> users) async {
    await _localDataSource.saveAll(users);
  }
  
    Future<void> deleteLocal(String localId) async {
    await _localDataSource.delete(localId);
  }
  
    Future<void> clearLocal() async {
    await _localDataSource.clear();
  }
  
    Future<void> syncWithRemote() async {
    try {
      final modifiedUsers = await _localDataSource.getModified();
      for (final user in modifiedUsers) {
        if (user.remoteId == null) {
          try {
            final dto = user.toDto();
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(user.localId, remoteDto.id);
          } catch (e) {
            continue;
          }
        } else {
          try {
            final dto = user.toDto();
            await _remoteDataSource.update(user.remoteId!, dto);
            await _localDataSource.updateSyncStatus(user.localId, user.remoteId!);
          } catch (e) {
            continue;
          }
        }
      }
      
      final remoteUsers = await _remoteDataSource.getAll();
      final localUsers = await _localDataSource.getAll();
      
      for (final remoteDto in remoteUsers) {
        final existingLocal = localUsers
            .where((u) => u.remoteId == remoteDto.id)
            .firstOrNull;
            
        if (existingLocal == null) {
          final newLocal = remoteDto.toEntity(_uuid.v7());
          await _localDataSource.save(newLocal);
        } else if (!existingLocal.isModified) {
          final updatedLocal = remoteDto.toEntity(existingLocal.localId);
          await _localDataSource.save(updatedLocal);
        }
      }
    } catch (e) {
      throw Exception('Sync failed: ${e.toString()}');
    }
  }
  
    Future<bool> hasLocalChanges() async {
    final modified = await _localDataSource.getModified();
    return modified.isNotEmpty;
  }
  
    Stream<List<User>> watchAll() async* {
    yield await getAllLocal();
  }

  // ===== Authentication Methods =====

  @override
  Future<User> login(String email, String password) async {
    try {
      final authResponse = await _remoteDataSource.login(email, password);
      final user = authResponse.user.toEntity(_uuid.v7());
      
      // Save tokens and user locally
      await _localDataSource.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );
      await _localDataSource.saveCurrentUser(user);
      
      return user;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<User> refreshToken(String refreshToken) async {
    try {
      final authResponse = await _remoteDataSource.refreshToken(refreshToken);
      final user = authResponse.user.toEntity(_uuid.v7());
      
      // Update tokens and user locally
      await _localDataSource.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );
      await _localDataSource.saveCurrentUser(user);
      
      return user;
    } catch (e) {
      throw Exception('Token refresh failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Try remote logout first (may fail if offline)
      try {
        await _remoteDataSource.logout();
      } catch (e) {
        // Continue with local cleanup even if remote logout fails
      }
      
      // Clear local data
      await Future.wait([
        _localDataSource.clearTokens(),
        _localDataSource.clearCurrentUser(),
      ]);
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Try to get current user from local storage first
      final localUser = await _localDataSource.getCurrentUser();
      
      // If we have a local user and we're authenticated, return it
      if (localUser != null) {
        final isAuth = await isAuthenticated();
        if (isAuth) {
          return localUser;
        }
      }
      
      // If no local user or not authenticated, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    try {
      final updatedUser = user.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
        syncVersion: user.syncVersion + 1,
      );

      // Save locally first
      await _localDataSource.saveCurrentUser(updatedUser);
      
      // Try to sync with remote
      if (user.remoteId != null) {
        try {
          final dto = updatedUser.toDto();
          final remoteDto = await _remoteDataSource.update(user.remoteId!, dto);
          
          final syncedUser = remoteDto.toEntity(user.localId);
          await _localDataSource.saveCurrentUser(syncedUser.copyWith(isModified: false));
          
          return syncedUser;
        } catch (e) {
          // Return local version if remote update fails
          return updatedUser;
        }
      }
      
      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAvatar(String avatarUrl) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      // Update locally first
      final updatedUser = currentUser.copyWith(
        avatarUrl: avatarUrl,
        isModified: true,
        lastModifiedAt: DateTime.now(),
        syncVersion: currentUser.syncVersion + 1,
      );
      await _localDataSource.saveCurrentUser(updatedUser);

      // Try to update remote
      if (currentUser.remoteId != null) {
        try {
          await _remoteDataSource.updateAvatar(currentUser.remoteId!, avatarUrl);
          
          // Mark as synced if remote update succeeds
          final syncedUser = updatedUser.copyWith(isModified: false);
          await _localDataSource.saveCurrentUser(syncedUser);
        } catch (e) {
          // Continue with local update even if remote fails
        }
      }
    } catch (e) {
      throw Exception('Failed to update avatar: ${e.toString()}');
    }
  }

  // ===== Local User Methods =====

  @override
  Future<User?> getCurrentUserLocal() async {
    try {
      return await _localDataSource.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveUserLocal(User user) async {
    try {
      await _localDataSource.saveCurrentUser(user);
    } catch (e) {
      throw Exception('Failed to save user locally: ${e.toString()}');
    }
  }

  @override
  Future<void> clearUserLocal() async {
    try {
      await _localDataSource.clearCurrentUser();
    } catch (e) {
      throw Exception('Failed to clear local user: ${e.toString()}');
    }
  }

  // ===== Token Management Methods =====

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _localDataSource.getAccessToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _localDataSource.getRefreshToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await _localDataSource.saveTokens(accessToken, refreshToken);
    } catch (e) {
      throw Exception('Failed to save tokens: ${e.toString()}');
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _localDataSource.clearTokens();
    } catch (e) {
      throw Exception('Failed to clear tokens: ${e.toString()}');
    }
  }

  // ===== Session Management Methods =====

  @override
  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await _localDataSource.getAccessToken();
      final currentUser = await _localDataSource.getCurrentUser();
      
      return accessToken != null && currentUser != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<User?> watchCurrentUser() async* {
    // Start with current user
    yield await getCurrentUserLocal();
    
    // Create a stream controller for user changes
    final StreamController<User?> controller = StreamController<User?>();
    
    // You could implement a more sophisticated watch mechanism here
    // For now, we'll return the initial value and close the stream
    controller.add(await getCurrentUserLocal());
    
    yield* controller.stream;
    
    // Clean up
    controller.close();
  }
}