import '../../domain/entities/floor.dart';
import '../../domain/entities/suite.dart';
import '../../domain/repositories/floor_repository.dart';
import '../datasources/local/tower_local_datasource.dart';
import '../datasources/remote/tower_remote_datasource.dart';
import '../models/floor_dto.dart';
import 'package:uuid/uuid.dart';

class FloorRepositoryImpl implements FloorRepository {
  final TowerLocalDataSource _localDataSource;
  final TowerRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  FloorRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<Floor> create(Floor floor) async {
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
          lastModifiedAt: DateTime.now(),
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
  Future<Floor> update(Floor floor) async {
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
          
          final syncedFloor = updatedFloor.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.saveFloor(syncedFloor);
          return syncedFloor;
        } catch (e) {
          return updatedFloor;
        }
      }
      
      return updatedFloor;
    } catch (e) {
      throw Exception('Failed to update floor: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final floor = await _localDataSource.getFloorById(localId);
      if (floor == null) return;
      
      final deletedFloor = floor.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveFloor(deletedFloor);
      
      if (floor.remoteId != null) {
        try {
          await _remoteDataSource.deleteFloor(floor.remoteId!);
          await _localDataSource.deleteFloor(localId);
        } catch (e) {
          // Keep soft delete for later sync
        }
      }
    } catch (e) {
      throw Exception('Failed to delete floor: ${e.toString()}');
    }
  }
  
  @override
  Future<Floor?> getById(String localId) async {
    try {
      return await _localDataSource.getFloorById(localId);
    } catch (e) {
      throw Exception('Failed to get floor by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Floor>> getAll() async {
    try {
      return await _localDataSource.getModifiedFloors();
    } catch (e) {
      throw Exception('Failed to get all floors: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Floor>> getByTowerId(String towerLocalId) async {
    try {
      return await _localDataSource.getFloorsByTowerId(towerLocalId);
    } catch (e) {
      throw Exception('Failed to get floors by tower id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Floor>> getActive() async {
    try {
      final floors = await _localDataSource.getModifiedFloors();
      return floors.where((floor) => floor.isActive && floor.deletedAt == null).toList();
    } catch (e) {
      throw Exception('Failed to get active floors: ${e.toString()}');
    }
  }
  
  @override
  Future<Floor?> getByNumber(String towerLocalId, int floorNumber) async {
    try {
      return await _localDataSource.getFloorByNumber(towerLocalId, floorNumber);
    } catch (e) {
      throw Exception('Failed to get floor by number: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Floor>> getAvailable() async {
    try {
      final floors = await _localDataSource.getModifiedFloors();
      return floors.where((floor) => 
        floor.isActive && 
        floor.deletedAt == null &&
        floor.isAvailable
      ).toList();
    } catch (e) {
      throw Exception('Failed to get available floors: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      // This would typically get all floors from remote
      // For now, we'll just get modified floors that need sync
      final modifiedFloors = await _localDataSource.getModifiedFloors();
      
      for (final floor in modifiedFloors) {
        if (floor.remoteId != null) {
          try {
            final remoteDto = await _remoteDataSource.getFloorById(floor.remoteId!);
            final updatedFloor = remoteDto.toEntity(_uuid.v7());
            await _localDataSource.saveFloor(updatedFloor);
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote() async {
    try {
      final modifiedFloors = await _localDataSource.getModifiedFloors();
      
      for (final floor in modifiedFloors) {
        try {
          final dto = floor.toDto();
          
          if (floor.remoteId == null) {
            final remoteDto = await _remoteDataSource.createFloor(dto);
            final syncedFloor = floor.copyWith(
              remoteId: remoteDto.id,
              isModified: false,
            );
            await _localDataSource.saveFloor(syncedFloor);
          } else {
            await _remoteDataSource.updateFloor(floor.remoteId!, dto);
            final syncedFloor = floor.copyWith(isModified: false);
            await _localDataSource.saveFloor(syncedFloor);
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
  Future<List<Floor>> getModified() async {
    try {
      return await _localDataSource.getModifiedFloors();
    } catch (e) {
      throw Exception('Failed to get modified floors: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local floors: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.deleteFloor(localId);
    } catch (e) {
      throw Exception('Failed to delete local floor: ${e.toString()}');
    }
  }
  
  @override
  Future<int> getTotalFloors(String towerLocalId) async {
    try {
      final floors = await _localDataSource.getFloorsByTowerId(towerLocalId);
      return floors.where((floor) => floor.deletedAt == null).length;
    } catch (e) {
      throw Exception('Failed to get total floors: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Floor>> getFloorRange(String towerLocalId, int startFloor, int endFloor) async {
    try {
      final floors = await _localDataSource.getFloorsByTowerId(towerLocalId);
      return floors.where((floor) => 
        floor.deletedAt == null &&
        floor.floorNumber >= startFloor &&
        floor.floorNumber <= endFloor
      ).toList()
      ..sort((a, b) => a.floorNumber.compareTo(b.floorNumber));
    } catch (e) {
      throw Exception('Failed to get floor range: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> hasAvailableSuites(String floorLocalId) async {
    try {
      final suites = await _localDataSource.getSuitesByFloorId(floorLocalId);
      return suites.any((suite) => 
        suite.deletedAt == null &&
        suite.status == SuiteStatus.available
      );
    } catch (e) {
      return false;
    }
  }
}