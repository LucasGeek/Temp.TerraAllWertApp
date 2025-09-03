import '../../../infra/http/rest_client.dart';
import '../../models/pin_marker_dto.dart';

abstract class PinMarkerRemoteDataSource {
  Future<List<PinMarkerDto>> getAll();
  Future<List<PinMarkerDto>> getByMenuId(String menuId);
  Future<PinMarkerDto> getById(String id);
  Future<PinMarkerDto> create(PinMarkerDto marker);
  Future<PinMarkerDto> update(String id, PinMarkerDto marker);
  Future<void> delete(String id);
  Future<void> updatePosition(String id, double x, double y);
}

class PinMarkerRemoteDataSourceImpl implements PinMarkerRemoteDataSource {
  final RestClient _client;
  
  PinMarkerRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<PinMarkerDto>> getAll() async {
    try {
      final response = await _client.get('/pin-markers');
      final List<dynamic> data = response.data;
      return data.map((json) => PinMarkerDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pin markers: ${e.toString()}');
    }
  }
  
  @override
  Future<List<PinMarkerDto>> getByMenuId(String menuId) async {
    try {
      final response = await _client.get('/pin-markers/menu/$menuId');
      final List<dynamic> data = response.data;
      return data.map((json) => PinMarkerDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pin markers by menu: ${e.toString()}');
    }
  }
  
  @override
  Future<PinMarkerDto> getById(String id) async {
    try {
      final response = await _client.get('/pin-markers/$id');
      return PinMarkerDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<PinMarkerDto> create(PinMarkerDto marker) async {
    try {
      final response = await _client.post(
        '/pin-markers',
        data: marker.toJson(),
      );
      return PinMarkerDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<PinMarkerDto> update(String id, PinMarkerDto marker) async {
    try {
      final response = await _client.put(
        '/pin-markers/$id',
        data: marker.toJson(),
      );
      return PinMarkerDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/pin-markers/$id');
    } catch (e) {
      throw Exception('Failed to delete pin marker: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updatePosition(String id, double x, double y) async {
    try {
      await _client.put(
        '/pin-markers/$id/position',
        data: {'x': x, 'y': y},
      );
    } catch (e) {
      throw Exception('Failed to update pin marker position: ${e.toString()}');
    }
  }
}