import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

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
    List<String>? permissions,
  }) = _NavigationItem;
}