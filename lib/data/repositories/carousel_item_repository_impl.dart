import '../../domain/entities/carousel_item.dart';
import '../../domain/repositories/carousel_item_repository.dart';
import '../datasources/local/carousel_item_local_datasource.dart';
import '../datasources/remote/carousel_item_remote_datasource.dart';
import '../models/carousel_item_dto.dart';
import 'package:uuid/uuid.dart';

class CarouselItemRepositoryImpl implements CarouselItemRepository {
  final CarouselItemLocalDataSource _localDataSource;
  final CarouselItemRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  CarouselItemRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<CarouselItem> create(CarouselItem item) async {
    try {
      // Offline-first: create locally first
      final localItem = item.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localItem);
      
      // Try to sync with remote
      try {
        final dto = localItem.toDto();
        final remoteDto = await _remoteDataSource.create(dto);
        
        // Update with remote ID and mark as synced
        final syncedItem = localItem.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        
        await _localDataSource.save(syncedItem);
        return syncedItem;
      } catch (e) {
        // Keep local copy for later sync
        return localItem;
      }
    } catch (e) {
      throw Exception('Failed to create carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<CarouselItem> update(CarouselItem item) async {
    try {
      final updatedItem = item.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedItem);
      
      // Try to sync with remote if has remote ID
      if (item.remoteId != null) {
        try {
          final dto = updatedItem.toDto();
          await _remoteDataSource.update(item.remoteId!, dto);
          
          final syncedItem = updatedItem.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.save(syncedItem);
          return syncedItem;
        } catch (e) {
          return updatedItem;
        }
      }
      
      return updatedItem;
    } catch (e) {
      throw Exception('Failed to update carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final item = await _localDataSource.getById(localId);
      if (item == null) return;
      
      // Soft delete locally
      final deletedItem = item.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(deletedItem);
      
      // Try to delete from remote if has remote ID
      if (item.remoteId != null) {
        try {
          await _remoteDataSource.delete(item.remoteId!);
          await _localDataSource.delete(localId);
        } catch (e) {
          // Keep soft delete for later sync
        }
      }
    } catch (e) {
      throw Exception('Failed to delete carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<CarouselItem?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get carousel item by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CarouselItem>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CarouselItem>> getByMenuId(String menuLocalId) async {
    try {
      return await _localDataSource.getByMenuId(menuLocalId);
    } catch (e) {
      throw Exception('Failed to get carousel items by menu: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CarouselItem>> getActive() async {
    try {
      final items = await _localDataSource.getAll();
      return items.where((item) => item.isActive && item.deletedAt == null).toList();
    } catch (e) {
      throw Exception('Failed to get active carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CarouselItem>> getByPosition() async {
    try {
      final items = await _localDataSource.getAll();
      items.sort((a, b) => a.position.compareTo(b.position));
      return items.where((item) => item.deletedAt == null).toList();
    } catch (e) {
      throw Exception('Failed to get carousel items by position: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updatePosition(String localId, int position) async {
    try {
      final item = await _localDataSource.getById(localId);
      if (item != null) {
        final updatedItem = item.copyWith(
          position: position,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(updatedItem);
        
        // Try to sync position with remote
        if (item.remoteId != null) {
          try {
            await _remoteDataSource.updatePosition(item.remoteId!, position);
          } catch (e) {
            // Will sync later
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update carousel item position: ${e.toString()}');
    }
  }
  
  @override
  Future<void> reorderItems(String menuLocalId, List<String> orderedIds) async {
    try {
      for (int i = 0; i < orderedIds.length; i++) {
        await updatePosition(orderedIds[i], i);
      }
    } catch (e) {
      throw Exception('Failed to reorder carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      final remoteDtos = await _remoteDataSource.getAll();
      final localItems = <CarouselItem>[];
      
      for (final dto in remoteDtos) {
        final localItem = dto.toEntity(_uuid.v7());
        localItems.add(localItem);
      }
      
      await _localDataSource.saveAll(localItems);
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote() async {
    try {
      final modifiedItems = await _localDataSource.getModified();
      
      for (final item in modifiedItems) {
        try {
          final dto = item.toDto();
          
          if (item.remoteId == null) {
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(item.localId, remoteDto.id);
          } else {
            await _remoteDataSource.update(item.remoteId!, dto);
            await _localDataSource.updateSyncStatus(item.localId, item.remoteId!);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to sync to remote: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CarouselItem>> getModified() async {
    try {
      return await _localDataSource.getModified();
    } catch (e) {
      throw Exception('Failed to get modified carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local carousel item: ${e.toString()}');
    }
  }
}