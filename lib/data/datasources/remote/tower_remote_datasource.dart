import '../../../infra/http/rest_client.dart';
import '../../models/tower_dto.dart';
import '../../models/floor_dto.dart';
import '../../models/suite_dto.dart';

abstract class TowerRemoteDataSource {
  // Tower operations
  Future<List<TowerDto>> getTowersByMenuId(String menuId);
  Future<TowerDto> getTowerById(String id);
  Future<TowerDto> createTower(TowerDto tower);
  Future<TowerDto> updateTower(String id, TowerDto tower);
  Future<void> updateTowerPosition(String id, int position);
  Future<void> deleteTower(String id);
  
  // Floor operations
  Future<List<FloorDto>> getFloorsByTowerId(String towerId);
  Future<FloorDto> getFloorById(String id);
  Future<FloorDto?> getFloorByNumber(String towerId, int floorNumber);
  Future<FloorDto> createFloor(FloorDto floor);
  Future<FloorDto> updateFloor(String id, FloorDto floor);
  Future<void> deleteFloor(String id);
  
  // Suite operations
  Future<List<SuiteDto>> getSuitesByFloorId(String floorId);
  Future<SuiteDto> getSuiteById(String id);
  Future<List<SuiteDto>> searchSuites(Map<String, dynamic> filters);
  Future<SuiteDto> createSuite(SuiteDto suite);
  Future<SuiteDto> updateSuite(String id, SuiteDto suite);
  Future<void> updateSuiteStatus(String id, String status);
  Future<void> deleteSuite(String id);
}

class TowerRemoteDataSourceImpl implements TowerRemoteDataSource {
  final RestClient _client;
  
  TowerRemoteDataSourceImpl(this._client);
  
  // ===== Tower Operations =====
  
  @override
  Future<List<TowerDto>> getTowersByMenuId(String menuId) async {
    try {
      final response = await _client.get('/menu-floor-plans/$menuId/towers');
      final List<dynamic> data = response.data;
      return data.map((json) => TowerDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get towers: ${e.toString()}');
    }
  }
  
  @override
  Future<TowerDto> getTowerById(String id) async {
    try {
      final response = await _client.get('/towers/$id');
      return TowerDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get tower: ${e.toString()}');
    }
  }
  
  @override
  Future<TowerDto> createTower(TowerDto tower) async {
    try {
      final response = await _client.post(
        '/towers',
        data: tower.toJson(),
      );
      return TowerDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create tower: ${e.toString()}');
    }
  }
  
  @override
  Future<TowerDto> updateTower(String id, TowerDto tower) async {
    try {
      final response = await _client.put(
        '/towers/$id',
        data: tower.toJson(),
      );
      return TowerDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update tower: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateTowerPosition(String id, int position) async {
    try {
      await _client.put(
        '/towers/$id/position',
        data: {'position': position},
      );
    } catch (e) {
      throw Exception('Failed to update tower position: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteTower(String id) async {
    try {
      await _client.delete('/towers/$id');
    } catch (e) {
      throw Exception('Failed to delete tower: ${e.toString()}');
    }
  }
  
  // ===== Floor Operations =====
  
  @override
  Future<List<FloorDto>> getFloorsByTowerId(String towerId) async {
    try {
      final response = await _client.get('/towers/$towerId/floors');
      final List<dynamic> data = response.data;
      return data.map((json) => FloorDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get floors: ${e.toString()}');
    }
  }
  
  @override
  Future<FloorDto> getFloorById(String id) async {
    try {
      final response = await _client.get('/floors/$id');
      return FloorDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get floor: ${e.toString()}');
    }
  }
  
  @override
  Future<FloorDto?> getFloorByNumber(String towerId, int floorNumber) async {
    try {
      final response = await _client.get('/towers/$towerId/floors/$floorNumber');
      return FloorDto.fromJson(response.data);
    } catch (e) {
      // Floor not found is acceptable
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Failed to get floor by number: ${e.toString()}');
    }
  }
  
  @override
  Future<FloorDto> createFloor(FloorDto floor) async {
    try {
      final response = await _client.post(
        '/floors',
        data: floor.toJson(),
      );
      return FloorDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create floor: ${e.toString()}');
    }
  }
  
  @override
  Future<FloorDto> updateFloor(String id, FloorDto floor) async {
    try {
      final response = await _client.put(
        '/floors/$id',
        data: floor.toJson(),
      );
      return FloorDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update floor: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteFloor(String id) async {
    try {
      await _client.delete('/floors/$id');
    } catch (e) {
      throw Exception('Failed to delete floor: ${e.toString()}');
    }
  }
  
  // ===== Suite Operations =====
  
  @override
  Future<List<SuiteDto>> getSuitesByFloorId(String floorId) async {
    try {
      final response = await _client.get('/floors/$floorId/suites');
      final List<dynamic> data = response.data;
      return data.map((json) => SuiteDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get suites: ${e.toString()}');
    }
  }
  
  @override
  Future<SuiteDto> getSuiteById(String id) async {
    try {
      final response = await _client.get('/suites/$id');
      return SuiteDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get suite: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SuiteDto>> searchSuites(Map<String, dynamic> filters) async {
    try {
      final response = await _client.get(
        '/suites/search',
        queryParameters: filters,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => SuiteDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search suites: ${e.toString()}');
    }
  }
  
  @override
  Future<SuiteDto> createSuite(SuiteDto suite) async {
    try {
      final response = await _client.post(
        '/suites',
        data: suite.toJson(),
      );
      return SuiteDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create suite: ${e.toString()}');
    }
  }
  
  @override
  Future<SuiteDto> updateSuite(String id, SuiteDto suite) async {
    try {
      final response = await _client.put(
        '/suites/$id',
        data: suite.toJson(),
      );
      return SuiteDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update suite: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateSuiteStatus(String id, String status) async {
    try {
      await _client.put(
        '/suites/$id/status',
        data: {'status': status},
      );
    } catch (e) {
      throw Exception('Failed to update suite status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteSuite(String id) async {
    try {
      await _client.delete('/suites/$id');
    } catch (e) {
      throw Exception('Failed to delete suite: ${e.toString()}');
    }
  }
}