import '../../domain/entities/sync_metadata.dart';
import '../../domain/repositories/sync_metadata_repository.dart';
import '../datasources/local/sync_metadata_local_datasource.dart';
import '../datasources/remote/sync_metadata_remote_datasource.dart';
import '../models/sync_metadata_dto.dart';
import 'package:uuid/uuid.dart';

class SyncMetadataRepositoryImpl implements SyncMetadataRepository {
  final SyncMetadataLocalDataSource _localDataSource;
  final SyncMetadataRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  SyncMetadataRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<SyncMetadata> create(SyncMetadata metadata) async {
    try {
      final localMetadata = metadata.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localMetadata);
      
      try {
        final dto = localMetadata.toDto();
        final remoteDto = await _remoteDataSource.create(dto);
        
        final syncedMetadata = localMetadata.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        
        await _localDataSource.save(syncedMetadata);
        return syncedMetadata;
      } catch (e) {
        return localMetadata;
      }
    } catch (e) {
      throw Exception('Failed to create sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncMetadata> update(SyncMetadata metadata) async {
    try {
      final updatedMetadata = metadata.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedMetadata);
      
      if (metadata.remoteId != null) {
        try {
          final dto = updatedMetadata.toDto();
          await _remoteDataSource.update(metadata.remoteId!, dto);
          
          final syncedMetadata = updatedMetadata.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.save(syncedMetadata);
          return syncedMetadata;
        } catch (e) {
          return updatedMetadata;
        }
      }
      
      return updatedMetadata;
    } catch (e) {
      throw Exception('Failed to update sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final metadata = await _localDataSource.getById(localId);
      if (metadata == null) return;
      
      final deletedMetadata = metadata.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(deletedMetadata);
      
      if (metadata.remoteId != null) {
        try {
          await _remoteDataSource.delete(metadata.remoteId!);
          await _localDataSource.delete(localId);
        } catch (e) {
          // Keep soft delete for later sync
        }
      }
    } catch (e) {
      throw Exception('Failed to delete sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncMetadata?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get sync metadata by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadata>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<SyncMetadata?> getByEntity(String entityType, String entityLocalId) async {
    try {
      return await _localDataSource.getByEntity(entityType, entityLocalId);
    } catch (e) {
      throw Exception('Failed to get sync metadata by entity: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadata>> getByEntityType(String entityType) async {
    try {
      return await _localDataSource.getByEntityType(entityType);
    } catch (e) {
      throw Exception('Failed to get sync metadata by entity type: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadata>> getOutdated() async {
    try {
      return await _localDataSource.getOutdated();
    } catch (e) {
      throw Exception('Failed to get outdated sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SyncMetadata>> getNeedingSync() async {
    try {
      return await _localDataSource.getNeedingSync();
    } catch (e) {
      throw Exception('Failed to get sync metadata needing sync: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      final remoteDtos = await _remoteDataSource.getAll();
      final localMetadata = <SyncMetadata>[];
      
      for (final dto in remoteDtos) {
        final localMeta = dto.toEntity(_uuid.v7());
        localMetadata.add(localMeta);
      }
      
      await _localDataSource.saveAll(localMetadata);
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote() async {
    try {
      final modifiedMetadata = await _localDataSource.getModified();
      
      for (final metadata in modifiedMetadata) {
        try {
          final dto = metadata.toDto();
          
          if (metadata.remoteId == null) {
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(metadata.localId, remoteDto.id);
          } else {
            await _remoteDataSource.update(metadata.remoteId!, dto);
            await _localDataSource.updateSyncStatus(metadata.localId, metadata.remoteId!);
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
  Future<List<SyncMetadata>> getModified() async {
    try {
      return await _localDataSource.getModified();
    } catch (e) {
      throw Exception('Failed to get modified sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local sync metadata: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateVersion(String localId, int version) async {
    try {
      final metadata = await _localDataSource.getById(localId);
      if (metadata != null) {
        final updatedMetadata = metadata.copyWith(
          version: version,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(updatedMetadata);
      }
    } catch (e) {
      throw Exception('Failed to update version: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateChecksum(String localId, String checksum) async {
    try {
      final metadata = await _localDataSource.getById(localId);
      if (metadata != null) {
        final updatedMetadata = metadata.copyWith(
          checksum: checksum,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(updatedMetadata);
      }
    } catch (e) {
      throw Exception('Failed to update checksum: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markSynced(String localId) async {
    try {
      final metadata = await _localDataSource.getById(localId);
      if (metadata != null) {
        final syncedMetadata = metadata.copyWith(
          isModified: false,
          lastSyncedAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(syncedMetadata);
      }
    } catch (e) {
      throw Exception('Failed to mark as synced: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> isEntityUpToDate(String entityType, String entityLocalId, int remoteVersion) async {
    try {
      final metadata = await _localDataSource.getByEntity(entityType, entityLocalId);
      if (metadata == null) return false;
      
      return metadata.version >= remoteVersion;
    } catch (e) {
      return false;
    }
  }
}