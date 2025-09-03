import 'package:flutter_riverpod/flutter_riverpod.dart';

// Domain imports
import '../../../domain/entities/user.dart';
import '../../../domain/entities/menu.dart';
import '../../../domain/entities/tower.dart';
import '../../../domain/entities/enterprise.dart';
import '../../../domain/entities/user_preferences.dart';

// Use Cases
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/menu/get_menu_hierarchy_usecase.dart';
import '../../../domain/usecases/menu/get_visible_menus_usecase.dart';
import '../../../domain/usecases/menu/get_menu_by_id_usecase.dart';
import '../../../domain/usecases/tower/get_towers_by_menu_usecase.dart';
import '../../../domain/usecases/tower/get_tower_by_id_usecase.dart';
import '../../../domain/usecases/enterprise/get_current_enterprise_usecase.dart';
import '../../../domain/usecases/user_preferences/get_user_preferences_usecase.dart';
import '../../../domain/usecases/user_preferences/set_preference_usecase.dart';

// Dependency Injection
import '../di/dependency_injection.dart';

// =============================================================================
// USE CASE PROVIDERS
// These providers get use cases from GetIt and expose them to the UI layer
// =============================================================================

// Auth Use Cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return getIt<LoginUseCase>();
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return getIt<LogoutUseCase>();
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return getIt<GetCurrentUserUseCase>();
});

// Menu Use Cases
final getMenuHierarchyUseCaseProvider = Provider<GetMenuHierarchyUseCase>((ref) {
  return getIt<GetMenuHierarchyUseCase>();
});

final getVisibleMenusUseCaseProvider = Provider<GetVisibleMenusUseCase>((ref) {
  return getIt<GetVisibleMenusUseCase>();
});

final getMenuByIdUseCaseProvider = Provider<GetMenuByIdUseCase>((ref) {
  return getIt<GetMenuByIdUseCase>();
});

// Tower Use Cases
final getTowersByMenuUseCaseProvider = Provider<GetTowersByMenuUseCase>((ref) {
  return getIt<GetTowersByMenuUseCase>();
});

final getTowerByIdUseCaseProvider = Provider<GetTowerByIdUseCase>((ref) {
  return getIt<GetTowerByIdUseCase>();
});

// Enterprise Use Cases
final getCurrentEnterpriseUseCaseProvider = Provider<GetCurrentEnterpriseUseCase>((ref) {
  return getIt<GetCurrentEnterpriseUseCase>();
});

// User Preferences Use Cases
final getUserPreferencesUseCaseProvider = Provider<GetUserPreferencesUseCase>((ref) {
  return getIt<GetUserPreferencesUseCase>();
});

final setPreferenceUseCaseProvider = Provider<SetPreferenceUseCase>((ref) {
  return getIt<SetPreferenceUseCase>();
});

// =============================================================================
// DATA PROVIDERS
// These providers use the use cases to fetch and manage data state
// =============================================================================

// Current User Provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  try {
    return await getCurrentUserUseCase.call();
  } catch (e) {
    return null; // Return null if user is not logged in
  }
});

// Current Enterprise Provider
final currentEnterpriseProvider = FutureProvider<Enterprise?>((ref) async {
  final getCurrentEnterpriseUseCase = ref.watch(getCurrentEnterpriseUseCaseProvider);
  try {
    return await getCurrentEnterpriseUseCase.call();
  } catch (e) {
    return null;
  }
});

// Menu Hierarchy Provider (needs enterprise ID)
final menuHierarchyProvider = FutureProvider.family<List<Menu>, String>((ref, enterpriseId) async {
  final getMenuHierarchyUseCase = ref.watch(getMenuHierarchyUseCaseProvider);
  return await getMenuHierarchyUseCase.call(GetMenuHierarchyParams(enterpriseLocalId: enterpriseId));
});

// Visible Menus Provider (needs enterprise ID)
final visibleMenusProvider = FutureProvider.family<List<Menu>, String>((ref, enterpriseId) async {
  final getVisibleMenusUseCase = ref.watch(getVisibleMenusUseCaseProvider);
  return await getVisibleMenusUseCase.call(GetVisibleMenusParams(enterpriseLocalId: enterpriseId));
});

// Towers by Menu Provider (Family)
final towersByMenuProvider = FutureProvider.family<List<Tower>, String>((ref, menuId) async {
  final getTowersByMenuUseCase = ref.watch(getTowersByMenuUseCaseProvider);
  return await getTowersByMenuUseCase.call(GetTowersByMenuParams(menuLocalId: menuId));
});

// Single Menu Provider (Family)
final menuByIdProvider = FutureProvider.family<Menu?, String>((ref, menuId) async {
  final getMenuByIdUseCase = ref.watch(getMenuByIdUseCaseProvider);
  try {
    return await getMenuByIdUseCase.call(GetMenuByIdParams(localId: menuId));
  } catch (e) {
    return null;
  }
});

// Single Tower Provider (Family)
final towerByIdProvider = FutureProvider.family<Tower?, String>((ref, towerId) async {
  final getTowerByIdUseCase = ref.watch(getTowerByIdUseCaseProvider);
  try {
    return await getTowerByIdUseCase.call(GetTowerByIdParams(localId: towerId));
  } catch (e) {
    return null;
  }
});

// =============================================================================
// AUTHENTICATION STATE PROVIDERS
// =============================================================================

// Authentication State Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  
  AuthStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final getCurrentUserUseCase = _ref.read(getCurrentUserUseCaseProvider);
      final user = await getCurrentUserUseCase.call();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final loginUseCase = _ref.read(loginUseCaseProvider);
      final user = await loginUseCase.execute(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      final logoutUseCase = _ref.read(logoutUseCaseProvider);
      await logoutUseCase.execute();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }
}

// =============================================================================
// PREFERENCES PROVIDERS
// =============================================================================

// User Preferences Provider
final userPreferencesProvider = FutureProvider<UserPreferences?>((ref) async {
  final getUserPreferencesUseCase = ref.watch(getUserPreferencesUseCaseProvider);
  final currentUser = await ref.watch(currentUserProvider.future);
  
  if (currentUser == null) return null;
  
  try {
    return await getUserPreferencesUseCase.call(
      GetUserPreferencesParams(userLocalId: currentUser.localId),
    );
  } catch (e) {
    return null;
  }
});

// Preference Setter Provider (for mutations)
final preferenceSetterProvider = Provider<SetPreferenceUseCase>((ref) {
  return ref.watch(setPreferenceUseCaseProvider);
});

// =============================================================================
// UI STATE PROVIDERS
// =============================================================================

// Loading states for various operations
final loginLoadingProvider = StateProvider<bool>((ref) => false);
final dataLoadingProvider = StateProvider<bool>((ref) => false);

// Error state provider
final errorStateProvider = StateProvider<String?>((ref) => null);

// =============================================================================
// HELPER METHODS
// =============================================================================

// Extension to make it easier to work with AsyncValue in UI
extension AsyncValueX on AsyncValue {
  bool get isLoading => maybeWhen(
    loading: () => true,
    orElse: () => false,
  );

  bool get hasError => maybeWhen(
    error: (_, _) => true,
    orElse: () => false,
  );

  Object? get valueOrNull => maybeWhen(
    data: (value) => value,
    orElse: () => null,
  );
}