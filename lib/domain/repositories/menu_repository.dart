import '../entities/menu.dart';

abstract class MenuRepository {
  // Remote operations
  Future<List<Menu>> getByEnterpriseId(String enterpriseId);
  Future<List<Menu>> getHierarchy(String enterpriseId);
  Future<Menu?> getById(String id);
  Future<Menu> create(Menu menu);
  Future<Menu> update(Menu menu);
  Future<void> updatePosition(String id, int position);
  Future<void> delete(String id);
  
  // Local operations
  Future<List<Menu>> getByEnterpriseIdLocal(String enterpriseLocalId);
  Future<List<Menu>> getChildrenLocal(String parentMenuLocalId);
  Future<Menu?> getByIdLocal(String localId);
  Future<void> saveLocal(Menu menu);
  Future<void> saveAllLocal(List<Menu> menus);
  Future<void> deleteLocal(String localId);
  Future<void> clearLocal();
  
  // Navigation
  Future<List<Menu>> buildHierarchy(String enterpriseLocalId);
  Future<List<Menu>> getVisibleMenus(String enterpriseLocalId);
  
  // Sync operations
  Future<void> syncWithRemote(String enterpriseId);
  Stream<List<Menu>> watchByEnterpriseId(String enterpriseLocalId);
}