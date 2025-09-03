import '../../../domain/entities/enterprise.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class EnterpriseLocalDataSource {
  Future<List<Enterprise>> getAll();
  Future<Enterprise?> getById(String localId);
  Future<Enterprise?> getBySlug(String slug);
  Future<void> save(Enterprise enterprise);
  Future<void> saveAll(List<Enterprise> enterprises);
  Future<void> delete(String localId);
  Future<void> clear();
  Future<List<Enterprise>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
}

class EnterpriseLocalDataSourceImpl implements EnterpriseLocalDataSource {
  final LocalStorageAdapter _storage;
  
  EnterpriseLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<Enterprise>> getAll() async {
    final data = _storage.getList(LocalStorageAdapter.keyEnterprises);
    if (data == null || data.isEmpty) return [];
    
    return data.map((json) => Enterprise.fromJson(json)).toList();
  }
  
  @override
  Future<Enterprise?> getById(String localId) async {
    final enterprises = await getAll();
    try {
      return enterprises.firstWhere((e) => e.localId == localId);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<Enterprise?> getBySlug(String slug) async {
    final enterprises = await getAll();
    try {
      return enterprises.firstWhere((e) => e.slug == slug);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<void> save(Enterprise enterprise) async {
    final enterprises = await getAll();
    
    // Update or add
    final index = enterprises.indexWhere((e) => e.localId == enterprise.localId);
    if (index >= 0) {
      enterprises[index] = enterprise.copyWith(
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
    } else {
      enterprises.add(enterprise);
    }
    
    await _storage.saveList(
      LocalStorageAdapter.keyEnterprises,
      enterprises.map((e) => e.toJson()).toList(),
    );
  }
  
  @override
  Future<void> saveAll(List<Enterprise> enterprises) async {
    await _storage.saveList(
      LocalStorageAdapter.keyEnterprises,
      enterprises.map((e) => e.toJson()).toList(),
    );
  }
  
  @override
  Future<void> delete(String localId) async {
    final enterprises = await getAll();
    enterprises.removeWhere((e) => e.localId == localId);
    
    await _storage.saveList(
      LocalStorageAdapter.keyEnterprises,
      enterprises.map((e) => e.toJson()).toList(),
    );
  }
  
  @override
  Future<void> clear() async {
    await _storage.remove(LocalStorageAdapter.keyEnterprises);
  }
  
  @override
  Future<List<Enterprise>> getModified() async {
    final enterprises = await getAll();
    return enterprises.where((e) => e.isModified).toList();
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    final enterprise = await getById(localId);
    if (enterprise != null) {
      await save(enterprise.copyWith(
        remoteId: remoteId,
        isModified: false,
        syncVersion: enterprise.syncVersion + 1,
      ));
    }
  }
}