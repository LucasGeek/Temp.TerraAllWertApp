import '../entities/conflict_resolution.dart';

abstract class ConflictResolutionRepository {
  // Basic CRUD operations
  Future<ConflictResolution> create(ConflictResolution conflict);
  Future<ConflictResolution> update(ConflictResolution conflict);
  Future<void> delete(String localId);
  Future<ConflictResolution?> getById(String localId);
  Future<List<ConflictResolution>> getAll();
  
  // Business-specific queries
  Future<List<ConflictResolution>> getPending();
  Future<List<ConflictResolution>> getResolved();
  Future<List<ConflictResolution>> getByEntityType(String entityType);
  Future<List<ConflictResolution>> getByEntityId(String entityLocalId);
  Future<ConflictResolution?> getActiveConflictForEntity(String entityType, String entityLocalId);
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<ConflictResolution>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  
  // Conflict resolution operations
  Future<void> resolveWithLocal(String localId);
  Future<void> resolveWithRemote(String localId);
  Future<void> resolveWithMerged(String localId, Map<String, dynamic> mergedData);
  Future<void> markAsResolved(String localId, String resolvedBy);
  Future<int> getPendingConflictCount();
}