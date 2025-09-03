import '../../../domain/entities/data_version.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class DataVersionLocalDataSource {
  Future<List<DataVersion>> getAll();
  Future<DataVersion?> getById(String localId);
  Future<DataVersion?> getByTableName(String tableName);
  Future<void> save(DataVersion dataVersion);
  Future<void> saveAll(List<DataVersion> dataVersions);
  Future<void> delete(String localId);
  Future<void> clear();
  Future<List<DataVersion>> getModified();
  Future<List<DataVersion>> getOutdated();
  Future<void> updateSyncStatus(String localId, String? remoteId);
}

class DataVersionLocalDataSourceImpl implements DataVersionLocalDataSource {
  final LocalStorageAdapter _storage;
  static const String _key = 'data_versions';
  
  DataVersionLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<DataVersion>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      if (data == null || data.isEmpty) return [];
      
      return data.map((json) => DataVersion.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<DataVersion?> getById(String localId) async {
    try {
      final all = await getAll();
      return all.cast<DataVersion?>().firstWhere(
        (version) => version?.localId == localId,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<DataVersion?> getByTableName(String tableName) async {
    try {
      final all = await getAll();
      return all.cast<DataVersion?>().firstWhere(
        (version) => version?.entityType == tableName,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> save(DataVersion dataVersion) async {
    try {
      final data = await getAll();
      
      final index = data.indexWhere((v) => v.localId == dataVersion.localId);
      if (index >= 0) {
        data[index] = dataVersion;
      } else {
        data.add(dataVersion);
      }
      
      await _storage.setJsonList(
        _key,
        data.map((v) => v.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to save data version: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<DataVersion> dataVersions) async {
    try {
      await _storage.setJsonList(
        _key,
        dataVersions.map((v) => v.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to save all data versions: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final data = await getAll();
      data.removeWhere((v) => v.localId == localId);
      
      await _storage.setJsonList(
        _key,
        data.map((v) => v.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to delete data version: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear data versions: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DataVersion>> getModified() async {
    try {
      final all = await getAll();
      // DataVersion não tem campo isModified, retornar todos por padrão
      return all;
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<DataVersion>> getOutdated() async {
    try {
      // DataVersion não tem campo lastSyncedAt, retornar lista vazia
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String? remoteId) async {
    try {
      final version = await getById(localId);
      if (version != null) {
        // DataVersion não tem esses campos, apenas salvar sem modificar
        final syncedVersion = version;
        await save(syncedVersion);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
}