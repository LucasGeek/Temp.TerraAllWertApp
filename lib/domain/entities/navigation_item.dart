import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

import '../enums/menu_presentation_type.dart';
import '../enums/tipo_tela.dart';

part 'navigation_item.freezed.dart';

@freezed
abstract class NavigationItem with _$NavigationItem {
  const factory NavigationItem({
    required String id,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required String route,
    required int order,
    @Default(true) bool isVisible,
    @Default(true) bool isEnabled,
    String? description,
    String? parentId, // ID do menu pai (null = menu raiz)
    @Default(MenuPresentationType.padrao) MenuPresentationType menuType, // Tipo de menu (padrão ou com submenu)
    TipoTela? tipoTela, // Tipo de tela/apresentação (null para menus com submenu)
    List<String>? permissions,
  }) = _NavigationItem;
}