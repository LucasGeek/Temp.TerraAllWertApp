import '../../domain/entities/pin_marker.dart';
import '../../domain/repositories/pin_marker_repository.dart';
import '../datasources/local/pin_marker_local_datasource.dart';
import '../datasources/remote/pin_marker_remote_datasource.dart';
import '../models/pin_marker_dto.dart';
import 'package:uuid/uuid.dart';

class PinMarkerRepositoryImpl implements PinMarkerRepository {
  final PinMarkerLocalDataSource _localDataSource;
  final PinMarkerRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();
  
  PinMarkerRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<PinMarker> create(PinMarker marker) async {
    try {
      final localMarker = marker.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localMarker);
      
      try {
        final dto = localMarker.toDto();
        final remoteDto = await _remoteDataSource.create(dto);
        
        final syncedMarker = localMarker.copyWith(
          remoteId: remoteDto.id,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        
        await _localDataSource.save(syncedMarker);
        return syncedMarker;
      } catch (e) {
        return localMarker;
      }
    } catch (e) {
      throw Exception('Failed to create pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<PinMarker> update(PinMarker marker) async {
    try {
      final updatedMarker = marker.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedMarker);
      
      if (marker.remoteId != null) {
        try {
          final dto = updatedMarker.toDto();
          await _remoteDataSource.update(marker.remoteId!, dto);
          
          final syncedMarker = updatedMarker.copyWith(
            isModified: false,
            lastModifiedAt: DateTime.now(),
          );
          
          await _localDataSource.save(syncedMarker);
          return syncedMarker;
        } catch (e) {
          return updatedMarker;
        }
      }
      
      return updatedMarker;
    } catch (e) {
      throw Exception('Failed to update pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final marker = await _localDataSource.getById(localId);
      if (marker == null) return;
      
      final deletedMarker = marker.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(deletedMarker);
      
      if (marker.remoteId != null) {
        try {
          await _remoteDataSource.delete(marker.remoteId!);
          await _localDataSource.delete(localId);
        } catch (e) {
          // Keep soft delete for later sync
        }
      }
    } catch (e) {
      throw Exception('Failed to delete pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<PinMarker?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get pin marker by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all pin markers: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getByFloorId(String floorLocalId) async {
    try {
      return await _localDataSource.getByFloorId(floorLocalId);
    } catch (e) {
      throw Exception('Failed to get pin markers by floor: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getBySuiteId(String suiteLocalId) async {
    try {
      return await _localDataSource.getBySuiteId(suiteLocalId);
    } catch (e) {
      throw Exception('Failed to get pin markers by suite: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getActive() async {
    try {
      final markers = await _localDataSource.getAll();
      return markers.where((marker) => marker.isActive && marker.deletedAt == null).toList();
    } catch (e) {
      throw Exception('Failed to get active pin markers: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getInArea(double minX, double minY, double maxX, double maxY) async {
    try {
      return await _localDataSource.getInArea(minX, minY, maxX, maxY);
    } catch (e) {
      throw Exception('Failed to get pin markers in area: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updatePosition(String localId, double x, double y) async {
    try {
      final marker = await _localDataSource.getById(localId);
      if (marker != null) {
        final updatedMarker = marker.copyWith(
          x: x,
          y: y,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(updatedMarker);
        
        // Try to sync position with remote
        if (marker.remoteId != null) {
          try {
            await _remoteDataSource.updatePosition(marker.remoteId!, x, y);
          } catch (e) {
            // Will sync later
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update pin marker position: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarker>> getNearbyMarkers(double x, double y, double radius) async {
    try {
      final markers = await _localDataSource.getAll();
      return markers.where((marker) => 
        marker.deletedAt == null &&
        _calculateDistance(x, y, marker.x, marker.y) <= radius
      ).toList();
    } catch (e) {
      throw Exception('Failed to get nearby pin markers: ${e.toString()}');
    }
  }
  
  double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return (dx * dx + dy * dy).abs(); // Simplified distance calculation
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      final remoteDtos = await _remoteDataSource.getAll();
      final localMarkers = <PinMarker>[];
      
      for (final dto in remoteDtos) {
        final localMarker = dto.toEntity(_uuid.v7());
        localMarkers.add(localMarker);
      }
      
      await _localDataSource.saveAll(localMarkers);
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote() async {
    try {
      final modifiedMarkers = await _localDataSource.getModified();
      
      for (final marker in modifiedMarkers) {
        try {
          final dto = marker.toDto();
          
          if (marker.remoteId == null) {
            final remoteDto = await _remoteDataSource.create(dto);
            await _localDataSource.updateSyncStatus(marker.localId, remoteDto.id);
          } else {
            await _remoteDataSource.update(marker.remoteId!, dto);
            await _localDataSource.updateSyncStatus(marker.localId, marker.remoteId!);
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
  Future<List<PinMarker>> getModified() async {
    try {
      return await _localDataSource.getModified();
    } catch (e) {
      throw Exception('Failed to get modified pin markers: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local pin markers: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local pin marker: ${e.toString()}');
    }
  }
}