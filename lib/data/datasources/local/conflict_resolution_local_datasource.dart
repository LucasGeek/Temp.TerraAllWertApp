import '../../../domain/entities/conflict_resolution.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class ConflictResolutionLocalDataSource {
  Future<List<ConflictResolution>> getAll();
  Future<ConflictResolution?> getById(String id);
  Future<List<ConflictResolution>> getPending();
  Future<List<ConflictResolution>> getResolved();
  Future<List<ConflictResolution>> getByEntityType(String entityType);
  Future<List<ConflictResolution>> getByEntityId(String entityLocalId);
  Future<void> save(ConflictResolution conflict);
  Future<void> saveAll(List<ConflictResolution> conflicts);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<ConflictResolution>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
}

class ConflictResolutionLocalDataSourceImpl implements ConflictResolutionLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'conflict_resolutions';
  
  ConflictResolutionLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<ConflictResolution>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => ConflictResolution.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<ConflictResolution?> getById(String id) async {
    try {
      final conflicts = await getAll();
      return conflicts.where((conflict) => conflict.localId == id || conflict.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<ConflictResolution>> getPending() async {
    try {
      final conflicts = await getAll();
      return conflicts.where((conflict) => conflict.resolutionStrategy == null).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<ConflictResolution>> getResolved() async {
    try {
      final conflicts = await getAll();
      return conflicts.where((conflict) => conflict.resolutionStrategy != null).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<ConflictResolution>> getByEntityType(String entityType) async {
    try {
      final conflicts = await getAll();
      return conflicts.where((conflict) => conflict.entityType == entityType).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(ConflictResolution conflict) async {
    try {
      final conflicts = await getAll();
      final index = conflicts.indexWhere((c) => c.localId == conflict.localId);
      
      if (index >= 0) {
        conflicts[index] = conflict;
      } else {
        conflicts.add(conflict);
      }
      
      final jsonList = conflicts.map((conflict) => conflict.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save conflict resolution: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<ConflictResolution> conflicts) async {
    try {
      final jsonList = conflicts.map((conflict) => conflict.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save conflict resolutions: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final conflicts = await getAll();
      conflicts.removeWhere((conflict) => conflict.localId == id || conflict.remoteId == id);
      
      final jsonList = conflicts.map((conflict) => conflict.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete conflict resolution: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear conflict resolutions: ${e.toString()}');
    }
  }
  
  @override
  Future<List<ConflictResolution>> getModified() async {
    try {
      final conflicts = await getAll();
      return conflicts.where((conflict) => conflict.resolvedAt == null).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<ConflictResolution>> getByEntityId(String entityLocalId) async {
    try {
      final conflicts = await getAll();
      return conflicts.where((conflict) => conflict.entityLocalId == entityLocalId).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final conflict = await getById(localId);
      if (conflict != null) {
        final updatedConflict = conflict.copyWith(
          entityRemoteId: remoteId,
          resolvedAt: DateTime.now(),
        );
        await save(updatedConflict);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
}