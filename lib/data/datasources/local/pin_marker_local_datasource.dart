import '../../../domain/entities/pin_marker.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class PinMarkerLocalDataSource {
  Future<List<PinMarker>> getAll();
  Future<PinMarker?> getById(String id);
  Future<List<PinMarker>> getByFloorId(String floorId);
  Future<List<PinMarker>> getBySuiteId(String suiteId);
  Future<void> save(PinMarker marker);
  Future<void> saveAll(List<PinMarker> markers);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<PinMarker>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
  Future<List<PinMarker>> getInArea(double minX, double minY, double maxX, double maxY);
}

class PinMarkerLocalDataSourceImpl implements PinMarkerLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'pin_markers';
  
  PinMarkerLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<PinMarker>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => PinMarker.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<PinMarker?> getById(String id) async {
    try {
      final markers = await getAll();
      return markers.where((marker) => marker.localId == id || marker.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<PinMarker>> getByFloorId(String floorId) async {
    try {
      final markers = await getAll();
      // PinMarker não tem campo floorLocalId, usando menuLocalId como alternativa
      return markers.where((marker) => marker.menuLocalId == floorId).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<PinMarker>> getBySuiteId(String suiteId) async {
    try {
      final markers = await getAll();
      // PinMarker não tem campo suiteLocalId, usando menuLocalId como alternativa
      return markers.where((marker) => marker.menuLocalId == suiteId).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(PinMarker marker) async {
    try {
      final markers = await getAll();
      final index = markers.indexWhere((m) => m.localId == marker.localId);
      
      if (index >= 0) {
        markers[index] = marker;
      } else {
        markers.add(marker);
      }
      
      final jsonList = markers.map((marker) => marker.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<PinMarker> markers) async {
    try {
      final jsonList = markers.map((marker) => marker.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save pin markers: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final markers = await getAll();
      markers.removeWhere((marker) => marker.localId == id || marker.remoteId == id);
      
      final jsonList = markers.map((marker) => marker.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear pin markers: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getModified() async {
    try {
      final markers = await getAll();
      return markers.where((marker) => marker.isModified && marker.deletedAt == null).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final marker = await getById(localId);
      if (marker != null) {
        final updatedMarker = marker.copyWith(
          remoteId: remoteId,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        await save(updatedMarker);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getInArea(double minX, double minY, double maxX, double maxY) async {
    try {
      final markers = await getAll();
      return markers.where((marker) => 
        marker.positionX >= minX && marker.positionX <= maxX && 
        marker.positionY >= minY && marker.positionY <= maxY &&
        marker.deletedAt == null
      ).toList();
    } catch (e) {
      return [];
    }
  }
}