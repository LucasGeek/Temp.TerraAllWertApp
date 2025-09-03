import '../entities/pin_marker.dart';

abstract class PinMarkerRepository {
  // Basic CRUD operations
  Future<PinMarker> create(PinMarker marker);
  Future<PinMarker> update(PinMarker marker);
  Future<void> delete(String localId);
  Future<PinMarker?> getById(String localId);
  Future<List<PinMarker>> getAll();
  
  // Business-specific queries
  Future<List<PinMarker>> getByFloorId(String floorLocalId);
  Future<List<PinMarker>> getBySuiteId(String suiteLocalId);
  Future<List<PinMarker>> getActive();
  Future<List<PinMarker>> getInArea(double minX, double minY, double maxX, double maxY);
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<PinMarker>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  
  // Position management
  Future<void> updatePosition(String localId, double x, double y);
  Future<List<PinMarker>> getNearbyMarkers(double x, double y, double radius);
}