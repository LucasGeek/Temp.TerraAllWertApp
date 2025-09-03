import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/menu.dart';
import '../../domain/usecases/menu/get_visible_menus_usecase.dart';
import '../../domain/usecases/menu/get_menu_hierarchy_usecase.dart';
import '../utils/errors/api_error_handler.dart';

/// Estado dos menus
enum MenuStatus { initial, loading, loaded, empty, error }

/// Classe para representar o estado dos menus
class MenuState {
  final MenuStatus status;
  final List<Menu> menus;
  final String? error;

  const MenuState({
    required this.status,
    this.menus = const [],
    this.error,
  });

  MenuState copyWith({
    MenuStatus? status,
    List<Menu>? menus,
    String? error,
  }) {
    return MenuState(
      status: status ?? this.status,
      menus: menus ?? this.menus,
      error: error ?? this.error,
    );
  }

  bool get isEmpty => status == MenuStatus.empty || menus.isEmpty;
  bool get isLoading => status == MenuStatus.loading;
  bool get hasError => status == MenuStatus.error;
  bool get hasMenus => status == MenuStatus.loaded && menus.isNotEmpty;
}

/// Provider para GetVisibleMenusUseCase
final getVisibleMenusUseCaseProvider = Provider<GetVisibleMenusUseCase>((ref) {
  return GetIt.instance<GetVisibleMenusUseCase>();
});

/// Provider para GetMenuHierarchyUseCase
final getMenuHierarchyUseCaseProvider = Provider<GetMenuHierarchyUseCase>((ref) {
  return GetIt.instance<GetMenuHierarchyUseCase>();
});

/// Notifier para gerenciar o estado dos menus
class MenuNotifier extends StateNotifier<MenuState> {
  final GetVisibleMenusUseCase _getVisibleMenusUseCase;
  final GetMenuHierarchyUseCase _getMenuHierarchyUseCase;

  MenuNotifier(this._getVisibleMenusUseCase, this._getMenuHierarchyUseCase) 
      : super(const MenuState(status: MenuStatus.initial));

  /// Carrega os menus visíveis
  Future<void> loadVisibleMenus() async {
    // Se já está carregando, não fazer nova request
    if (state.isLoading) return;

    state = state.copyWith(status: MenuStatus.loading, error: null);

    try {
      // Por enquanto, usar um enterpriseId mockado
      // TODO: Pegar do usuário autenticado
      final params = GetVisibleMenusParams(enterpriseLocalId: 'default-enterprise');
      final menus = await _getVisibleMenusUseCase(params);
      
      if (menus.isEmpty) {
        state = const MenuState(status: MenuStatus.empty);
      } else {
        state = MenuState(status: MenuStatus.loaded, menus: menus);
      }
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        status: MenuStatus.error,
        error: errorMessage,
      );
    }
  }

  /// Carrega a hierarquia de menus
  Future<void> loadMenuHierarchy() async {
    // Se já está carregando, não fazer nova request
    if (state.isLoading) return;

    state = state.copyWith(status: MenuStatus.loading, error: null);

    try {
      // Por enquanto, usar um enterpriseId mockado
      // TODO: Pegar do usuário autenticado
      final params = GetMenuHierarchyParams(enterpriseLocalId: 'default-enterprise');
      final menus = await _getMenuHierarchyUseCase(params);
      
      if (menus.isEmpty) {
        state = const MenuState(status: MenuStatus.empty);
      } else {
        state = MenuState(status: MenuStatus.loaded, menus: menus);
      }
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      state = state.copyWith(
        status: MenuStatus.error,
        error: errorMessage,
      );
    }
  }

  /// Recarrega os menus
  Future<void> refresh() async {
    await loadVisibleMenus();
  }

  /// Limpa o estado dos menus
  void clearMenus() {
    state = const MenuState(status: MenuStatus.initial);
  }
}

/// Provider de menus
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(
    ref.read(getVisibleMenusUseCaseProvider),
    ref.read(getMenuHierarchyUseCaseProvider),
  );
});

/// Provider que expõe apenas se tem menus
final hasMenusProvider = Provider<bool>((ref) {
  final menuState = ref.watch(menuProvider);
  return menuState.hasMenus;
});

/// Provider que expõe apenas se está vazio
final isMenusEmptyProvider = Provider<bool>((ref) {
  final menuState = ref.watch(menuProvider);
  return menuState.isEmpty;
});

/// Provider que expõe apenas se está carregando
final isMenusLoadingProvider = Provider<bool>((ref) {
  final menuState = ref.watch(menuProvider);
  return menuState.isLoading;
});