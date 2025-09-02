import 'package:graphql/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/menu_types.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../infra/graphql/queries/menu_queries.dart';
import '../../infra/graphql/mutations/menu_mutations.dart';

abstract class MenuRemoteDataSource {
  Future<List<Menu>> getAllMenus();
  
  Future<Menu?> getMenuById(String id);
  
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela});
  
  Future<List<Menu>> getSubmenus(String menuPaiId);
  
  Future<Menu> createMenu({
    required String title,
    String? description,
    String? icon,
    String? route,
    bool isActive = true,
    required TipoMenu tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  });
  
  Future<Menu> updateMenu(String id, {
    String? title,
    String? description,
    String? icon,
    String? route,
    bool? isActive,
    TipoMenu? tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  });
  
  Future<bool> deleteMenu(String id);
  
  Future<bool> reorderMenus(List<MenuOrder> orders);
  
  Future<MenuFloor?> getMenuFloor(String menuId);
  
  Future<MenuFloor> updateMenuFloor(String menuId, MenuFloorInput input);
  
  Future<MenuCarousel?> getMenuCarousel(String menuId);
  
  Future<MenuCarousel> updateMenuCarousel(String menuId, MenuCarouselInput input);
  
  Future<MenuPin?> getMenuPin(String menuId);
  
  Future<MenuPin> updateMenuPin(String menuId, MenuPinInput input);
}

class MenuRemoteDataSourceImpl implements MenuRemoteDataSource {
  final GraphQLClient _client;

  MenuRemoteDataSourceImpl(this._client);

  @override
  Future<List<Menu>> getAllMenus() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getAllMenusQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final menusData = result.data?['menus'] as List<dynamic>?;
    if (menusData == null) return [];

    return menusData.map((menuJson) => Menu.fromJson(menuJson)).toList();
  }

  @override
  Future<Menu?> getMenuById(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getMenuByIdQuery),
        variables: {'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final menuData = result.data?['menu'];
    if (menuData == null) return null;

    return Menu.fromJson(menuData);
  }

  @override
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela}) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getMenusByTypeQuery),
        variables: {
          'tipoMenu': tipoMenu.value,
          if (tipoTela != null) 'tipoTela': tipoTela.value,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final menusData = result.data?['menusByType'] as List<dynamic>?;
    if (menusData == null) return [];

    return menusData.map((menuJson) => Menu.fromJson(menuJson)).toList();
  }

  @override
  Future<List<Menu>> getSubmenus(String menuPaiId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getSubmenusQuery),
        variables: {'menuPaiId': menuPaiId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final submenusData = result.data?['submenus'] as List<dynamic>?;
    if (submenusData == null) return [];

    return submenusData.map((menuJson) => Menu.fromJson(menuJson)).toList();
  }

  @override
  Future<Menu> createMenu({
    required String title,
    String? description,
    String? icon,
    String? route,
    bool isActive = true,
    required TipoMenu tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(createMenuMutation),
        variables: {
          'input': {
            'title': title,
            if (description != null) 'description': description,
            if (icon != null) 'icon': icon,
            if (route != null) 'route': route,
            'isActive': isActive,
            'tipoMenu': tipoMenu.value,
            if (tipoTela != null) 'tipoTela': tipoTela.value,
            if (menuPaiId != null) 'menuPaiId': menuPaiId,
            if (posicao != null) 'posicao': posicao,
          },
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Menu.fromJson(result.data!['createMenu']);
  }

  @override
  Future<Menu> updateMenu(String id, {
    String? title,
    String? description,
    String? icon,
    String? route,
    bool? isActive,
    TipoMenu? tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(updateMenuMutation),
        variables: {
          'id': id,
          'input': {
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (icon != null) 'icon': icon,
            if (route != null) 'route': route,
            if (isActive != null) 'isActive': isActive,
            if (tipoMenu != null) 'tipoMenu': tipoMenu.value,
            if (tipoTela != null) 'tipoTela': tipoTela.value,
            if (menuPaiId != null) 'menuPaiId': menuPaiId,
            if (posicao != null) 'posicao': posicao,
          },
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Menu.fromJson(result.data!['updateMenu']);
  }

  @override
  Future<bool> deleteMenu(String id) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(deleteMenuMutation),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data?['deleteMenu']?['success'] == true;
  }

  @override
  Future<bool> reorderMenus(List<MenuOrder> orders) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(reorderMenusMutation),
        variables: {
          'menuOrders': orders.map((order) => {
            'id': order.id,
            'posicao': order.posicao,
          }).toList(),
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data?['reorderMenus']?['success'] == true;
  }

  @override
  Future<MenuFloor?> getMenuFloor(String menuId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getMenuFloorQuery),
        variables: {'menuId': menuId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final floorData = result.data?['menuFloor'];
    if (floorData == null) return null;

    return MenuFloor.fromJson(floorData);
  }

  @override
  Future<MenuFloor> updateMenuFloor(String menuId, MenuFloorInput input) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(updateMenuFloorMutation),
        variables: {
          'menuId': menuId,
          'input': _menuFloorInputToJson(input),
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return MenuFloor.fromJson(result.data!['updateMenuFloor']);
  }

  @override
  Future<MenuCarousel?> getMenuCarousel(String menuId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getMenuCarouselQuery),
        variables: {'menuId': menuId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final carouselData = result.data?['menuCarousel'];
    if (carouselData == null) return null;

    return MenuCarousel.fromJson(carouselData);
  }

  @override
  Future<MenuCarousel> updateMenuCarousel(String menuId, MenuCarouselInput input) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(updateMenuCarouselMutation),
        variables: {
          'menuId': menuId,
          'input': _menuCarouselInputToJson(input),
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return MenuCarousel.fromJson(result.data!['updateMenuCarousel']);
  }

  @override
  Future<MenuPin?> getMenuPin(String menuId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getMenuPinQuery),
        variables: {'menuId': menuId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final pinData = result.data?['menuPin'];
    if (pinData == null) return null;

    return MenuPin.fromJson(pinData);
  }

  @override
  Future<MenuPin> updateMenuPin(String menuId, MenuPinInput input) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(updateMenuPinMutation),
        variables: {
          'menuId': menuId,
          'input': _menuPinInputToJson(input),
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return MenuPin.fromJson(result.data!['updateMenuPin']);
  }

  // Helper methods to convert input classes to JSON
  Map<String, dynamic> _menuFloorInputToJson(MenuFloorInput input) {
    return {
      if (input.layoutJson != null) 'layoutJson': input.layoutJson,
      if (input.zoomDefault != null) 'zoomDefault': input.zoomDefault,
      if (input.allowZoom != null) 'allowZoom': input.allowZoom,
      if (input.showGrid != null) 'showGrid': input.showGrid,
      if (input.gridSize != null) 'gridSize': input.gridSize,
      if (input.backgroundColor != null) 'backgroundColor': input.backgroundColor,
      if (input.floorCount != null) 'floorCount': input.floorCount,
      if (input.defaultFloor != null) 'defaultFloor': input.defaultFloor,
      if (input.floorLabels != null) 'floorLabels': input.floorLabels,
    };
  }

  Map<String, dynamic> _menuCarouselInputToJson(MenuCarouselInput input) {
    return {
      if (input.images != null) 'images': input.images!.map((img) => img.toJson()).toList(),
      if (input.transitionTime != null) 'transitionTime': input.transitionTime,
      if (input.transitionType != null) 'transitionType': input.transitionType,
      if (input.autoPlay != null) 'autoPlay': input.autoPlay,
      if (input.showIndicators != null) 'showIndicators': input.showIndicators,
      if (input.showArrows != null) 'showArrows': input.showArrows,
      if (input.allowSwipe != null) 'allowSwipe': input.allowSwipe,
      if (input.infiniteLoop != null) 'infiniteLoop': input.infiniteLoop,
      if (input.aspectRatio != null) 'aspectRatio': input.aspectRatio,
    };
  }

  Map<String, dynamic> _menuPinInputToJson(MenuPinInput input) {
    return {
      if (input.mapConfig != null) 'mapConfig': input.mapConfig,
      if (input.pinData != null) 'pinData': input.pinData!.map((pin) => pin.toJson()).toList(),
      if (input.backgroundImageUrl != null) 'backgroundImageUrl': input.backgroundImageUrl,
      if (input.mapBounds != null) 'mapBounds': input.mapBounds,
      if (input.initialZoom != null) 'initialZoom': input.initialZoom,
      if (input.minZoom != null) 'minZoom': input.minZoom,
      if (input.maxZoom != null) 'maxZoom': input.maxZoom,
      if (input.enableClustering != null) 'enableClustering': input.enableClustering,
      if (input.clusterRadius != null) 'clusterRadius': input.clusterRadius,
      if (input.pinIconDefault != null) 'pinIconDefault': input.pinIconDefault,
      if (input.showPinLabels != null) 'showPinLabels': input.showPinLabels,
      if (input.enableSearch != null) 'enableSearch': input.enableSearch,
      if (input.enableFilters != null) 'enableFilters': input.enableFilters,
    };
  }
}

// Provider
final menuRemoteDataSourceProvider = Provider<MenuRemoteDataSource>((ref) {
  // TODO: Inject GraphQL client
  throw UnimplementedError('GraphQL client not yet configured for MenuRemoteDataSource');
});