import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/local/user_preferences_local_datasource.dart';
import '../datasources/remote/user_preferences_remote_datasource.dart';
import '../models/user_preferences_dto.dart';
import 'package:uuid/uuid.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final UserPreferencesLocalDataSource _localDataSource;
  final UserPreferencesRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  UserPreferencesRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<UserPreferences> create(UserPreferences preferences) async {
    try {
      final localPreferences = preferences.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localPreferences);
      
      try {
        final dto = localPreferences.toDto();
        final remoteDto = await _remoteDataSource.create(dto);
        
        final syncedPreferences = localPreferences.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        
        await _localDataSource.save(syncedPreferences);
        return syncedPreferences;
      } catch (e) {
        return localPreferences;
      }
    } catch (e) {
      throw Exception('Failed to create user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferences> update(UserPreferences preferences) async {
    try {
      final updatedPreferences = preferences.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedPreferences);
      
      if (preferences.remoteId != null) {
        try {
          final dto = updatedPreferences.toDto();
          await _remoteDataSource.update(preferences.remoteId!, dto);
          
          final syncedPreferences = updatedPreferences.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.save(syncedPreferences);
          return syncedPreferences;
        } catch (e) {
          return updatedPreferences;
        }
      }
      
      return updatedPreferences;
    } catch (e) {
      throw Exception('Failed to update user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final preferences = await _localDataSource.getById(localId);
      if (preferences == null) return;
      
      final deletedPreferences = preferences.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(deletedPreferences);
      
      if (preferences.remoteId != null) {
        try {
          await _remoteDataSource.delete(preferences.remoteId!);
          await _localDataSource.delete(localId);
        } catch (e) {
          // Keep soft delete for later sync
        }
      }
    } catch (e) {
      throw Exception('Failed to delete user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferences?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get user preferences by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<UserPreferences>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<UserPreferences?> getByUserId(String userLocalId) async {
    try {
      return await _localDataSource.getByUserId(userLocalId);
    } catch (e) {
      throw Exception('Failed to get user preferences by user id: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getCurrentUserPreferences() async {
    try {
      // This would get current user from auth context
      // For now, get the first available preferences
      final allPreferences = await _localDataSource.getAll();
      if (allPreferences.isNotEmpty) {
        return allPreferences.first.preferences ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }
  
  @override
  Future<T?> getPreference<T>(String key, T defaultValue) async {
    try {
      final currentPrefs = await getCurrentUserPreferences();
      if (currentPrefs.containsKey(key)) {
        final value = currentPrefs[key];
        if (value is T) {
          return value;
        }
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      final remoteDtos = await _remoteDataSource.getAll();
      final localPreferences = <UserPreferences>[];
      
      for (final dto in remoteDtos) {
        final localPref = dto.toEntity(_uuid.v7());
        localPreferences.add(localPref);
      }
      
      await _localDataSource.saveAll(localPreferences);
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote() async {
    try {
      final modifiedPreferences = await _localDataSource.getModified();
      
      for (final preferences in modifiedPreferences) {
        try {
          final dto = preferences.toDto();
          
          if (preferences.remoteId == null) {
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(preferences.localId, remoteDto.id);
          } else {
            await _remoteDataSource.update(preferences.remoteId!, dto);
            await _localDataSource.updateSyncStatus(preferences.localId, preferences.remoteId!);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to sync to remote: ${e.toString()}');
    }
  }
  
  @override
  Future<List<UserPreferences>> getModified() async {
    try {
      return await _localDataSource.getModified();
    } catch (e) {
      throw Exception('Failed to get modified preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setPreference(String key, dynamic value) async {
    try {
      final currentPrefs = await getCurrentUserPreferences();
      currentPrefs[key] = value;
      
      // Get or create user preferences
      final allPrefs = await _localDataSource.getAll();
      UserPreferences preferences;
      
      if (allPrefs.isNotEmpty) {
        preferences = allPrefs.first.copyWith(
          preferences: currentPrefs,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
      } else {
        preferences = UserPreferences(
          localId: _uuid.v7(),
          userLocalId: 'current', // This should be from auth context
          preferences: currentPrefs,
          isModified: true,
          createdAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        );
      }
      
      await _localDataSource.save(preferences);
    } catch (e) {
      throw Exception('Failed to set preference: ${e.toString()}');
    }
  }
  
  @override
  Future<void> removePreference(String key) async {
    try {
      final currentPrefs = await getCurrentUserPreferences();
      currentPrefs.remove(key);
      
      final allPrefs = await _localDataSource.getAll();
      if (allPrefs.isNotEmpty) {
        final preferences = allPrefs.first.copyWith(
          preferences: currentPrefs,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(preferences);
      }
    } catch (e) {
      throw Exception('Failed to remove preference: ${e.toString()}');
    }
  }
  
  @override
  Future<void> resetToDefaults() async {
    try {
      final defaultPreferences = <String, dynamic>{
        'theme': 'light',
        'language': 'pt_BR',
        'notifications': true,
        'autoSync': true,
        'cacheEnabled': true,
      };
      
      final allPrefs = await _localDataSource.getAll();
      UserPreferences preferences;
      
      if (allPrefs.isNotEmpty) {
        preferences = allPrefs.first.copyWith(
          preferences: defaultPreferences,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
      } else {
        preferences = UserPreferences(
          localId: _uuid.v7(),
          userLocalId: 'current',
          preferences: defaultPreferences,
          isModified: true,
          createdAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        );
      }
      
      await _localDataSource.save(preferences);
    } catch (e) {
      throw Exception('Failed to reset to defaults: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> exportPreferences() async {
    try {
      return await getCurrentUserPreferences();
    } catch (e) {
      return {};
    }
  }
  
  @override
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    try {
      final allPrefs = await _localDataSource.getAll();
      UserPreferences userPrefs;
      
      if (allPrefs.isNotEmpty) {
        userPrefs = allPrefs.first.copyWith(
          preferences: preferences,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
      } else {
        userPrefs = UserPreferences(
          localId: _uuid.v7(),
          userLocalId: 'current',
          preferences: preferences,
          isModified: true,
          createdAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        );
      }
      
      await _localDataSource.save(userPrefs);
    } catch (e) {
      throw Exception('Failed to import preferences: ${e.toString()}');
    }
  }
}