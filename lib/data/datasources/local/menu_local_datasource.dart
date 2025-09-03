import '../../../domain/entities/menu.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class MenuLocalDataSource {
  Future<List<Menu>> getAll();
  Future<List<Menu>> getByEnterpriseId(String enterpriseLocalId);
  Future<List<Menu>> getChildren(String parentMenuLocalId);
  Future<Menu?> getById(String localId);
  Future<void> save(Menu menu);
  Future<void> saveAll(List<Menu> menus);
  Future<void> delete(String localId);
  Future<void> clear();
  Future<List<Menu>> getModified();
  Future<void> updatePosition(String localId, int position);
  Future<void> updateSyncStatus(String localId, String remoteId);
}

class MenuLocalDataSourceImpl implements MenuLocalDataSource {
  final LocalStorageAdapter _storage;
  
  MenuLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<Menu>> getAll() async {
    final data = _storage.getList(LocalStorageAdapter.keyMenus);
    if (data == null || data.isEmpty) return [];
    
    return data.map((json) => Menu.fromJson(json)).toList();
  }
  
  @override
  Future<List<Menu>> getByEnterpriseId(String enterpriseLocalId) async {
    final menus = await getAll();
    return menus.where((m) => m.enterpriseLocalId == enterpriseLocalId).toList();
  }
  
  @override
  Future<List<Menu>> getChildren(String parentMenuLocalId) async {
    final menus = await getAll();
    return menus
        .where((m) => m.parentMenuLocalId == parentMenuLocalId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }
  
  @override
  Future<Menu?> getById(String localId) async {
    final menus = await getAll();
    try {
      return menus.firstWhere((m) => m.localId == localId);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<void> save(Menu menu) async {
    final menus = await getAll();
    
    final index = menus.indexWhere((m) => m.localId == menu.localId);
    if (index >= 0) {
      menus[index] = menu.copyWith(
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
    } else {
      menus.add(menu);
    }
    
    await _storage.saveList(
      LocalStorageAdapter.keyMenus,
      menus.map((m) => m.toJson()).toList(),
    );
  }
  
  @override
  Future<void> saveAll(List<Menu> menus) async {
    await _storage.saveList(
      LocalStorageAdapter.keyMenus,
      menus.map((m) => m.toJson()).toList(),
    );
  }
  
  @override
  Future<void> delete(String localId) async {
    final menus = await getAll();
    
    // Remove menu and its children recursively
    void removeMenuAndChildren(String menuId) {
      menus.removeWhere((m) => m.localId == menuId);
      final children = menus.where((m) => m.parentMenuLocalId == menuId).toList();
      for (final child in children) {
        removeMenuAndChildren(child.localId);
      }
    }
    
    removeMenuAndChildren(localId);
    
    await _storage.saveList(
      LocalStorageAdapter.keyMenus,
      menus.map((m) => m.toJson()).toList(),
    );
  }
  
  @override
  Future<void> clear() async {
    await _storage.remove(LocalStorageAdapter.keyMenus);
  }
  
  @override
  Future<List<Menu>> getModified() async {
    final menus = await getAll();
    return menus.where((m) => m.isModified).toList();
  }
  
  @override
  Future<void> updatePosition(String localId, int position) async {
    final menu = await getById(localId);
    if (menu != null) {
      await save(menu.copyWith(
        position: position,
        isModified: true,
        lastModifiedAt: DateTime.now(),
      ));
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    final menu = await getById(localId);
    if (menu != null) {
      await save(menu.copyWith(
        remoteId: remoteId,
        isModified: false,
        syncVersion: menu.syncVersion + 1,
      ));
    }
  }
}