import '../../../infra/http/rest_client.dart';
import '../../models/carousel_item_dto.dart';

abstract class CarouselItemRemoteDataSource {
  Future<List<CarouselItemDto>> getAll();
  Future<List<CarouselItemDto>> getByMenuId(String menuId);
  Future<CarouselItemDto> getById(String id);
  Future<CarouselItemDto> create(CarouselItemDto item);
  Future<CarouselItemDto> update(String id, CarouselItemDto item);
  Future<void> delete(String id);
  Future<void> updatePosition(String id, int position);
}

class CarouselItemRemoteDataSourceImpl implements CarouselItemRemoteDataSource {
  final RestClient _client;
  
  CarouselItemRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<CarouselItemDto>> getAll() async {
    try {
      final response = await _client.get('/carousel-items');
      final List<dynamic> data = response.data;
      return data.map((json) => CarouselItemDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get carousel items: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CarouselItemDto>> getByMenuId(String menuId) async {
    try {
      final response = await _client.get('/carousel-items/menu/$menuId');
      final List<dynamic> data = response.data;
      return data.map((json) => CarouselItemDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get carousel items by menu: ${e.toString()}');
    }
  }
  
  @override
  Future<CarouselItemDto> getById(String id) async {
    try {
      final response = await _client.get('/carousel-items/$id');
      return CarouselItemDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<CarouselItemDto> create(CarouselItemDto item) async {
    try {
      final response = await _client.post(
        '/carousel-items',
        data: item.toJson(),
      );
      return CarouselItemDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<CarouselItemDto> update(String id, CarouselItemDto item) async {
    try {
      final response = await _client.put(
        '/carousel-items/$id',
        data: item.toJson(),
      );
      return CarouselItemDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/carousel-items/$id');
    } catch (e) {
      throw Exception('Failed to delete carousel item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updatePosition(String id, int position) async {
    try {
      await _client.put(
        '/carousel-items/$id/position',
        data: {'position': position},
      );
    } catch (e) {
      throw Exception('Failed to update carousel item position: ${e.toString()}');
    }
  }
}