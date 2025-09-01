import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
          variables: _navigationItemToGraphQLInput(item),
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL mutation failed: ${result.exception}', tag: 'MenuGraphQL');
        return null;
      }

      final data = result.data?['createMenu'];
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
            'id': item.id,
            'input': _navigationItemToGraphQLInput(item),
          },
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL update failed: ${result.exception}', tag: 'MenuGraphQL');
        return null;
      }

      final data = result.data?['updateMenu'];
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
          variables: {'id': menuId},
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
  Future<List<NavigationItem>> getMenus({String? userId}) async {
    try {
      AppLogger.debug('Fetching menus via GraphQL', tag: 'MenuGraphQL');

      final result = await _client.query(
        QueryOptions(
          document: gql(getMenusQuery),
          variables: userId != null ? {'userId': userId} : {},
          errorPolicy: ErrorPolicy.all,
          cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL query failed: ${result.exception}', tag: 'MenuGraphQL');
        return [];
      }

      final data = result.data?['menus'] as List<dynamic>?;
      if (data != null) {
        final menus = data
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
    return {
      'label': item.label,
      'route': item.route,
      'iconCodePoint': item.icon.codePoint,
      'iconFontFamily': item.icon.fontFamily,
      'selectedIconCodePoint': item.selectedIcon.codePoint,
      'selectedIconFontFamily': item.selectedIcon.fontFamily,
      'order': item.order,
      'isVisible': item.isVisible,
      'isEnabled': item.isEnabled,
      'description': item.description,
      'parentId': item.parentId,
      'menuType': item.menuType.name,
      'permissions': item.permissions,
    };
  }

  /// Converte data GraphQL para NavigationItem
  NavigationItem _graphQLDataToNavigationItem(Map<String, dynamic> data) {
    return NavigationItem(
      id: data['id'] as String,
      label: data['label'] as String,
      icon: IconData(
        data['iconCodePoint'] as int,
        fontFamily: data['iconFontFamily'] as String?,
      ),
      selectedIcon: IconData(
        data['selectedIconCodePoint'] as int,
        fontFamily: data['selectedIconFontFamily'] as String?,
      ),
      route: data['route'] as String,
      order: data['order'] as int,
      isVisible: data['isVisible'] as bool? ?? true,
      isEnabled: data['isEnabled'] as bool? ?? true,
      description: data['description'] as String?,
      parentId: data['parentId'] as String?,
      menuType: MenuPresentationType.values.firstWhere(
        (type) => type.name == data['menuType'],
        orElse: () => MenuPresentationType.standard,
      ),
      permissions: (data['permissions'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

/// Provider para o serviço GraphQL de menus
final menuGraphQLServiceProvider = Provider<MenuGraphQLService>((ref) {
  final clientService = ref.watch(graphQLClientProvider);
  return MenuGraphQLService(clientService.client);
});