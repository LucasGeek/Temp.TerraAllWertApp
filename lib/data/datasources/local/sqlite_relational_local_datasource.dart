import '../../../infra/storage/sqlite_adapter.dart';

abstract class SQLiteRelationalLocalDataSource {
  // Sync Relationships
  Future<void> saveSyncRelationship({
    required String id,
    required String entityType,
    required String localId,
    String? remoteId,
    String? parentLocalId,
    String? parentRemoteId,
    required String relationshipType,
  });
  
  Future<List<Map<String, dynamic>>> getSyncRelationships({
    String? entityType,
    String? localId,
    String? parentLocalId,
    String? relationshipType,
  });
  
  Future<void> deleteSyncRelationship(String id);
  
  // Entity Versions
  Future<void> saveEntityVersion({
    required String id,
    required String entityType,
    required String entityId,
    required int versionNumber,
    required String dataHash,
  });
  
  Future<List<Map<String, dynamic>>> getEntityVersions({
    required String entityType,
    required String entityId,
    int? limit,
  });
  
  Future<Map<String, dynamic>?> getLatestEntityVersion({
    required String entityType,
    required String entityId,
  });
  
  // Sync Conflicts
  Future<void> saveSyncConflict({
    required String id,
    required String entityType,
    required String entityId,
    required int localVersion,
    required int remoteVersion,
    required String localData,
    required String remoteData,
    required String conflictType,
    String status = 'pending',
  });
  
  Future<List<Map<String, dynamic>>> getSyncConflicts({
    String? entityType,
    String? entityId,
    String? status,
  });
  
  Future<void> updateConflictStatus({
    required String id,
    required String status,
    String? resolutionStrategy,
  });
  
  // File Relationships
  Future<void> saveFileRelationship({
    required String id,
    required String fileId,
    required String entityType,
    required String entityId,
    required String fieldName,
    required String fileType,
    int? fileSize,
    String? localPath,
    String downloadStatus = 'pending',
  });
  
  Future<List<Map<String, dynamic>>> getFileRelationships({
    String? entityType,
    String? entityId,
    String? downloadStatus,
  });
  
  Future<void> updateFileDownloadStatus({
    required String id,
    required String downloadStatus,
    String? localPath,
  });
  
  // General operations
  Future<void> clearAll();
  Future<void> close();
}

class SQLiteRelationalLocalDataSourceImpl implements SQLiteRelationalLocalDataSource {
  final SQLiteAdapter _sqliteAdapter;
  
  SQLiteRelationalLocalDataSourceImpl(this._sqliteAdapter);
  
  @override
  Future<void> saveSyncRelationship({
    required String id,
    required String entityType,
    required String localId,
    String? remoteId,
    String? parentLocalId,
    String? parentRemoteId,
    required String relationshipType,
  }) async {
    try {
      await _sqliteAdapter.saveSyncRelationship(
        id: id,
        entityType: entityType,
        localId: localId,
        remoteId: remoteId,
        parentLocalId: parentLocalId,
        parentRemoteId: parentRemoteId,
        relationshipType: relationshipType,
      );
    } catch (e) {
      throw Exception('Failed to save sync relationship: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getSyncRelationships({
    String? entityType,
    String? localId,
    String? parentLocalId,
    String? relationshipType,
  }) async {
    try {
      return await _sqliteAdapter.getSyncRelationships(
        entityType: entityType,
        localId: localId,
        parentLocalId: parentLocalId,
        relationshipType: relationshipType,
      );
    } catch (e) {
      throw Exception('Failed to get sync relationships: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteSyncRelationship(String id) async {
    try {
      await _sqliteAdapter.deleteSyncRelationship(id);
    } catch (e) {
      throw Exception('Failed to delete sync relationship: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveEntityVersion({
    required String id,
    required String entityType,
    required String entityId,
    required int versionNumber,
    required String dataHash,
  }) async {
    try {
      await _sqliteAdapter.saveEntityVersion(
        id: id,
        entityType: entityType,
        entityId: entityId,
        versionNumber: versionNumber,
        dataHash: dataHash,
      );
    } catch (e) {
      throw Exception('Failed to save entity version: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getEntityVersions({
    required String entityType,
    required String entityId,
    int? limit,
  }) async {
    try {
      return await _sqliteAdapter.getEntityVersions(
        entityType: entityType,
        entityId: entityId,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get entity versions: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getLatestEntityVersion({
    required String entityType,
    required String entityId,
  }) async {
    try {
      return await _sqliteAdapter.getLatestEntityVersion(
        entityType: entityType,
        entityId: entityId,
      );
    } catch (e) {
      throw Exception('Failed to get latest entity version: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveSyncConflict({
    required String id,
    required String entityType,
    required String entityId,
    required int localVersion,
    required int remoteVersion,
    required String localData,
    required String remoteData,
    required String conflictType,
    String status = 'pending',
  }) async {
    try {
      await _sqliteAdapter.saveSyncConflict(
        id: id,
        entityType: entityType,
        entityId: entityId,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
        localData: localData,
        remoteData: remoteData,
        conflictType: conflictType,
        status: status,
      );
    } catch (e) {
      throw Exception('Failed to save sync conflict: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getSyncConflicts({
    String? entityType,
    String? entityId,
    String? status,
  }) async {
    try {
      return await _sqliteAdapter.getSyncConflicts(
        entityType: entityType,
        entityId: entityId,
        status: status,
      );
    } catch (e) {
      throw Exception('Failed to get sync conflicts: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateConflictStatus({
    required String id,
    required String status,
    String? resolutionStrategy,
  }) async {
    try {
      await _sqliteAdapter.updateConflictStatus(
        id: id,
        status: status,
        resolutionStrategy: resolutionStrategy,
      );
    } catch (e) {
      throw Exception('Failed to update conflict status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveFileRelationship({
    required String id,
    required String fileId,
    required String entityType,
    required String entityId,
    required String fieldName,
    required String fileType,
    int? fileSize,
    String? localPath,
    String downloadStatus = 'pending',
  }) async {
    try {
      await _sqliteAdapter.saveFileRelationship(
        id: id,
        fileId: fileId,
        entityType: entityType,
        entityId: entityId,
        fieldName: fieldName,
        fileType: fileType,
        fileSize: fileSize,
        localPath: localPath,
        downloadStatus: downloadStatus,
      );
    } catch (e) {
      throw Exception('Failed to save file relationship: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getFileRelationships({
    String? entityType,
    String? entityId,
    String? downloadStatus,
  }) async {
    try {
      return await _sqliteAdapter.getFileRelationships(
        entityType: entityType,
        entityId: entityId,
        downloadStatus: downloadStatus,
      );
    } catch (e) {
      throw Exception('Failed to get file relationships: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateFileDownloadStatus({
    required String id,
    required String downloadStatus,
    String? localPath,
  }) async {
    try {
      await _sqliteAdapter.updateFileDownloadStatus(
        id: id,
        downloadStatus: downloadStatus,
        localPath: localPath,
      );
    } catch (e) {
      throw Exception('Failed to update file download status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearAll() async {
    try {
      await _sqliteAdapter.clearAllTables();
    } catch (e) {
      throw Exception('Failed to clear all tables: ${e.toString()}');
    }
  }
  
  @override
  Future<void> close() async {
    try {
      await _sqliteAdapter.close();
    } catch (e) {
      throw Exception('Failed to close SQLite connection: ${e.toString()}');
    }
  }
}