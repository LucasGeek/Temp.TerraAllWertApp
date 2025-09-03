import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para controlar a rota/menu selecionado atualmente
final currentRouteProvider = StateProvider<String?>((ref) => null);

/// Notifier para gerenciar a rota atual
class CurrentRouteNotifier extends StateNotifier<String?> {
  CurrentRouteNotifier() : super(null);

  /// Define a rota atual
  void setCurrentRoute(String route) {
    state = route;
  }

  /// Limpa a seleção de rota
  void clearCurrentRoute() {
    state = null;
  }

  /// Verifica se uma rota específica está selecionada
  bool isRouteSelected(String route) {
    return state == route;
  }
}

final currentRouteNotifierProvider = StateNotifierProvider<CurrentRouteNotifier, String?>((ref) {
  return CurrentRouteNotifier();
});