import '../../domain/entities/suite.dart';
import '../../domain/repositories/suite_repository.dart';
import '../datasources/local/tower_local_datasource.dart';
import '../datasources/remote/tower_remote_datasource.dart';
import '../models/suite_dto.dart';
import 'package:uuid/uuid.dart';

class SuiteRepositoryImpl implements SuiteRepository {
  final TowerLocalDataSource _localDataSource;
  final TowerRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  SuiteRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<Suite> create(Suite suite) async {
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
          lastModifiedAt: DateTime.now(),
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
  Future<Suite> update(Suite suite) async {
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
          
          final syncedSuite = updatedSuite.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.saveSuite(syncedSuite);
          return syncedSuite;
        } catch (e) {
          return updatedSuite;
        }
      }
      
      return updatedSuite;
    } catch (e) {
      throw Exception('Failed to update suite: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final suite = await _localDataSource.getSuiteById(localId);
      if (suite == null) return;
      
      final deletedSuite = suite.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.saveSuite(deletedSuite);
      
      if (suite.remoteId != null) {
        try {
          await _remoteDataSource.deleteSuite(suite.remoteId!);
          await _localDataSource.deleteSuite(localId);
        } catch (e) {
          // Keep soft delete for later sync
        }
      }
    } catch (e) {
      throw Exception('Failed to delete suite: ${e.toString()}');
    }
  }
  
  @override
  Future<Suite?> getById(String localId) async {
    try {
      return await _localDataSource.getSuiteById(localId);
    } catch (e) {
      throw Exception('Failed to get suite by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getAll() async {
    try {
      return await _localDataSource.getModifiedSuites();
    } catch (e) {
      throw Exception('Failed to get all suites: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getByFloorId(String floorLocalId) async {
    try {
      return await _localDataSource.getSuitesByFloorId(floorLocalId);
    } catch (e) {
      throw Exception('Failed to get suites by floor id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getByTowerId(String towerLocalId) async {
    try {
      // Get all floors for the tower first
      final floors = await _localDataSource.getFloorsByTowerId(towerLocalId);
      final List<Suite> allSuites = [];
      
      for (final floor in floors) {
        final suites = await _localDataSource.getSuitesByFloorId(floor.localId);
        allSuites.addAll(suites);
      }
      
      return allSuites.where((suite) => suite.deletedAt == null).toList();
    } catch (e) {
      throw Exception('Failed to get suites by tower id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getAvailable() async {
    try {
      final suites = await _localDataSource.getModifiedSuites();
      return suites.where((suite) => 
        suite.deletedAt == null &&
        suite.status == SuiteStatus.available
      ).toList();
    } catch (e) {
      throw Exception('Failed to get available suites: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getSold() async {
    try {
      final suites = await _localDataSource.getModifiedSuites();
      return suites.where((suite) => 
        suite.deletedAt == null &&
        suite.status == SuiteStatus.sold
      ).toList();
    } catch (e) {
      throw Exception('Failed to get sold suites: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getReserved() async {
    try {
      final suites = await _localDataSource.getModifiedSuites();
      return suites.where((suite) => 
        suite.deletedAt == null &&
        suite.status == SuiteStatus.reserved
      ).toList();
    } catch (e) {
      throw Exception('Failed to get reserved suites: ${e.toString()}');
    }
  }
  
  @override
  Future<Suite?> getBySuiteNumber(String floorLocalId, String suiteNumber) async {
    try {
      final suites = await _localDataSource.getSuitesByFloorId(floorLocalId);
      try {
        return suites.firstWhere((suite) => 
          suite.unitNumber == suiteNumber && 
          suite.deletedAt == null
        );
      } catch (_) {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to get suite by number: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      // This would typically get all suites from remote
      // For now, we'll just get modified suites that need sync
      final modifiedSuites = await _localDataSource.getModifiedSuites();
      
      for (final suite in modifiedSuites) {
        if (suite.remoteId != null) {
          try {
            final remoteDto = await _remoteDataSource.getSuiteById(suite.remoteId!);
            final updatedSuite = remoteDto.toEntity(_uuid.v7());
            await _localDataSource.saveSuite(updatedSuite);
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
      final modifiedSuites = await _localDataSource.getModifiedSuites();
      
      for (final suite in modifiedSuites) {
        try {
          final dto = suite.toDto();
          
          if (suite.remoteId == null) {
            final remoteDto = await _remoteDataSource.createSuite(dto);
            final syncedSuite = suite.copyWith(
              remoteId: remoteDto.id,
              isModified: false,
            );
            await _localDataSource.saveSuite(syncedSuite);
          } else {
            await _remoteDataSource.updateSuite(suite.remoteId!, dto);
            final syncedSuite = suite.copyWith(isModified: false);
            await _localDataSource.saveSuite(syncedSuite);
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
  Future<List<Suite>> getModified() async {
    try {
      return await _localDataSource.getModifiedSuites();
    } catch (e) {
      throw Exception('Failed to get modified suites: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local suites: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.deleteSuite(localId);
    } catch (e) {
      throw Exception('Failed to delete local suite: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> searchSuites(String query) async {
    try {
      final filters = {'query': query};
      return await _localDataSource.searchSuites(filters);
    } catch (e) {
      throw Exception('Failed to search suites: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getByPriceRange(double minPrice, double maxPrice) async {
    try {
      final filters = {
        'minPrice': minPrice,
        'maxPrice': maxPrice,
      };
      return await _localDataSource.searchSuites(filters);
    } catch (e) {
      throw Exception('Failed to get suites by price range: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getByAreaRange(double minArea, double maxArea) async {
    try {
      final filters = {
        'minArea': minArea,
        'maxArea': maxArea,
      };
      return await _localDataSource.searchSuites(filters);
    } catch (e) {
      throw Exception('Failed to get suites by area range: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Suite>> getByRooms(int bedrooms, int bathrooms) async {
    try {
      final filters = {
        'minBedrooms': bedrooms,
        'maxBedrooms': bedrooms,
        'bathrooms': bathrooms,
      };
      return await _localDataSource.searchSuites(filters);
    } catch (e) {
      throw Exception('Failed to get suites by rooms: ${e.toString()}');
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
}