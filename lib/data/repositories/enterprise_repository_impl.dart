import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../datasources/local/enterprise_local_datasource.dart';
import '../datasources/remote/enterprise_remote_datasource.dart';
import '../models/enterprise_dto.dart';
import 'package:uuid/uuid.dart';

class EnterpriseRepositoryImpl implements EnterpriseRepository {
  final EnterpriseLocalDataSource _localDataSource;
  final EnterpriseRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  EnterpriseRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  // ===== Remote Operations (Offline-First Pattern) =====
  
  @override
  Future<List<Enterprise>> getAll() async {
    try {
      // Try remote first
      final remoteDtos = await _remoteDataSource.getAll();
      final enterprises = remoteDtos.map((dto) => dto.toEntity(_uuid.v7())).toList();
      
      // Save to local for offline access
      await _localDataSource.saveAll(enterprises);
      
      return enterprises;
    } catch (e) {
      // Fallback to local data
      final localEnterprises = await _localDataSource.getAll();
      if (localEnterprises.isNotEmpty) {
        return localEnterprises;
      }
      throw Exception('No data available offline: ${e.toString()}');
    }
  }
  
  @override
  Future<Enterprise?> getById(String id) async {
    try {
      // Try remote first
      final dto = await _remoteDataSource.getById(id);
      final enterprise = dto.toEntity(_uuid.v7());
      
      // Save to local
      await _localDataSource.save(enterprise);
      
      return enterprise;
    } catch (e) {
      // Fallback to local
      return await _localDataSource.getById(id);
    }
  }
  
  @override
  Future<Enterprise?> getBySlug(String slug) async {
    try {
      // Try remote first
      final dto = await _remoteDataSource.getBySlug(slug);
      final enterprise = dto.toEntity(_uuid.v7());
      
      // Save to local
      await _localDataSource.save(enterprise);
      
      return enterprise;
    } catch (e) {
      // Fallback to local
      return await _localDataSource.getBySlug(slug);
    }
  }
  
  @override
  Future<Enterprise> create(Enterprise enterprise) async {
    try {
      // Create locally first (optimistic UI)
      final localId = _uuid.v7();
      final localEnterprise = enterprise.copyWith(
        localId: localId,
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localEnterprise);
      
      // Try to sync with remote
      final dto = localEnterprise.toDto();
      final remoteDto = await _remoteDataSource.create(dto);
      
      // Update local with remote ID
      final syncedEnterprise = remoteDto.toEntity(localId);
      await _localDataSource.save(syncedEnterprise.copyWith(isModified: false));
      
      return syncedEnterprise;
    } catch (e) {
      // Keep local copy for later sync
      throw Exception('Failed to create enterprise: ${e.toString()}');
    }
  }
  
  @override
  Future<Enterprise> update(Enterprise enterprise) async {
    // Update locally first
    final updatedEnterprise = enterprise.copyWith(
      isModified: true,
      lastModifiedAt: DateTime.now(),
      syncVersion: enterprise.syncVersion + 1,
    );
    
    try {
      await _localDataSource.save(updatedEnterprise);
      
      // Try to sync with remote
      if (enterprise.remoteId != null) {
        final dto = updatedEnterprise.toDto();
        final remoteDto = await _remoteDataSource.update(enterprise.remoteId!, dto);
        
        // Update local with synced version
        final syncedEnterprise = remoteDto.toEntity(enterprise.localId);
        await _localDataSource.save(syncedEnterprise.copyWith(isModified: false));
        
        return syncedEnterprise;
      }
      
      return updatedEnterprise;
    } catch (e) {
      // Keep local changes for later sync
      return updatedEnterprise;
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      // Try remote delete first
      await _remoteDataSource.delete(id);
      
      // Remove from local
      await _localDataSource.delete(id);
    } catch (e) {
      // Mark for deletion (soft delete locally)
      final enterprise = await _localDataSource.getById(id);
      if (enterprise != null) {
        await _localDataSource.save(enterprise.copyWith(
          deletedAt: DateTime.now(),
          isModified: true,
        ));
      }
    }
  }
  
  // ===== Local Operations =====
  
  @override
  Future<List<Enterprise>> getAllLocal() async {
    return await _localDataSource.getAll();
  }
  
  @override
  Future<Enterprise?> getByIdLocal(String localId) async {
    return await _localDataSource.getById(localId);
  }
  
  @override
  Future<void> saveLocal(Enterprise enterprise) async {
    await _localDataSource.save(enterprise);
  }
  
  @override
  Future<void> saveAllLocal(List<Enterprise> enterprises) async {
    await _localDataSource.saveAll(enterprises);
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    await _localDataSource.delete(localId);
  }
  
  @override
  Future<void> clearLocal() async {
    await _localDataSource.clear();
  }
  
  // ===== Sync Operations =====
  
  @override
  Future<void> syncWithRemote() async {
    try {
      // 1. Upload local changes
      final modifiedEnterprises = await _localDataSource.getModified();
      for (final enterprise in modifiedEnterprises) {
        if (enterprise.remoteId == null) {
          // Create new
          try {
            final dto = enterprise.toDto();
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(enterprise.localId, remoteDto.id);
          } catch (e) {
            // Handle conflict or error
            continue;
          }
        } else {
          // Update existing
          try {
            final dto = enterprise.toDto();
            await _remoteDataSource.update(enterprise.remoteId!, dto);
            await _localDataSource.updateSyncStatus(enterprise.localId, enterprise.remoteId!);
          } catch (e) {
            // Handle conflict or error
            continue;
          }
        }
      }
      
      // 2. Download remote changes
      final remoteEnterprises = await _remoteDataSource.getAll();
      final localEnterprises = await _localDataSource.getAll();
      
      for (final remoteDto in remoteEnterprises) {
        final existingLocal = localEnterprises
            .where((e) => e.remoteId == remoteDto.id)
            .firstOrNull;
            
        if (existingLocal == null) {
          // New remote entity
          final newLocal = remoteDto.toEntity(_uuid.v7());
          await _localDataSource.save(newLocal);
        } else if (!existingLocal.isModified) {
          // Update local with remote changes
          final updatedLocal = remoteDto.toEntity(existingLocal.localId);
          await _localDataSource.save(updatedLocal);
        }
        // Skip if local has modifications (conflict resolution needed)
      }
    } catch (e) {
      throw Exception('Sync failed: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> hasLocalChanges() async {
    final modified = await _localDataSource.getModified();
    return modified.isNotEmpty;
  }
  
  @override
  Stream<List<Enterprise>> watchAll() async* {
    // TODO: Implement stream that watches local changes
    // For now, return current data
    yield await getAllLocal();
  }
}