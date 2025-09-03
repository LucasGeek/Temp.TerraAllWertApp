import '../../../infra/http/rest_client.dart';
import '../../models/menu_dto.dart';

abstract class MenuRemoteDataSource {
  Future<List<MenuDto>> getByEnterpriseId(String enterpriseId);
  Future<List<MenuDto>> getHierarchy(String enterpriseId);
  Future<MenuDto> getById(String id);
  Future<List<MenuDto>> getChildren(String parentId);
  Future<MenuDto> create(MenuDto menu);
  Future<MenuDto> update(String id, MenuDto menu);
  Future<void> updatePosition(String id, int position);
  Future<void> delete(String id);
}

class MenuRemoteDataSourceImpl implements MenuRemoteDataSource {
  final RestClient _client;
  
  MenuRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<MenuDto>> getByEnterpriseId(String enterpriseId) async {
    try {
      final response = await _client.get('/enterprises/$enterpriseId/menus');
      final List<dynamic> data = response.data;
      return data.map((json) => MenuDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get menus: ${e.toString()}');
    }
  }
  
  @override
  Future<List<MenuDto>> getHierarchy(String enterpriseId) async {
    try {
      final response = await _client.get('/enterprises/$enterpriseId/menus/hierarchy');
      final List<dynamic> data = response.data;
      return data.map((json) => MenuDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get menu hierarchy: ${e.toString()}');
    }
  }
  
  @override
  Future<MenuDto> getById(String id) async {
    try {
      final response = await _client.get('/menus/$id');
      return MenuDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get menu: ${e.toString()}');
    }
  }
  
  @override
  Future<List<MenuDto>> getChildren(String parentId) async {
    try {
      final response = await _client.get('/menus/$parentId/children');
      final List<dynamic> data = response.data;
      return data.map((json) => MenuDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get menu children: ${e.toString()}');
    }
  }
  
  @override
  Future<MenuDto> create(MenuDto menu) async {
    try {
      final response = await _client.post(
        '/menus',
        data: menu.toJson(),
      );
      return MenuDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create menu: ${e.toString()}');
    }
  }
  
  @override
  Future<MenuDto> update(String id, MenuDto menu) async {
    try {
      final response = await _client.put(
        '/menus/$id',
        data: menu.toJson(),
      );
      return MenuDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update menu: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updatePosition(String id, int position) async {
    try {
      await _client.put(
        '/menus/$id/position',
        data: {'position': position},
      );
    } catch (e) {
      throw Exception('Failed to update menu position: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/menus/$id');
    } catch (e) {
      throw Exception('Failed to delete menu: ${e.toString()}');
    }
  }
}