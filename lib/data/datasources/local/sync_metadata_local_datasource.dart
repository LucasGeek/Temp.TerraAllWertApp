import '../../../domain/entities/sync_metadata.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class SyncMetadataLocalDataSource {
  Future<List<SyncMetadata>> getAll();
  Future<SyncMetadata?> getById(String id);
  Future<SyncMetadata?> getByEntity(String entityType, String entityId);
  Future<List<SyncMetadata>> getByEntityType(String entityType);
  Future<void> save(SyncMetadata metadata);
  Future<void> saveAll(List<SyncMetadata> metadataList);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<SyncMetadata>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
  Future<List<SyncMetadata>> getOutdated();
  Future<List<SyncMetadata>> getNeedingSync();
}

class SyncMetadataLocalDataSourceImpl implements SyncMetadataLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'sync_metadata';
  
  SyncMetadataLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<SyncMetadata>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => SyncMetadata.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<SyncMetadata?> getById(String id) async {
    try {
      final metadataList = await getAll();
      return metadataList.where((metadata) => metadata.localId == id || metadata.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<SyncMetadata?> getByEntity(String entityType, String entityId) async {
    try {
      final metadataList = await getAll();
      return metadataList.where((metadata) => 
        metadata.entityType == entityType && metadata.entityLocalId == entityId
      ).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<SyncMetadata>> getByEntityType(String entityType) async {
    try {
      final metadataList = await getAll();
      return metadataList.where((metadata) => metadata.entityType == entityType).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(SyncMetadata metadata) async {
    try {
      final metadataList = await getAll();
      final index = metadataList.indexWhere((m) => m.localId == metadata.localId);
      
      if (index >= 0) {
        metadataList[index] = metadata;
      } else {
        metadataList.add(metadata);
      }
      
      final jsonList = metadataList.map((metadata) => metadata.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<SyncMetadata> metadataList) async {
    try {
      final jsonList = metadataList.map((metadata) => metadata.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save sync metadata list: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final metadataList = await getAll();
      metadataList.removeWhere((metadata) => metadata.localId == id || metadata.remoteId == id);
      
      final jsonList = metadataList.map((metadata) => metadata.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadata>> getModified() async {
    try {
      final metadataList = await getAll();
      return metadataList.where((metadata) => metadata.isModified).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final metadata = await getById(localId);
      if (metadata != null) {
        final updatedMetadata = metadata.copyWith(
          remoteId: remoteId,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        await save(updatedMetadata);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadata>> getOutdated() async {
    try {
      final metadataList = await getAll();
      final now = DateTime.now();
      const staleThreshold = Duration(hours: 24); // Consider data stale after 24 hours
      
      return metadataList.where((metadata) => 
        metadata.lastSyncedAt == null ||
        now.difference(metadata.lastSyncedAt!).compareTo(staleThreshold) > 0
      ).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SyncMetadata>> getNeedingSync() async {
    try {
      final metadataList = await getAll();
      return metadataList.where((metadata) => 
        metadata.syncStatus == SyncStatus.pending ||
        metadata.syncStatus == SyncStatus.error ||
        metadata.pendingChangesCount > 0
      ).toList();
    } catch (e) {
      return [];
    }
  }
}