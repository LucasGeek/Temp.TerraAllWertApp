import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';

import '../../domain/entities/navigation_item.dart';
import '../../domain/enums/menu_presentation_type.dart';
import '../logging/app_logger.dart';
import 'graphql_client.dart';
import 'mutations/menu_mutations.dart';
import 'queries/menu_queries.dart';

/// Serviço GraphQL para operações de menu/navegação
class MenuGraphQLService {
  final GraphQLClient _client;

  MenuGraphQLService(this._client);

  /// Cria um novo menu via GraphQL
  Future<NavigationItem?> createMenu(NavigationItem item) async {
    try {
      AppLogger.info('Creating menu via GraphQL: ${item.label}', tag: 'MenuGraphQL');

      final result = await _client.mutate(
        MutationOptions(
          document: gql(createMenuMutation),
          variables: {
            'input': _navigationItemToGraphQLInput(item),
          },
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL mutation failed: ${result.exception}', tag: 'MenuGraphQL');
        return null;
      }

      final menuResponse = result.data?['createMenu'];
      final data = menuResponse?['menu'];
      if (data != null) {
        AppLogger.info('Menu created successfully via GraphQL: ${data['id']}', tag: 'MenuGraphQL');
        return _graphQLDataToNavigationItem(data);
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to create menu via GraphQL: $e', tag: 'MenuGraphQL');
      return null;
    }
  }

  /// Atualiza um menu via GraphQL
  Future<NavigationItem?> updateMenu(NavigationItem item) async {
    try {
      AppLogger.info('Updating menu via GraphQL: ${item.id}', tag: 'MenuGraphQL');

      final result = await _client.mutate(
        MutationOptions(
          document: gql(updateMenuMutation),
          variables: {
            'input': {
              'menuId': item.id,
              ..._navigationItemToGraphQLInput(item),
            },
          },
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL update failed: ${result.exception}', tag: 'MenuGraphQL');
        return null;
      }

      final menuResponse = result.data?['updateMenu'];
      final data = menuResponse?['menu'];
      if (data != null) {
        AppLogger.info('Menu updated successfully via GraphQL', tag: 'MenuGraphQL');
        return _graphQLDataToNavigationItem(data);
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to update menu via GraphQL: $e', tag: 'MenuGraphQL');
      return null;
    }
  }

  /// Deleta um menu via GraphQL
  Future<bool> deleteMenu(String menuId) async {
    try {
      AppLogger.info('Deleting menu via GraphQL: $menuId', tag: 'MenuGraphQL');

      final result = await _client.mutate(
        MutationOptions(
          document: gql(deleteMenuMutation),
          variables: {'menuId': menuId},
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL delete failed: ${result.exception}', tag: 'MenuGraphQL');
        return false;
      }

      final success = result.data?['deleteMenu']?['success'] ?? false;
      if (success) {
        AppLogger.info('Menu deleted successfully via GraphQL', tag: 'MenuGraphQL');
      }

      return success;
    } catch (e) {
      AppLogger.error('Failed to delete menu via GraphQL: $e', tag: 'MenuGraphQL');
      return false;
    }
  }

  /// Busca menus via GraphQL
  Future<List<NavigationItem>> getMenus({String? userId, String? routeId}) async {
    try {
      AppLogger.debug('Fetching menus via GraphQL', tag: 'MenuGraphQL');

      final result = await _client.query(
        QueryOptions(
          document: gql(getMenusQuery),
          variables: {'routeId': routeId ?? 'main'},
          errorPolicy: ErrorPolicy.all,
          cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL query failed: ${result.exception}', tag: 'MenuGraphQL');
        return [];
      }

      final menusResponse = result.data?['getMenus'];
      final menusList = menusResponse?['menus'] as List<dynamic>?;
      if (menusList != null) {
        final menus = menusList
            .map((item) => _graphQLDataToNavigationItem(item))
            .toList();
        
        AppLogger.info('Fetched ${menus.length} menus via GraphQL', tag: 'MenuGraphQL');
        return menus;
      }

      return [];
    } catch (e) {
      AppLogger.error('Failed to fetch menus via GraphQL: $e', tag: 'MenuGraphQL');
      return [];
    }
  }

  /// Reordena menus via GraphQL
  Future<bool> reorderMenus(List<NavigationItem> items) async {
    try {
      AppLogger.info('Reordering ${items.length} menus via GraphQL', tag: 'MenuGraphQL');

      final menuOrders = items.asMap().entries.map((entry) => {
        'id': entry.value.id,
        'order': entry.key,
      }).toList();

      final result = await _client.mutate(
        MutationOptions(
          document: gql(reorderMenusMutation),
          variables: {
            'input': {
              'menuOrders': menuOrders,
            }
          },
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL reorder failed: ${result.exception}', tag: 'MenuGraphQL');
        return false;
      }

      final success = result.data?['reorderMenus']?['success'] ?? false;
      if (success) {
        AppLogger.info('Menus reordered successfully via GraphQL', tag: 'MenuGraphQL');
      }

      return success;
    } catch (e) {
      AppLogger.error('Failed to reorder menus via GraphQL: $e', tag: 'MenuGraphQL');
      return false;
    }
  }

  /// Converte NavigationItem para input GraphQL
  Map<String, dynamic> _navigationItemToGraphQLInput(NavigationItem item) {
    // Mapear NavigationItem para CreateMenuInput do schema
    // Schema: title!, type!, route!, icon, parentId, order!, permissions, metadata
    final Map<String, dynamic> input = {
      'title': item.label,
      'type': _menuTypeToString(item.menuType),
      'route': item.route,
      'order': item.order,
    };
    
    // Campos opcionais - só adicionar se não nulos
    if (item.description != null || item.isVisible != true || item.isEnabled != true) {
      input['metadata'] = <String, dynamic>{
        if (item.description != null) 'description': item.description,
        'isVisible': item.isVisible,
        'isEnabled': item.isEnabled,
      };
    }
    
    if (_iconToString(item.icon).isNotEmpty) {
      input['icon'] = _iconToString(item.icon);
    }
    
    if (item.parentId != null) {
      input['parentId'] = item.parentId;
    }
    
    if (item.permissions != null && item.permissions!.isNotEmpty) {
      input['permissions'] = item.permissions;
    } else {
      input['permissions'] = <String>[];
    }
    
    return input;
  }
  
  /// Converte MenuType para string do schema
  String _menuTypeToString(MenuPresentationType type) {
    // Schema define: MAIN, SUB, ACTION, DIVIDER
    switch (type) {
      case MenuPresentationType.standard:
        return 'MAIN';
      default:
        return 'MAIN';
    }
  }
  
  /// Converte IconData para string
  String _iconToString(IconData icon) {
    if (icon == Icons.home) return 'home';
    if (icon == Icons.settings) return 'settings';
    if (icon == Icons.dashboard) return 'dashboard';
    if (icon == Icons.menu) return 'menu';
    return 'circle';
  }

  /// Converte data GraphQL para NavigationItem
  NavigationItem _graphQLDataToNavigationItem(Map<String, dynamic> data) {
    // Mapear de Menu schema para NavigationItem
    // Schema define: id, title, type, route, icon, order, isActive, permissions
    return NavigationItem(
      id: data['id'] as String,
      label: data['title'] as String? ?? data['label'] as String? ?? 'Menu Item',
      icon: _parseIconFromString(data['icon'] as String?),
      selectedIcon: _parseIconFromString(data['icon'] as String?),
      route: data['route'] as String,
      order: data['order'] as int,
      isVisible: data['isActive'] as bool? ?? true,
      isEnabled: data['isActive'] as bool? ?? true,
      description: data['description'] as String?,
      parentId: data['parentId'] as String?,
      menuType: _parseMenuType(data['type'] as String?),
      permissions: (data['permissions'] as List<dynamic>?)?.cast<String>(),
    );
  }
  
  /// Parse icon string para IconData
  IconData _parseIconFromString(String? iconStr) {
    // Se não tiver ícone, usar default
    if (iconStr == null || iconStr.isEmpty) {
      return Icons.home;
    }
    
    // Tentar mapear string para ícone conhecido
    switch (iconStr.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'settings':
        return Icons.settings;
      case 'dashboard':
        return Icons.dashboard;
      case 'menu':
        return Icons.menu;
      default:
        return Icons.circle;
    }
  }
  
  /// Parse menu type string para enum
  MenuPresentationType _parseMenuType(String? typeStr) {
    if (typeStr == null) return MenuPresentationType.standard;
    
    switch (typeStr.toUpperCase()) {
      case 'MAIN':
        return MenuPresentationType.standard;
      case 'SUB':
        return MenuPresentationType.standard;
      case 'ACTION':
        return MenuPresentationType.standard;
      case 'DIVIDER':
        return MenuPresentationType.standard;
      default:
        return MenuPresentationType.standard;
    }
  }
}

/// Provider para o serviço GraphQL de menus
final menuGraphQLServiceProvider = Provider<MenuGraphQLService>((ref) {
  // Usar cliente autenticado para mutations que precisam de token
  final clientService = ref.watch(graphQLClientProvider);  
  return MenuGraphQLService(clientService.client);
});