import '../entities/sync_metadata.dart';

abstract class SyncMetadataRepository {
  // Basic CRUD operations
  Future<SyncMetadata> create(SyncMetadata metadata);
  Future<SyncMetadata> update(SyncMetadata metadata);
  Future<void> delete(String localId);
  Future<SyncMetadata?> getById(String localId);
  Future<List<SyncMetadata>> getAll();
  
  // Business-specific queries
  Future<SyncMetadata?> getByEntity(String entityType, String entityLocalId);
  Future<List<SyncMetadata>> getByEntityType(String entityType);
  Future<List<SyncMetadata>> getOutdated();
  Future<List<SyncMetadata>> getNeedingSync();
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<SyncMetadata>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  
  // Metadata management
  Future<void> updateVersion(String localId, int version);
  Future<void> updateChecksum(String localId, String checksum);
  Future<void> markSynced(String localId);
  Future<bool> isEntityUpToDate(String entityType, String entityLocalId, int remoteVersion);
}