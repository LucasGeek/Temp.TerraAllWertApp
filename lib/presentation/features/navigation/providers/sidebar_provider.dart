import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para controlar o estado de expansão/colapso da sidebar
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

/// Notifier para gerenciar o estado da sidebar
class SidebarNotifier extends StateNotifier<bool> {
  SidebarNotifier() : super(true); // Inicialmente expandida

  /// Alterna entre expandida e recolhida
  void toggle() {
    state = !state;
  }

  /// Define se a sidebar está expandida
  void setExpanded(bool expanded) {
    state = expanded;
  }

  /// Expande a sidebar
  void expand() {
    state = true;
  }

  /// Recolhe a sidebar
  void collapse() {
    state = false;
  }
}

final sidebarNotifierProvider = StateNotifierProvider<SidebarNotifier, bool>((ref) {
  return SidebarNotifier();
});