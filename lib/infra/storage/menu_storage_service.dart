import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infra/logging/app_logger.dart';
import '../../domain/entities/navigation_item.dart';
import '../../domain/enums/menu_presentation_type.dart';

/// Service para armazenamento local de menus customizados
/// Usa SharedPreferences para persistir configurações de navegação
class MenuStorageService {
  static const String _menuItemsKey = 'custom_navigation_items';
  static const String _menuConfigKey = 'menu_configuration';

  SharedPreferences? _prefs;

  /// Inicializa o service de storage
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      StorageLogger.info('MenuStorageService initialized successfully');
    } catch (e, stackTrace) {
      StorageLogger.error(
        'Failed to initialize MenuStorageService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Salva lista completa de itens de navegação
  Future<void> saveNavigationItems(List<NavigationItem> items) async {
    try {
      await _ensureInitialized();

      StorageLogger.info('Saving ${items.length} navigation items to local storage');

      // Converter para JSON serializável (sem IconData)
      final serializedItems = items
          .map(
            (item) => {
              'id': item.id,
              'label': item.label,
              'iconCodePoint': item.icon.codePoint,
              'iconFontFamily': item.icon.fontFamily,
              'selectedIconCodePoint': item.selectedIcon.codePoint,
              'selectedIconFontFamily': item.selectedIcon.fontFamily,
              'route': item.route,
              'order': item.order,
              'isVisible': item.isVisible,
              'isEnabled': item.isEnabled,
              'description': item.description,
              'parentId': item.parentId,
              'menuType': item.menuType.name, // Serializar o enum como string
              'permissions': item.permissions,
            },
          )
          .toList();

      final jsonString = jsonEncode(serializedItems);
      await _prefs!.setString(_menuItemsKey, jsonString);

      StorageLogger.info('Navigation items saved successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to save navigation items', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Carrega lista de itens de navegação salvos
  Future<List<NavigationItem>> loadNavigationItems() async {
    try {
      await _ensureInitialized();

      final jsonString = _prefs!.getString(_menuItemsKey);
      if (jsonString == null) {
        StorageLogger.debug('No custom navigation items found, returning default items');
        return _getDefaultNavigationItems();
      }

      StorageLogger.debug('Loading navigation items from local storage');

      final List<dynamic> serializedItems = jsonDecode(jsonString);

      final items = serializedItems.map((itemData) {
        // Deserializar menuType enum
        MenuPresentationType menuType = MenuPresentationType.standard;
        final menuTypeString = itemData['menuType'] as String?;
        if (menuTypeString != null) {
          try {
            menuType = MenuPresentationType.values.firstWhere(
              (type) => type.name == menuTypeString,
              orElse: () => MenuPresentationType.standard,
            );
          } catch (e) {
            StorageLogger.warning('Unknown menu type: $menuTypeString, using default');
          }
        }

        return NavigationItem(
          id: itemData['id'] as String,
          label: itemData['label'] as String,
          icon: _createIconData(
            itemData['iconCodePoint'] as int,
            itemData['iconFontFamily'] as String?,
          ),
          selectedIcon: _createIconData(
            itemData['selectedIconCodePoint'] as int,
            itemData['selectedIconFontFamily'] as String?,
          ),
          route: itemData['route'] as String,
          order: itemData['order'] as int,
          isVisible: itemData['isVisible'] as bool? ?? true,
          isEnabled: itemData['isEnabled'] as bool? ?? true,
          description: itemData['description'] as String?,
          parentId: itemData['parentId'] as String?,
          menuType: menuType,
          permissions: (itemData['permissions'] as List<dynamic>?)?.cast<String>(),
        );
      }).toList();

      // Ordenar por order
      items.sort((a, b) => a.order.compareTo(b.order));

      StorageLogger.info('Loaded ${items.length} navigation items from storage');
      return items;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to load navigation items', error: e, stackTrace: stackTrace);
      StorageLogger.warning('Falling back to default navigation items');
      return _getDefaultNavigationItems();
    }
  }

  /// Adiciona um novo item de navegação
  Future<void> addNavigationItem(NavigationItem item) async {
    try {
      final currentItems = await loadNavigationItems();

      // Verificar se já existe item com mesmo ID
      if (currentItems.any((existing) => existing.id == item.id)) {
        throw Exception('Item with ID ${item.id} already exists');
      }

      currentItems.add(item);
      await saveNavigationItems(currentItems);

      StorageLogger.info('Navigation item "${item.label}" added successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to add navigation item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Atualiza um item de navegação existente
  Future<void> updateNavigationItem(NavigationItem updatedItem) async {
    try {
      final currentItems = await loadNavigationItems();

      final index = currentItems.indexWhere((item) => item.id == updatedItem.id);
      if (index == -1) {
        throw Exception('Item with ID ${updatedItem.id} not found');
      }

      currentItems[index] = updatedItem;
      await saveNavigationItems(currentItems);

      StorageLogger.info('Navigation item "${updatedItem.label}" updated successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to update navigation item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Remove um item de navegação
  Future<void> removeNavigationItem(String itemId) async {
    try {
      final currentItems = await loadNavigationItems();

      final itemToRemove = currentItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item with ID $itemId not found'),
      );

      currentItems.removeWhere((item) => item.id == itemId);
      await saveNavigationItems(currentItems);

      StorageLogger.info('Navigation item "${itemToRemove.label}" removed successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to remove navigation item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Reordena itens de navegação
  Future<void> reorderNavigationItems(List<NavigationItem> reorderedItems) async {
    try {
      // Atualizar orders baseado na nova posição
      final updatedItems = reorderedItems.asMap().entries.map((entry) {
        return entry.value.copyWith(order: entry.key);
      }).toList();

      await saveNavigationItems(updatedItems);

      StorageLogger.info('Navigation items reordered successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to reorder navigation items', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Reseta para itens padrão
  Future<void> resetToDefault() async {
    try {
      await _ensureInitialized();

      StorageLogger.warning('Resetting navigation items to default');

      await _prefs!.remove(_menuItemsKey);
      await _prefs!.remove(_menuConfigKey);

      StorageLogger.info('Navigation items reset to default successfully');
    } catch (e, stackTrace) {
      StorageLogger.error(
        'Failed to reset to default navigation items',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Salva configurações específicas de menu
  Future<void> saveMenuConfiguration(Map<String, dynamic> config) async {
    try {
      await _ensureInitialized();

      final jsonString = jsonEncode(config);
      await _prefs!.setString(_menuConfigKey, jsonString);

      StorageLogger.info('Menu configuration saved successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to save menu configuration', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Carrega configurações de menu
  Future<Map<String, dynamic>> loadMenuConfiguration() async {
    try {
      await _ensureInitialized();

      final jsonString = _prefs!.getString(_menuConfigKey);
      if (jsonString == null) {
        StorageLogger.debug('No menu configuration found, returning defaults');
        return _getDefaultMenuConfiguration();
      }

      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      StorageLogger.debug('Menu configuration loaded successfully');

      return config;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to load menu configuration', error: e, stackTrace: stackTrace);
      return _getDefaultMenuConfiguration();
    }
  }

  /// Verifica se tem items customizados salvos
  Future<bool> hasCustomItems() async {
    try {
      await _ensureInitialized();
      return _prefs!.containsKey(_menuItemsKey);
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to check for custom items', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Obtém estatísticas do storage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      await _ensureInitialized();

      final items = await loadNavigationItems();
      final config = await loadMenuConfiguration();

      return {
        'totalItems': items.length,
        'visibleItems': items.where((item) => item.isVisible).length,
        'enabledItems': items.where((item) => item.isEnabled).length,
        'hasCustomization': await hasCustomItems(),
        'configKeys': config.keys.toList(),
        'lastModified': _prefs!.getString('${_menuItemsKey}_timestamp'),
      };
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get storage stats', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Garante que o storage foi inicializado
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// Itens de navegação padrão do sistema
  /// Retorna lista vazia para permitir que cliente configure seus próprios menus
  List<NavigationItem> _getDefaultNavigationItems() {
    return [];
  }

  /// Configuração padrão de menu
  Map<String, dynamic> _getDefaultMenuConfiguration() {
    return {
      'theme': 'default',
      'showIcons': true,
      'showDescription': false,
      'compactMode': false,
      'autoCollapse': true,
      'version': '1.0.0',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Cria IconData const para evitar problemas de tree shaking no web
  IconData _createIconData(int codePoint, String? fontFamily) {
    // Para web, usar apenas Icons padrão evitando fontFamily personalizada
    if (fontFamily != null && fontFamily != 'MaterialIcons') {
      // Se não é MaterialIcons padrão, usar ícone genérico
      return const IconData(0xe3b7, fontFamily: 'MaterialIcons'); // navigation icon
    }
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }
}

// Provider
final menuStorageServiceProvider = Provider<MenuStorageService>((ref) {
  return MenuStorageService();
});
