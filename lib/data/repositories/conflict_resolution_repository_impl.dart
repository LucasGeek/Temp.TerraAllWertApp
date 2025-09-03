import 'package:uuid/uuid.dart';

import '../../domain/entities/conflict_resolution.dart';
import '../../domain/repositories/conflict_resolution_repository.dart';
import '../datasources/local/conflict_resolution_local_datasource.dart';

class ConflictResolutionRepositoryImpl implements ConflictResolutionRepository {
  final ConflictResolutionLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();

  ConflictResolutionRepositoryImpl(this._localDataSource);

  @override
  Future<ConflictResolution> create(ConflictResolution conflict) async {
    try {
      final localConflict = conflict.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );

      await _localDataSource.save(localConflict);
      return localConflict;
    } catch (e) {
      throw Exception('Failed to create conflict resolution: ${e.toString()}');
    }
  }

  @override
  Future<ConflictResolution> update(ConflictResolution conflict) async {
    try {
      final updatedConflict = conflict.copyWith(isModified: true, lastModifiedAt: DateTime.now());

      await _localDataSource.save(updatedConflict);
      return updatedConflict;
    } catch (e) {
      throw Exception('Failed to update conflict resolution: ${e.toString()}');
    }
  }

  @override
  Future<void> delete(String localId) async {
    try {
      final conflict = await _localDataSource.getById(localId);
      if (conflict == null) return;

      final deletedConflict = conflict.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );

      await _localDataSource.save(deletedConflict);
    } catch (e) {
      throw Exception('Failed to delete conflict resolution: ${e.toString()}');
    }
  }

  @override
  Future<ConflictResolution?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get conflict resolution by id: ${e.toString()}');
    }
  }

  @override
  Future<List<ConflictResolution>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all conflict resolutions: ${e.toString()}');
    }
  }

  @override
  Future<List<ConflictResolution>> getPending() async {
    try {
      return await _localDataSource.getPending();
    } catch (e) {
      throw Exception('Failed to get pending conflicts: ${e.toString()}');
    }
  }

  @override
  Future<List<ConflictResolution>> getResolved() async {
    try {
      return await _localDataSource.getResolved();
    } catch (e) {
      throw Exception('Failed to get resolved conflicts: ${e.toString()}');
    }
  }

  @override
  Future<List<ConflictResolution>> getByEntityType(String entityType) async {
    try {
      return await _localDataSource.getByEntityType(entityType);
    } catch (e) {
      throw Exception('Failed to get conflicts by entity type: ${e.toString()}');
    }
  }

  @override
  Future<List<ConflictResolution>> getByEntityId(String entityLocalId) async {
    try {
      return await _localDataSource.getByEntityId(entityLocalId);
    } catch (e) {
      throw Exception('Failed to get conflicts by entity id: ${e.toString()}');
    }
  }

  @override
  Future<ConflictResolution?> getActiveConflictForEntity(
    String entityType,
    String entityLocalId,
  ) async {
    try {
      final conflicts = await _localDataSource.getByEntityType(entityType);
      try {
        return conflicts.firstWhere(
          (conflict) =>
              conflict.entityLocalId == entityLocalId &&
              conflict.deletedAt == null &&
              conflict.isResolved == false,
        );
      } catch (_) {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to get active conflict for entity: ${e.toString()}');
    }
  }

  @override
  Future<void> syncFromRemote() async {
    try {
      // Conflict resolution is primarily local operation
      // Remote sync would fetch server-side conflict markers
      final modifiedConflicts = await _localDataSource.getModified();

      for (final conflict in modifiedConflicts) {
        // Mark as synced locally
        final syncedConflict = conflict.copyWith(isModified: false);
        await _localDataSource.save(syncedConflict);
      }
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }

  @override
  Future<void> syncToRemote() async {
    try {
      final modifiedConflicts = await _localDataSource.getModified();

      for (final conflict in modifiedConflicts) {
        try {
          // Mark as synced (conflict resolution is local-first)
          final syncedConflict = conflict.copyWith(isModified: false);
          await _localDataSource.save(syncedConflict);
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to sync to remote: ${e.toString()}');
    }
  }

  @override
  Future<List<ConflictResolution>> getModified() async {
    try {
      return await _localDataSource.getModified();
    } catch (e) {
      throw Exception('Failed to get modified conflicts: ${e.toString()}');
    }
  }

  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local conflicts: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local conflict: ${e.toString()}');
    }
  }

  @override
  Future<void> resolveWithLocal(String localId) async {
    try {
      final conflict = await _localDataSource.getById(localId);
      if (conflict != null) {
        final resolvedConflict = conflict.copyWith(
          isResolved: true,
          resolvedAt: DateTime.now(),
          resolvedBy: 'local',
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(resolvedConflict);
      }
    } catch (e) {
      throw Exception('Failed to resolve with local: ${e.toString()}');
    }
  }

  @override
  Future<void> resolveWithRemote(String localId) async {
    try {
      final conflict = await _localDataSource.getById(localId);
      if (conflict != null) {
        final resolvedConflict = conflict.copyWith(
          isResolved: true,
          resolvedAt: DateTime.now(),
          resolvedBy: 'remote',
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(resolvedConflict);
      }
    } catch (e) {
      throw Exception('Failed to resolve with remote: ${e.toString()}');
    }
  }

  @override
  Future<void> resolveWithMerged(String localId, Map<String, dynamic> mergedData) async {
    try {
      final conflict = await _localDataSource.getById(localId);
      if (conflict != null) {
        final resolvedConflict = conflict.copyWith(
          isResolved: true,
          resolvedAt: DateTime.now(),
          resolvedBy: 'merged',
          resolvedData: mergedData,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(resolvedConflict);
      }
    } catch (e) {
      throw Exception('Failed to resolve with merged data: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsResolved(String localId, String resolvedBy) async {
    try {
      final conflict = await _localDataSource.getById(localId);
      if (conflict != null) {
        final resolvedConflict = conflict.copyWith(
          isResolved: true,
          resolvedAt: DateTime.now(),
          resolvedBy: resolvedBy,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(resolvedConflict);
      }
    } catch (e) {
      throw Exception('Failed to mark as resolved: ${e.toString()}');
    }
  }

  @override
  Future<int> getPendingConflictCount() async {
    try {
      final pendingConflicts = await getPending();
      return pendingConflicts.length;
    } catch (e) {
      return 0;
    }
  }
}
