import '../entities/suite.dart';

abstract class SuiteRepository {
  // Basic CRUD operations
  Future<Suite> create(Suite suite);
  Future<Suite> update(Suite suite);
  Future<void> delete(String localId);
  Future<Suite?> getById(String localId);
  Future<List<Suite>> getAll();
  
  // Business-specific queries
  Future<List<Suite>> getByFloorId(String floorLocalId);
  Future<List<Suite>> getByTowerId(String towerLocalId);
  Future<List<Suite>> getAvailable();
  Future<List<Suite>> getSold();
  Future<List<Suite>> getReserved();
  Future<Suite?> getBySuiteNumber(String floorLocalId, String suiteNumber);
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<Suite>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  
  // Search and filtering
  Future<List<Suite>> searchSuites(String query);
  Future<List<Suite>> getByPriceRange(double minPrice, double maxPrice);
  Future<List<Suite>> getByAreaRange(double minArea, double maxArea);
  Future<List<Suite>> getByRooms(int bedrooms, int bathrooms);
  Future<List<Suite>> getFavorites();
}