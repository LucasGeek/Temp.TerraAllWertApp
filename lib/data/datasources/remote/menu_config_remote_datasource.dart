import '../../../infra/http/rest_client.dart';

abstract class MenuConfigRemoteDataSource {
  Future<Map<String, dynamic>?> getConfig(String menuId);
  Future<Map<String, dynamic>> updateConfig(String menuId, Map<String, dynamic> config);
  Future<void> resetConfig(String menuId);
  Future<List<Map<String, dynamic>>> getAllConfigs();
  Future<Map<String, dynamic>> getDefaultConfig();
}

class MenuConfigRemoteDataSourceImpl implements MenuConfigRemoteDataSource {
  final RestClient _client;
  
  MenuConfigRemoteDataSourceImpl(this._client);
  
  @override
  Future<Map<String, dynamic>?> getConfig(String menuId) async {
    try {
      final response = await _client.get('/menu-config/$menuId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      // Return null if config not found (404)
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Failed to get menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> updateConfig(String menuId, Map<String, dynamic> config) async {
    try {
      final response = await _client.put(
        '/menu-config/$menuId',
        data: config,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to update menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<void> resetConfig(String menuId) async {
    try {
      await _client.delete('/menu-config/$menuId');
    } catch (e) {
      throw Exception('Failed to reset menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getAllConfigs() async {
    try {
      final response = await _client.get('/menu-config');
      final List<dynamic> data = response.data;
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw Exception('Failed to get all menu configs: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDefaultConfig() async {
    try {
      final response = await _client.get('/menu-config/default');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      // Return default values if not found
      return {
        'theme': 'light',
        'layout': 'grid',
        'displayOptions': {
          'showThumbnails': true,
          'showDescriptions': true,
          'showPrices': true,
        },
        'navigationConfig': {
          'enableSwipeNavigation': true,
          'showNavigationDots': true,
          'autoAdvanceTime': 5000,
        },
      };
    }
  }
}