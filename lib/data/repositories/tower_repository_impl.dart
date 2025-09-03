import '../../domain/entities/tower.dart';
import '../../domain/entities/floor.dart';
import '../../domain/entities/suite.dart';
import '../../domain/repositories/tower_repository.dart';
import '../datasources/local/tower_local_datasource.dart';
import '../datasources/remote/tower_remote_datasource.dart';
import '../models/tower_dto.dart';
import '../models/floor_dto.dart';
import '../models/suite_dto.dart';
import 'package:uuid/uuid.dart';

class TowerRepositoryImpl implements TowerRepository {
  final TowerLocalDataSource _localDataSource;
  final TowerRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  TowerRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  // ===== Tower Operations =====
  
  @override
  Future<List<Tower>> getByMenuId(String menuId) async {
    try {
      final remoteDtos = await _remoteDataSource.getTowersByMenuId(menuId);
      final towers = remoteDtos.map((dto) => dto.toEntity(_uuid.v7())).toList();
      return towers;
    } catch (e) {
      return await _localDataSource.getTowersByMenuId(menuId);
    }
  }
  
  @override
  Future<Tower?> getById(String id) async {
    try {
      return await _localDataSource.getTowerById(id);
    } catch (e) {
      throw Exception('Failed to get tower by id: ${e.toString()}');
    }
  }
  
  @override
  Future<Tower> create(Tower tower) async {
    try {
      final localTower = tower.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveTower(localTower);
      
      try {
        final dto = localTower.toDto();
        final remoteDto = await _remoteDataSource.createTower(dto);
        
        final syncedTower = localTower.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        
        await _localDataSource.saveTower(syncedTower);
        return syncedTower;
      } catch (e) {
        return localTower;
      }
    } catch (e) {
      throw Exception('Failed to create tower: ${e.toString()}');
    }
  }
  
  @override
  Future<Tower> update(Tower tower) async {
    try {
      final updatedTower = tower.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveTower(updatedTower);
      
      if (tower.remoteId != null) {
        try {
          final dto = updatedTower.toDto();
          await _remoteDataSource.updateTower(tower.remoteId!, dto);
          
          final syncedTower = updatedTower.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.saveTower(syncedTower);
          return syncedTower;
        } catch (e) {
          return updatedTower;
        }
      }
      
      return updatedTower;
    } catch (e) {
      throw Exception('Failed to update tower: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updatePosition(String id, int position) async {
    try {
      final tower = await _localDataSource.getTowerById(id);
      if (tower != null) {
        final updatedTower = tower.copyWith(
          position: position,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.saveTower(updatedTower);
        
        if (tower.remoteId != null) {
          try {
            await _remoteDataSource.updateTowerPosition(tower.remoteId!, position);
          } catch (e) {
            // Will sync later
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update tower position: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final tower = await _localDataSource.getTowerById(id);
      if (tower == null) return;
      
      await _localDataSource.deleteTower(id);
      
      if (tower.remoteId != null) {
        try {
          await _remoteDataSource.deleteTower(tower.remoteId!);
        } catch (e) {
          // Will sync later
        }
      }
    } catch (e) {
      throw Exception('Failed to delete tower: ${e.toString()}');
    }
  }
  
  // ===== Floor Operations =====
  
  @override
  Future<List<Floor>> getFloorsByTowerId(String towerId) async {
    try {
      return await _localDataSource.getFloorsByTowerId(towerId);
    } catch (e) {
      throw Exception('Failed to get floors by tower id: ${e.toString()}');
    }
  }
  
  @override
  Future<Floor?> getFloorById(String id) async {
    try {
      return await _localDataSource.getFloorById(id);
    } catch (e) {
      throw Exception('Failed to get floor by id: ${e.toString()}');
    }
  }
  
  @override
  Future<Floor?> getFloorByNumber(String towerId, int floorNumber) async {
    try {
      return await _localDataSource.getFloorByNumber(towerId, floorNumber);
    } catch (e) {
      throw Exception('Failed to get floor by number: ${e.toString()}');
    }
  }
  
  @override
  Future<Floor> createFloor(Floor floor) async {
    try {
      final localFloor = floor.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveFloor(localFloor);
      
      try {
        final dto = localFloor.toDto();
        final remoteDto = await _remoteDataSource.createFloor(dto);
        
        final syncedFloor = localFloor.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
        );
        
        await _localDataSource.saveFloor(syncedFloor);
        return syncedFloor;
      } catch (e) {
        return localFloor;
      }
    } catch (e) {
      throw Exception('Failed to create floor: ${e.toString()}');
    }
  }
  
  @override
  Future<Floor> updateFloor(Floor floor) async {
    try {
      final updatedFloor = floor.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveFloor(updatedFloor);
      
      if (floor.remoteId != null) {
        try {
          final dto = updatedFloor.toDto();
          await _remoteDataSource.updateFloor(floor.remoteId!, dto);
        } catch (e) {
          // Will sync later
        }
      }
      
      return updatedFloor;
    } catch (e) {
      throw Exception('Failed to update floor: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteFloor(String id) async {
    try {
      final floor = await _localDataSource.getFloorById(id);
      if (floor == null) return;
      
      await _localDataSource.deleteFloor(id);
      
      if (floor.remoteId != null) {
        try {
          await _remoteDataSource.deleteFloor(floor.remoteId!);
        } catch (e) {
          // Will sync later
        }
      }
    } catch (e) {
      throw Exception('Failed to delete floor: ${e.toString()}');
    }
  }
  
  // ===== Suite Operations =====
  
  @override
  Future<List<Suite>> getSuitesByFloorId(String floorId) async {
    try {
      return await _localDataSource.getSuitesByFloorId(floorId);
    } catch (e) {
      throw Exception('Failed to get suites by floor id: ${e.toString()}');
    }
  }
  
  @override
  Future<Suite?> getSuiteById(String id) async {
    try {
      return await _localDataSource.getSuiteById(id);
    } catch (e) {
      throw Exception('Failed to get suite by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> searchSuites({
    String? query,
    int? minBedrooms,
    int? maxBedrooms,
    double? minArea,
    double? maxArea,
    double? minPrice,
    double? maxPrice,
    String? status,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (query != null) filters['query'] = query;
      if (minBedrooms != null) filters['minBedrooms'] = minBedrooms;
      if (maxBedrooms != null) filters['maxBedrooms'] = maxBedrooms;
      if (minArea != null) filters['minArea'] = minArea;
      if (maxArea != null) filters['maxArea'] = maxArea;
      if (minPrice != null) filters['minPrice'] = minPrice;
      if (maxPrice != null) filters['maxPrice'] = maxPrice;
      if (status != null) filters['status'] = status;
      
      return await _localDataSource.searchSuites(filters);
    } catch (e) {
      throw Exception('Failed to search suites: ${e.toString()}');
    }
  }
  
  @override
  Future<Suite> createSuite(Suite suite) async {
    try {
      final localSuite = suite.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveSuite(localSuite);
      
      try {
        final dto = localSuite.toDto();
        final remoteDto = await _remoteDataSource.createSuite(dto);
        
        final syncedSuite = localSuite.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
        );
        
        await _localDataSource.saveSuite(syncedSuite);
        return syncedSuite;
      } catch (e) {
        return localSuite;
      }
    } catch (e) {
      throw Exception('Failed to create suite: ${e.toString()}');
    }
  }
  
  @override
  Future<Suite> updateSuite(Suite suite) async {
    try {
      final updatedSuite = suite.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveSuite(updatedSuite);
      
      if (suite.remoteId != null) {
        try {
          final dto = updatedSuite.toDto();
          await _remoteDataSource.updateSuite(suite.remoteId!, dto);
        } catch (e) {
          // Will sync later
        }
      }
      
      return updatedSuite;
    } catch (e) {
      throw Exception('Failed to update suite: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateSuiteStatus(String id, String status) async {
    try {
      final suite = await _localDataSource.getSuiteById(id);
      if (suite != null) {
        final updatedSuite = suite.copyWith(
          status: _parseStatus(status),
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.saveSuite(updatedSuite);
        
        if (suite.remoteId != null) {
          try {
            await _remoteDataSource.updateSuiteStatus(suite.remoteId!, status);
          } catch (e) {
            // Will sync later
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update suite status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteSuite(String id) async {
    try {
      final suite = await _localDataSource.getSuiteById(id);
      if (suite == null) return;
      
      await _localDataSource.deleteSuite(id);
      
      if (suite.remoteId != null) {
        try {
          await _remoteDataSource.deleteSuite(suite.remoteId!);
        } catch (e) {
          // Will sync later
        }
      }
    } catch (e) {
      throw Exception('Failed to delete suite: ${e.toString()}');
    }
  }
  
  // ===== Local Operations =====
  
  @override
  Future<List<Tower>> getByMenuIdLocal(String menuLocalId) async {
    try {
      return await _localDataSource.getTowersByMenuId(menuLocalId);
    } catch (e) {
      throw Exception('Failed to get towers by menu id local: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveTowerLocal(Tower tower) async {
    try {
      await _localDataSource.saveTower(tower);
    } catch (e) {
      throw Exception('Failed to save tower local: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveFloorsLocal(List<Floor> floors) async {
    try {
      await _localDataSource.saveFloors(floors);
    } catch (e) {
      throw Exception('Failed to save floors local: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveSuitesLocal(List<Suite> suites) async {
    try {
      await _localDataSource.saveSuites(suites);
    } catch (e) {
      throw Exception('Failed to save suites local: ${e.toString()}');
    }
  }
  
  // ===== Favorites =====
  
  @override
  Future<void> toggleFavorite(String suiteLocalId) async {
    try {
      await _localDataSource.toggleFavorite(suiteLocalId);
    } catch (e) {
      throw Exception('Failed to toggle favorite: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getFavorites() async {
    try {
      return await _localDataSource.getFavorites();
    } catch (e) {
      throw Exception('Failed to get favorites: ${e.toString()}');
    }
  }
  
  // ===== Sync Operations =====
  
  @override
  Future<void> syncTowersWithRemote(String menuId) async {
    try {
      // Sync towers
      final remoteTowers = await _remoteDataSource.getTowersByMenuId(menuId);
      final localTowers = remoteTowers.map((dto) => dto.toEntity(_uuid.v7())).toList();
      await _localDataSource.saveTowers(localTowers);
      
      // Sync floors and suites for each tower
      for (final tower in localTowers) {
        if (tower.remoteId != null) {
          // Sync floors
          final remoteFloors = await _remoteDataSource.getFloorsByTowerId(tower.remoteId!);
          final localFloors = remoteFloors.map((dto) => dto.toEntity(_uuid.v7())).toList();
          await _localDataSource.saveFloors(localFloors);
          
          // Sync suites for each floor
          for (final floor in localFloors) {
            if (floor.remoteId != null) {
              final remoteSuites = await _remoteDataSource.getSuitesByFloorId(floor.remoteId!);
              final localSuites = remoteSuites.map((dto) => dto.toEntity(_uuid.v7())).toList();
              await _localDataSource.saveSuites(localSuites);
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to sync towers with remote: ${e.toString()}');
    }
  }
  
  @override
  Stream<List<Tower>> watchTowersByMenuId(String menuLocalId) {
    // This would typically use a stream controller or reactive storage
    // For now, return a simple stream that emits once
    return Stream.fromFuture(getByMenuIdLocal(menuLocalId));
  }

  // Helper method to parse status string to enum
  SuiteStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return SuiteStatus.available;
      case 'reserved':
        return SuiteStatus.reserved;
      case 'sold':
        return SuiteStatus.sold;
      case 'blocked':
        return SuiteStatus.blocked;
      default:
        return SuiteStatus.available;
    }
  }
}