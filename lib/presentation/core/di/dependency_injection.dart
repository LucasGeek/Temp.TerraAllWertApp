import 'package:get_it/get_it.dart';

// Use Cases - Auth
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';

// Use Cases - Menu
import '../../../domain/usecases/menu/get_menu_hierarchy_usecase.dart';
import '../../../domain/usecases/menu/get_visible_menus_usecase.dart';
import '../../../domain/usecases/menu/get_menu_by_id_usecase.dart';

// Use Cases - Tower
import '../../../domain/usecases/tower/get_towers_by_menu_usecase.dart';
import '../../../domain/usecases/tower/get_tower_by_id_usecase.dart';

// Use Cases - Enterprise
import '../../../domain/usecases/enterprise/get_current_enterprise_usecase.dart';

// Use Cases - User Preferences
import '../../../domain/usecases/user_preferences/get_user_preferences_usecase.dart';
import '../../../domain/usecases/user_preferences/set_preference_usecase.dart';

// Repositories (Domain interfaces)
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/menu_repository.dart';
import '../../../domain/repositories/tower_repository.dart';
import '../../../domain/repositories/enterprise_repository.dart';
import '../../../domain/repositories/user_preferences_repository.dart';
import '../../../domain/repositories/sync_repository.dart';

// Repository implementations
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/repositories/menu_repository_impl.dart';
import '../../../data/repositories/tower_repository_impl.dart';
import '../../../data/repositories/enterprise_repository_impl.dart';
import '../../../data/repositories/user_preferences_repository_impl.dart';
import '../../../data/repositories/sync_repository_impl.dart';

// DataSources
import '../../../data/datasources/local/user_local_datasource.dart';
import '../../../data/datasources/remote/user_remote_datasource.dart';
import '../../../data/datasources/local/menu_local_datasource.dart';
import '../../../data/datasources/remote/menu_remote_datasource.dart';
import '../../../data/datasources/local/tower_local_datasource.dart';
import '../../../data/datasources/remote/tower_remote_datasource.dart';
import '../../../data/datasources/local/enterprise_local_datasource.dart';
import '../../../data/datasources/remote/enterprise_remote_datasource.dart';
import '../../../data/datasources/local/user_preferences_local_datasource.dart';
import '../../../data/datasources/remote/user_preferences_remote_datasource.dart';
import '../../../data/datasources/local/sync_queue_local_datasource.dart';

// Storage Adapters
import '../../../infra/storage/local_storage_adapter.dart';
import '../../../infra/storage/preferences_adapter.dart';

// HTTP Client
import '../../../infra/http/rest_client.dart';

// Config
import '../../../infra/config/env_config.dart';

final GetIt getIt = GetIt.instance;

/// Configure all dependencies for the application
/// This should be called during app initialization
Future<void> configureDependencies() async {
  // ===== CONFIG =====
  
  // Register EnvConfig
  getIt.registerSingleton<EnvConfig>(EnvConfig.fromEnvironment());
  
  // ===== STORAGE ADAPTERS =====
  
  // Initialize storage adapters asynchronously  
  final localStorageAdapter = await LocalStorageAdapter.getInstance();
  getIt.registerSingleton<LocalStorageAdapter>(localStorageAdapter);
  
  final preferencesAdapter = await PreferencesAdapter.getInstance();  
  getIt.registerSingleton<PreferencesAdapter>(preferencesAdapter);

  // ===== DATA SOURCES =====
  
  // Local Data Sources (using concrete implementations)
  getIt.registerLazySingleton<UserLocalDataSource>(() => UserLocalDataSourceImpl(getIt<LocalStorageAdapter>()));
  getIt.registerLazySingleton<MenuLocalDataSource>(() => MenuLocalDataSourceImpl(getIt<LocalStorageAdapter>()));
  getIt.registerLazySingleton<TowerLocalDataSource>(() => TowerLocalDataSourceImpl(getIt<LocalStorageAdapter>()));
  getIt.registerLazySingleton<EnterpriseLocalDataSource>(() => EnterpriseLocalDataSourceImpl(getIt<LocalStorageAdapter>()));
  getIt.registerLazySingleton<UserPreferencesLocalDataSource>(() => UserPreferencesLocalDataSourceImpl(getIt<LocalStorageAdapter>()));
  getIt.registerLazySingleton<SyncQueueLocalDataSource>(() => SyncQueueLocalDataSourceImpl(getIt<LocalStorageAdapter>()));
  
  // HTTP Client for remote datasources
  getIt.registerLazySingleton<RestClient>(() => RestClient(config: getIt<EnvConfig>()));
  
  // Remote Data Sources (using concrete implementations)
  getIt.registerLazySingleton<UserRemoteDataSource>(() => UserRemoteDataSourceImpl(getIt<RestClient>()));
  getIt.registerLazySingleton<MenuRemoteDataSource>(() => MenuRemoteDataSourceImpl(getIt<RestClient>()));
  getIt.registerLazySingleton<TowerRemoteDataSource>(() => TowerRemoteDataSourceImpl(getIt<RestClient>()));
  getIt.registerLazySingleton<EnterpriseRemoteDataSource>(() => EnterpriseRemoteDataSourceImpl(getIt<RestClient>()));
  getIt.registerLazySingleton<UserPreferencesRemoteDataSource>(() => UserPreferencesRemoteDataSourceImpl(getIt<RestClient>()));

  // ===== REPOSITORIES =====
  
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      getIt<UserLocalDataSource>(),
      getIt<UserRemoteDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<MenuRepository>(
    () => MenuRepositoryImpl(
      getIt<MenuLocalDataSource>(),
      getIt<MenuRemoteDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<TowerRepository>(
    () => TowerRepositoryImpl(
      getIt<TowerLocalDataSource>(),
      getIt<TowerRemoteDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<EnterpriseRepository>(
    () => EnterpriseRepositoryImpl(
      getIt<EnterpriseLocalDataSource>(),
      getIt<EnterpriseRemoteDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<UserPreferencesRepository>(
    () => UserPreferencesRepositoryImpl(
      getIt<UserPreferencesLocalDataSource>(),
      getIt<UserPreferencesRemoteDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(getIt<SyncQueueLocalDataSource>()),
  );

  // ===== USE CASES =====
  
  // Auth Use Cases
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<UserRepository>()),
  );
  
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(
      getIt<UserRepository>(),
      getIt<SyncRepository>(),
    ),
  );
  
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<UserRepository>()),
  );
  
  // Menu Use Cases
  getIt.registerLazySingleton<GetMenuHierarchyUseCase>(
    () => GetMenuHierarchyUseCase(getIt<MenuRepository>()),
  );
  
  getIt.registerLazySingleton<GetVisibleMenusUseCase>(
    () => GetVisibleMenusUseCase(getIt<MenuRepository>()),
  );
  
  getIt.registerLazySingleton<GetMenuByIdUseCase>(
    () => GetMenuByIdUseCase(getIt<MenuRepository>()),
  );
  
  // Tower Use Cases
  getIt.registerLazySingleton<GetTowersByMenuUseCase>(
    () => GetTowersByMenuUseCase(getIt<TowerRepository>()),
  );
  
  getIt.registerLazySingleton<GetTowerByIdUseCase>(
    () => GetTowerByIdUseCase(getIt<TowerRepository>()),
  );
  
  // Enterprise Use Cases
  getIt.registerLazySingleton<GetCurrentEnterpriseUseCase>(
    () => GetCurrentEnterpriseUseCase(getIt<EnterpriseRepository>()),
  );
  
  // User Preferences Use Cases
  getIt.registerLazySingleton<GetUserPreferencesUseCase>(
    () => GetUserPreferencesUseCase(getIt<UserPreferencesRepository>()),
  );
  
  getIt.registerLazySingleton<SetPreferenceUseCase>(
    () => SetPreferenceUseCase(getIt<UserPreferencesRepository>()),
  );
}

/// Clean up all registered dependencies
/// Call this when the app is being disposed
void disposeDependencies() {
  getIt.reset();
}