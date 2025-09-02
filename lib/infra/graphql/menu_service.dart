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
          document: gql(getAllMenusQuery),
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
    // Navigation & Common
    if (icon == Icons.home) return 'home';
    if (icon == Icons.dashboard) return 'dashboard';
    if (icon == Icons.menu) return 'menu';
    if (icon == Icons.search) return 'search';
    if (icon == Icons.notifications) return 'notifications';
    if (icon == Icons.settings) return 'settings';
    if (icon == Icons.person) return 'person';
    if (icon == Icons.exit_to_app) return 'logout';
    if (icon == Icons.login) return 'login';
    
    // Real Estate & Building
    if (icon == Icons.apartment) return 'apartment';
    if (icon == Icons.house) return 'house';
    if (icon == Icons.domain) return 'tower';
    if (icon == Icons.layers) return 'floor';
    if (icon == Icons.meeting_room) return 'room';
    if (icon == Icons.bed) return 'bed';
    if (icon == Icons.bathroom) return 'bathroom';
    if (icon == Icons.kitchen) return 'kitchen';
    if (icon == Icons.local_parking) return 'parking';
    if (icon == Icons.balcony) return 'balcony';
    if (icon == Icons.yard) return 'garden';
    if (icon == Icons.pool) return 'pool';
    if (icon == Icons.fitness_center) return 'gym';
    if (icon == Icons.elevator) return 'elevator';
    if (icon == Icons.stairs) return 'stairs';
    
    // Business & Commerce
    if (icon == Icons.business) return 'business';
    if (icon == Icons.store) return 'store';
    if (icon == Icons.business_center) return 'office';
    if (icon == Icons.attach_money) return 'money';
    if (icon == Icons.calculate) return 'calculator';
    if (icon == Icons.description) return 'document';
    
    // Communication & Media
    if (icon == Icons.phone) return 'phone';
    if (icon == Icons.email) return 'email';
    if (icon == Icons.message) return 'message';
    if (icon == Icons.video_call) return 'video';
    if (icon == Icons.camera_alt) return 'camera';
    if (icon == Icons.photo_library) return 'gallery';
    if (icon == Icons.share) return 'share';
    
    // Location & Maps
    if (icon == Icons.location_on) return 'location';
    if (icon == Icons.map) return 'map';
    if (icon == Icons.directions) return 'directions';
    
    // Time & Calendar
    if (icon == Icons.calendar_today) return 'calendar';
    if (icon == Icons.schedule) return 'schedule';
    if (icon == Icons.access_time) return 'clock';
    if (icon == Icons.history) return 'history';
    
    // Actions & Controls
    if (icon == Icons.add) return 'add';
    if (icon == Icons.edit) return 'edit';
    if (icon == Icons.delete) return 'delete';
    if (icon == Icons.save) return 'save';
    if (icon == Icons.download) return 'download';
    if (icon == Icons.upload) return 'upload';
    if (icon == Icons.refresh) return 'refresh';
    if (icon == Icons.close) return 'close';
    if (icon == Icons.check) return 'check';
    if (icon == Icons.favorite) return 'favorite';
    if (icon == Icons.star) return 'star';
    if (icon == Icons.bookmark) return 'bookmark';
    
    // Status & Info
    if (icon == Icons.info) return 'info';
    if (icon == Icons.warning) return 'warning';
    if (icon == Icons.error) return 'error';
    if (icon == Icons.help) return 'help';
    if (icon == Icons.visibility) return 'visibility';
    if (icon == Icons.visibility_off) return 'hidden';
    if (icon == Icons.lock) return 'lock';
    if (icon == Icons.lock_open) return 'unlock';
    
    // Lists & Data
    if (icon == Icons.list) return 'list';
    if (icon == Icons.grid_view) return 'grid';
    if (icon == Icons.table_chart) return 'table';
    if (icon == Icons.sort) return 'sort';
    if (icon == Icons.filter_list) return 'filter';
    if (icon == Icons.analytics) return 'analytics';
    
    // Files & Storage
    if (icon == Icons.folder) return 'folder';
    if (icon == Icons.insert_drive_file) return 'file';
    if (icon == Icons.picture_as_pdf) return 'pdf';
    if (icon == Icons.image) return 'image';
    if (icon == Icons.cloud) return 'cloud';
    
    // Social & People
    if (icon == Icons.people) return 'people';
    if (icon == Icons.person_outline) return 'client';
    if (icon == Icons.groups) return 'team';
    if (icon == Icons.contacts) return 'contacts';
    
    // Weather & Environment
    if (icon == Icons.wb_sunny) return 'sun';
    if (icon == Icons.wb_cloudy) return 'weather';
    
    // Technology & Devices
    if (icon == Icons.smartphone) return 'mobile';
    if (icon == Icons.computer) return 'computer';
    if (icon == Icons.wifi) return 'wifi';
    
    // Default fallback
    return 'circle';
  }

  /// Converte data GraphQL para NavigationItem
  NavigationItem _graphQLDataToNavigationItem(Map<String, dynamic> data) {
    // Mapear de Menu schema para NavigationItem
    // Schema define: id, title, type, route, icon, order, isActive, permissions, children
    return NavigationItem(
      id: data['id'] as String,
      label: data['title'] as String,
      icon: _parseIconFromString(data['icon'] as String?),
      selectedIcon: _parseIconFromString(data['icon'] as String?),
      route: data['route'] as String,
      order: data['order'] as int,
      isVisible: data['isActive'] as bool? ?? true,
      isEnabled: data['isActive'] as bool? ?? true,
      description: null, // Não disponível no schema atual
      parentId: null,    // Será inferido dos children
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
    
    // Mapear string para ícone conhecido - ampla lista Material Design
    switch (iconStr.toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
      // Navigation & Common
      case 'home':
        return Icons.home;
      case 'dashboard':
        return Icons.dashboard;
      case 'menu':
        return Icons.menu;
      case 'search':
        return Icons.search;
      case 'notifications':
        return Icons.notifications;
      case 'settings':
        return Icons.settings;
      case 'account':
      case 'profile':
      case 'person':
        return Icons.person;
      case 'logout':
      case 'exit':
        return Icons.exit_to_app;
      case 'login':
        return Icons.login;
      
      // Real Estate & Building
      case 'apartment':
      case 'building':
        return Icons.apartment;
      case 'house':
      case 'residential':
        return Icons.house;
      case 'tower':
      case 'towers':
        return Icons.domain;
      case 'floor':
      case 'floors':
        return Icons.layers;
      case 'room':
      case 'rooms':
        return Icons.meeting_room;
      case 'bedroom':
      case 'bed':
        return Icons.bed;
      case 'bathroom':
      case 'shower':
        return Icons.bathroom;
      case 'kitchen':
        return Icons.kitchen;
      case 'garage':
      case 'parking':
        return Icons.local_parking;
      case 'balcony':
      case 'terrace':
        return Icons.balcony;
      case 'garden':
        return Icons.yard;
      case 'pool':
      case 'swimming':
        return Icons.pool;
      case 'gym':
      case 'fitness':
        return Icons.fitness_center;
      case 'elevator':
        return Icons.elevator;
      case 'stairs':
        return Icons.stairs;
      
      // Business & Commerce
      case 'business':
      case 'commercial':
        return Icons.business;
      case 'store':
      case 'shop':
        return Icons.store;
      case 'office':
        return Icons.business_center;
      case 'money':
      case 'price':
      case 'payment':
        return Icons.attach_money;
      case 'calculator':
        return Icons.calculate;
      case 'contract':
      case 'document':
        return Icons.description;
      case 'signature':
        return Icons.draw;
      
      // Communication & Media
      case 'phone':
      case 'call':
        return Icons.phone;
      case 'email':
      case 'mail':
        return Icons.email;
      case 'message':
      case 'chat':
        return Icons.message;
      case 'video':
      case 'videocall':
        return Icons.video_call;
      case 'camera':
      case 'photo':
        return Icons.camera_alt;
      case 'gallery':
      case 'photos':
        return Icons.photo_library;
      case 'share':
        return Icons.share;
      
      // Location & Maps
      case 'location':
      case 'place':
      case 'pin':
        return Icons.location_on;
      case 'map':
      case 'maps':
        return Icons.map;
      case 'directions':
        return Icons.directions;
      case 'gps':
        return Icons.gps_fixed;
      case 'nearby':
        return Icons.near_me;
      
      // Time & Calendar
      case 'calendar':
      case 'date':
        return Icons.calendar_today;
      case 'schedule':
      case 'time':
        return Icons.schedule;
      case 'clock':
        return Icons.access_time;
      case 'timer':
        return Icons.timer;
      case 'history':
        return Icons.history;
      
      // Actions & Controls
      case 'add':
      case 'plus':
      case 'create':
        return Icons.add;
      case 'edit':
      case 'pencil':
        return Icons.edit;
      case 'delete':
      case 'remove':
      case 'trash':
        return Icons.delete;
      case 'save':
        return Icons.save;
      case 'download':
        return Icons.download;
      case 'upload':
        return Icons.upload;
      case 'refresh':
      case 'reload':
        return Icons.refresh;
      case 'close':
        return Icons.close;
      case 'check':
      case 'done':
        return Icons.check;
      case 'favorite':
      case 'heart':
      case 'like':
        return Icons.favorite;
      case 'star':
      case 'rating':
        return Icons.star;
      case 'bookmark':
        return Icons.bookmark;
      case 'flag':
        return Icons.flag;
      
      // Status & Info
      case 'info':
      case 'information':
        return Icons.info;
      case 'warning':
      case 'alert':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'help':
      case 'question':
        return Icons.help;
      case 'visibility':
      case 'visible':
      case 'show':
        return Icons.visibility;
      case 'hidden':
      case 'hide':
        return Icons.visibility_off;
      case 'lock':
      case 'locked':
        return Icons.lock;
      case 'unlock':
      case 'unlocked':
        return Icons.lock_open;
      case 'security':
        return Icons.security;
      
      // Lists & Data
      case 'list':
        return Icons.list;
      case 'grid':
        return Icons.grid_view;
      case 'table':
        return Icons.table_chart;
      case 'sort':
        return Icons.sort;
      case 'filter':
        return Icons.filter_list;
      case 'analytics':
      case 'chart':
        return Icons.analytics;
      case 'report':
        return Icons.assessment;
      
      // Files & Storage
      case 'folder':
        return Icons.folder;
      case 'file':
        return Icons.insert_drive_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'cloud':
        return Icons.cloud;
      case 'storage':
        return Icons.storage;
      
      // Social & People
      case 'people':
      case 'group':
      case 'users':
        return Icons.people;
      case 'client':
      case 'customer':
        return Icons.person_outline;
      case 'team':
        return Icons.groups;
      case 'contact':
      case 'contacts':
        return Icons.contacts;
      
      // Transportation
      case 'car':
      case 'vehicle':
        return Icons.directions_car;
      case 'bus':
        return Icons.directions_bus;
      case 'train':
      case 'subway':
        return Icons.directions_subway;
      case 'bike':
      case 'bicycle':
        return Icons.directions_bike;
      case 'walk':
      case 'walking':
        return Icons.directions_walk;
      
      // Weather & Environment
      case 'sun':
      case 'sunny':
      case 'solar':
        return Icons.wb_sunny;
      case 'weather':
        return Icons.wb_cloudy;
      case 'rain':
        return Icons.umbrella;
      case 'wind':
        return Icons.air;
      case 'temperature':
        return Icons.thermostat;
      
      // Technology & Devices
      case 'mobile':
        return Icons.smartphone;
      case 'computer':
      case 'desktop':
        return Icons.computer;
      case 'tablet':
        return Icons.tablet;
      case 'wifi':
        return Icons.wifi;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'battery':
        return Icons.battery_full;
      case 'power':
      case 'electric':
        return Icons.power;
      
      // Shopping & E-commerce
      case 'shopping':
      case 'cart':
        return Icons.shopping_cart;
      case 'bag':
        return Icons.shopping_bag;
      case 'credit':
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'receipt':
        return Icons.receipt;
      case 'sale':
      case 'offer':
        return Icons.local_offer;
      
      // Default fallbacks
      case 'circle':
        return Icons.circle;
      case 'dot':
        return Icons.fiber_manual_record;
      case 'square':
        return Icons.stop;
      
      default:
        // Se não encontrar correspondência, tentar usar um ícone genérico baseado no contexto
        if (iconStr.contains('home') || iconStr.contains('house')) return Icons.home;
        if (iconStr.contains('user') || iconStr.contains('person') || iconStr.contains('profile')) return Icons.person;
        if (iconStr.contains('setting') || iconStr.contains('config')) return Icons.settings;
        if (iconStr.contains('search') || iconStr.contains('find')) return Icons.search;
        if (iconStr.contains('list') || iconStr.contains('menu')) return Icons.list;
        if (iconStr.contains('info') || iconStr.contains('about')) return Icons.info;
        if (iconStr.contains('help') || iconStr.contains('support')) return Icons.help;
        if (iconStr.contains('contact') || iconStr.contains('phone')) return Icons.contact_phone;
        if (iconStr.contains('mail') || iconStr.contains('email')) return Icons.email;
        if (iconStr.contains('location') || iconStr.contains('map')) return Icons.location_on;
        if (iconStr.contains('time') || iconStr.contains('clock')) return Icons.access_time;
        if (iconStr.contains('calendar') || iconStr.contains('date')) return Icons.calendar_today;
        if (iconStr.contains('favorite') || iconStr.contains('star')) return Icons.star;
        
        // Fallback final
        return Icons.circle_outlined;
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