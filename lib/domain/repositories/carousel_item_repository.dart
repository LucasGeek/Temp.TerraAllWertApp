import '../entities/carousel_item.dart';

abstract class CarouselItemRepository {
  // Basic CRUD operations
  Future<CarouselItem> create(CarouselItem item);
  Future<CarouselItem> update(CarouselItem item);
  Future<void> delete(String localId);
  Future<CarouselItem?> getById(String localId);
  Future<List<CarouselItem>> getAll();
  
  // Business-specific queries
  Future<List<CarouselItem>> getByMenuId(String menuLocalId);
  Future<List<CarouselItem>> getActive();
  Future<List<CarouselItem>> getByPosition();
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<CarouselItem>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  
  // Position management
  Future<void> updatePosition(String localId, int position);
  Future<void> reorderItems(String menuLocalId, List<String> orderedIds);
}