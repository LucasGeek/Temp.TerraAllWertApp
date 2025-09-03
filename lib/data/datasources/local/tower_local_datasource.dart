import '../../../domain/entities/tower.dart';
import '../../../domain/entities/floor.dart';
import '../../../domain/entities/suite.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class TowerLocalDataSource {
  // Tower operations
  Future<List<Tower>> getTowersByMenuId(String menuLocalId);
  Future<Tower?> getTowerById(String localId);
  Future<void> saveTower(Tower tower);
  Future<void> saveTowers(List<Tower> towers);
  Future<void> deleteTower(String localId);
  
  // Floor operations
  Future<List<Floor>> getFloorsByTowerId(String towerLocalId);
  Future<Floor?> getFloorById(String localId);
  Future<Floor?> getFloorByNumber(String towerLocalId, int floorNumber);
  Future<void> saveFloor(Floor floor);
  Future<void> saveFloors(List<Floor> floors);
  Future<void> deleteFloor(String localId);
  
  // Suite operations
  Future<List<Suite>> getSuitesByFloorId(String floorLocalId);
  Future<Suite?> getSuiteById(String localId);
  Future<List<Suite>> searchSuites(Map<String, dynamic> filters);
  Future<List<Suite>> getFavorites();
  Future<void> saveSuite(Suite suite);
  Future<void> saveSuites(List<Suite> suites);
  Future<void> deleteSuite(String localId);
  Future<void> toggleFavorite(String localId);
  
  // General operations
  Future<void> clear();
  Future<List<Tower>> getModifiedTowers();
  Future<List<Floor>> getModifiedFloors();
  Future<List<Suite>> getModifiedSuites();
}

class TowerLocalDataSourceImpl implements TowerLocalDataSource {
  final LocalStorageAdapter _storage;
  
  TowerLocalDataSourceImpl(this._storage);
  
  // ===== Tower Operations =====
  
  @override
  Future<List<Tower>> getTowersByMenuId(String menuLocalId) async {
    final data = _storage.getList(LocalStorageAdapter.keyTowers);
    if (data == null || data.isEmpty) return [];
    
    final towers = data.map((json) => Tower.fromJson(json)).toList();
    return towers.where((t) => t.menuLocalId == menuLocalId).toList();
  }
  
  @override
  Future<Tower?> getTowerById(String localId) async {
    final data = _storage.getList(LocalStorageAdapter.keyTowers);
    if (data == null) return null;
    
    final towers = data.map((json) => Tower.fromJson(json)).toList();
    try {
      return towers.firstWhere((t) => t.localId == localId);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<void> saveTower(Tower tower) async {
    final data = _storage.getList(LocalStorageAdapter.keyTowers) ?? [];
    final towers = data.map((json) => Tower.fromJson(json)).toList();
    
    final index = towers.indexWhere((t) => t.localId == tower.localId);
    if (index >= 0) {
      towers[index] = tower.copyWith(
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
    } else {
      towers.add(tower);
    }
    
    await _storage.saveList(
      LocalStorageAdapter.keyTowers,
      towers.map((t) => t.toJson()).toList(),
    );
  }
  
  @override
  Future<void> saveTowers(List<Tower> towers) async {
    await _storage.saveList(
      LocalStorageAdapter.keyTowers,
      towers.map((t) => t.toJson()).toList(),
    );
  }
  
  @override
  Future<void> deleteTower(String localId) async {
    final data = _storage.getList(LocalStorageAdapter.keyTowers) ?? [];
    final towers = data.map((json) => Tower.fromJson(json)).toList();
    
    towers.removeWhere((t) => t.localId == localId);
    
    await _storage.saveList(
      LocalStorageAdapter.keyTowers,
      towers.map((t) => t.toJson()).toList(),
    );
  }
  
  // ===== Floor Operations =====
  
  @override
  Future<List<Floor>> getFloorsByTowerId(String towerLocalId) async {
    final data = _storage.getList(LocalStorageAdapter.keyFloors);
    if (data == null || data.isEmpty) return [];
    
    final floors = data.map((json) => Floor.fromJson(json)).toList();
    return floors.where((f) => f.towerLocalId == towerLocalId).toList()
      ..sort((a, b) => a.floorNumber.compareTo(b.floorNumber));
  }
  
  @override
  Future<Floor?> getFloorById(String localId) async {
    final data = _storage.getList(LocalStorageAdapter.keyFloors);
    if (data == null) return null;
    
    final floors = data.map((json) => Floor.fromJson(json)).toList();
    try {
      return floors.firstWhere((f) => f.localId == localId);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<Floor?> getFloorByNumber(String towerLocalId, int floorNumber) async {
    final floors = await getFloorsByTowerId(towerLocalId);
    try {
      return floors.firstWhere((f) => f.floorNumber == floorNumber);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<void> saveFloor(Floor floor) async {
    final data = _storage.getList(LocalStorageAdapter.keyFloors) ?? [];
    final floors = data.map((json) => Floor.fromJson(json)).toList();
    
    final index = floors.indexWhere((f) => f.localId == floor.localId);
    if (index >= 0) {
      floors[index] = floor.copyWith(
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
    } else {
      floors.add(floor);
    }
    
    await _storage.saveList(
      LocalStorageAdapter.keyFloors,
      floors.map((f) => f.toJson()).toList(),
    );
  }
  
  @override
  Future<void> saveFloors(List<Floor> floors) async {
    await _storage.saveList(
      LocalStorageAdapter.keyFloors,
      floors.map((f) => f.toJson()).toList(),
    );
  }
  
  @override
  Future<void> deleteFloor(String localId) async {
    final data = _storage.getList(LocalStorageAdapter.keyFloors) ?? [];
    final floors = data.map((json) => Floor.fromJson(json)).toList();
    
    floors.removeWhere((f) => f.localId == localId);
    
    await _storage.saveList(
      LocalStorageAdapter.keyFloors,
      floors.map((f) => f.toJson()).toList(),
    );
  }
  
  // ===== Suite Operations =====
  
  @override
  Future<List<Suite>> getSuitesByFloorId(String floorLocalId) async {
    final data = _storage.getList(LocalStorageAdapter.keySuites);
    if (data == null || data.isEmpty) return [];
    
    final suites = data.map((json) => Suite.fromJson(json)).toList();
    return suites.where((s) => s.floorLocalId == floorLocalId).toList()
      ..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
  }
  
  @override
  Future<Suite?> getSuiteById(String localId) async {
    final data = _storage.getList(LocalStorageAdapter.keySuites);
    if (data == null) return null;
    
    final suites = data.map((json) => Suite.fromJson(json)).toList();
    try {
      return suites.firstWhere((s) => s.localId == localId);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<List<Suite>> searchSuites(Map<String, dynamic> filters) async {
    final data = _storage.getList(LocalStorageAdapter.keySuites);
    if (data == null || data.isEmpty) return [];
    
    var suites = data.map((json) => Suite.fromJson(json)).toList();
    
    // Apply filters
    if (filters['query'] != null) {
      final query = filters['query'].toString().toLowerCase();
      suites = suites.where((s) => 
        s.title.toLowerCase().contains(query) ||
        s.unitNumber.toLowerCase().contains(query) ||
        (s.description?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    if (filters['minBedrooms'] != null) {
      suites = suites.where((s) => s.bedrooms >= filters['minBedrooms']).toList();
    }
    
    if (filters['maxBedrooms'] != null) {
      suites = suites.where((s) => s.bedrooms <= filters['maxBedrooms']).toList();
    }
    
    if (filters['minArea'] != null) {
      suites = suites.where((s) => s.areaSqm >= filters['minArea']).toList();
    }
    
    if (filters['maxArea'] != null) {
      suites = suites.where((s) => s.areaSqm <= filters['maxArea']).toList();
    }
    
    if (filters['minPrice'] != null && filters['minPrice'] is double) {
      suites = suites.where((s) => s.price != null && s.price! >= filters['minPrice']).toList();
    }
    
    if (filters['maxPrice'] != null && filters['maxPrice'] is double) {
      suites = suites.where((s) => s.price != null && s.price! <= filters['maxPrice']).toList();
    }
    
    if (filters['status'] != null) {
      suites = suites.where((s) => s.status == filters['status']).toList();
    }
    
    return suites;
  }
  
  @override
  Future<List<Suite>> getFavorites() async {
    final data = _storage.getList(LocalStorageAdapter.keySuites);
    if (data == null || data.isEmpty) return [];
    
    final suites = data.map((json) => Suite.fromJson(json)).toList();
    return suites.where((s) => s.isFavorite).toList();
  }
  
  @override
  Future<void> saveSuite(Suite suite) async {
    final data = _storage.getList(LocalStorageAdapter.keySuites) ?? [];
    final suites = data.map((json) => Suite.fromJson(json)).toList();
    
    final index = suites.indexWhere((s) => s.localId == suite.localId);
    if (index >= 0) {
      suites[index] = suite.copyWith(
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
    } else {
      suites.add(suite);
    }
    
    await _storage.saveList(
      LocalStorageAdapter.keySuites,
      suites.map((s) => s.toJson()).toList(),
    );
  }
  
  @override
  Future<void> saveSuites(List<Suite> suites) async {
    await _storage.saveList(
      LocalStorageAdapter.keySuites,
      suites.map((s) => s.toJson()).toList(),
    );
  }
  
  @override
  Future<void> deleteSuite(String localId) async {
    final data = _storage.getList(LocalStorageAdapter.keySuites) ?? [];
    final suites = data.map((json) => Suite.fromJson(json)).toList();
    
    suites.removeWhere((s) => s.localId == localId);
    
    await _storage.saveList(
      LocalStorageAdapter.keySuites,
      suites.map((s) => s.toJson()).toList(),
    );
  }
  
  @override
  Future<void> toggleFavorite(String localId) async {
    final suite = await getSuiteById(localId);
    if (suite != null) {
      await saveSuite(suite.copyWith(
        isFavorite: !suite.isFavorite,
        favoritedAt: !suite.isFavorite ? DateTime.now() : null,
      ));
    }
  }
  
  // ===== General Operations =====
  
  @override
  Future<void> clear() async {
    await _storage.remove(LocalStorageAdapter.keyTowers);
    await _storage.remove(LocalStorageAdapter.keyFloors);
    await _storage.remove(LocalStorageAdapter.keySuites);
  }
  
  @override
  Future<List<Tower>> getModifiedTowers() async {
    final data = _storage.getList(LocalStorageAdapter.keyTowers);
    if (data == null) return [];
    
    final towers = data.map((json) => Tower.fromJson(json)).toList();
    return towers.where((t) => t.isModified).toList();
  }
  
  @override
  Future<List<Floor>> getModifiedFloors() async {
    final data = _storage.getList(LocalStorageAdapter.keyFloors);
    if (data == null) return [];
    
    final floors = data.map((json) => Floor.fromJson(json)).toList();
    return floors.where((f) => f.isModified).toList();
  }
  
  @override
  Future<List<Suite>> getModifiedSuites() async {
    final data = _storage.getList(LocalStorageAdapter.keySuites);
    if (data == null) return [];
    
    final suites = data.map((json) => Suite.fromJson(json)).toList();
    return suites.where((s) => s.isModified).toList();
  }
}