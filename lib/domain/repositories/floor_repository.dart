import '../entities/floor.dart';

abstract class FloorRepository {
  // Basic CRUD operations
  Future<Floor> create(Floor floor);
  Future<Floor> update(Floor floor);
  Future<void> delete(String localId);
  Future<Floor?> getById(String localId);
  Future<List<Floor>> getAll();
  
  // Business-specific queries
  Future<List<Floor>> getByTowerId(String towerLocalId);
  Future<List<Floor>> getActive();
  Future<Floor?> getByNumber(String towerLocalId, int floorNumber);
  Future<List<Floor>> getAvailable();
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<Floor>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  
  // Floor-specific operations
  Future<int> getTotalFloors(String towerLocalId);
  Future<List<Floor>> getFloorRange(String towerLocalId, int startFloor, int endFloor);
  Future<bool> hasAvailableSuites(String floorLocalId);
}