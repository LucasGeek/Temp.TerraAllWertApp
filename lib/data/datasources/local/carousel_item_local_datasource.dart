import '../../../domain/entities/carousel_item.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class CarouselItemLocalDataSource {
  Future<List<CarouselItem>> getAll();
  Future<CarouselItem?> getById(String id);
  Future<List<CarouselItem>> getByMenuId(String menuId);
  Future<void> save(CarouselItem item);
  Future<void> saveAll(List<CarouselItem> items);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<CarouselItem>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
}

class CarouselItemLocalDataSourceImpl implements CarouselItemLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'carousel_items';
  
  CarouselItemLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<CarouselItem>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => CarouselItem.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<CarouselItem?> getById(String id) async {
    try {
      final items = await getAll();
      return items.where((item) => item.localId == id || item.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<CarouselItem>> getByMenuId(String menuId) async {
    try {
      final items = await getAll();
      return items.where((item) => item.menuLocalId == menuId).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(CarouselItem item) async {
    try {
      final items = await getAll();
      final index = items.indexWhere((i) => i.localId == item.localId);
      
      if (index >= 0) {
        items[index] = item;
      } else {
        items.add(item);
      }
      
      final jsonList = items.map((item) => item.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<CarouselItem> items) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final items = await getAll();
      items.removeWhere((item) => item.localId == id || item.remoteId == id);
      
      final jsonList = items.map((item) => item.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CarouselItem>> getModified() async {
    try {
      final items = await getAll();
      return items.where((item) => item.isModified && item.deletedAt == null).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final item = await getById(localId);
      if (item != null) {
        final updatedItem = item.copyWith(
          remoteId: remoteId,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        await save(updatedItem);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
}