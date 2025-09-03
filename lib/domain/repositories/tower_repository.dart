import '../entities/tower.dart';
import '../entities/floor.dart';
import '../entities/suite.dart';

abstract class TowerRepository {
  // Tower operations
  Future<List<Tower>> getByMenuId(String menuId);
  Future<Tower?> getById(String id);
  Future<Tower> create(Tower tower);
  Future<Tower> update(Tower tower);
  Future<void> updatePosition(String id, int position);
  Future<void> delete(String id);
  
  // Floor operations
  Future<List<Floor>> getFloorsByTowerId(String towerId);
  Future<Floor?> getFloorById(String id);
  Future<Floor?> getFloorByNumber(String towerId, int floorNumber);
  Future<Floor> createFloor(Floor floor);
  Future<Floor> updateFloor(Floor floor);
  Future<void> deleteFloor(String id);
  
  // Suite operations
  Future<List<Suite>> getSuitesByFloorId(String floorId);
  Future<Suite?> getSuiteById(String id);
  Future<List<Suite>> searchSuites({
    String? query,
    int? minBedrooms,
    int? maxBedrooms,
    double? minArea,
    double? maxArea,
    double? minPrice,
    double? maxPrice,
    String? status,
  });
  Future<Suite> createSuite(Suite suite);
  Future<Suite> updateSuite(Suite suite);
  Future<void> updateSuiteStatus(String id, String status);
  Future<void> deleteSuite(String id);
  
  // Local operations
  Future<List<Tower>> getByMenuIdLocal(String menuLocalId);
  Future<void> saveTowerLocal(Tower tower);
  Future<void> saveFloorsLocal(List<Floor> floors);
  Future<void> saveSuitesLocal(List<Suite> suites);
  
  // Favorites
  Future<void> toggleFavorite(String suiteLocalId);
  Future<List<Suite>> getFavorites();
  
  // Sync operations
  Future<void> syncTowersWithRemote(String menuId);
  Stream<List<Tower>> watchTowersByMenuId(String menuLocalId);
}