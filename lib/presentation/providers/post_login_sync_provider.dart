import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/post_login_sync_service_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/post_login_sync_service.dart';
import '../../infra/cache/cache_service.dart';
import '../../infra/graphql/menu_service.dart';
import '../../infra/sync/offline_sync_service.dart';
import '../../infra/graphql/graphql_client.dart';
import 'connectivity_provider.dart';

// Provider do serviço de sincronização pós-login
final postLoginSyncServiceProvider = Provider<PostLoginSyncService>((ref) {
  // Inicializar dependências
  final cacheService = CacheService();
  final graphqlClient = ref.watch(graphQLClientProvider);
  final menuService = MenuGraphQLService(graphqlClient.client);
  final syncService = OfflineSyncService(graphqlClient: graphqlClient);

  return PostLoginSyncServiceImpl(
    cacheService: cacheService,
    menuService: menuService,
    syncService: syncService,
  );
});

// Provider que executa o fluxo de sincronização
final postLoginSyncProvider = FutureProvider.family<PostLoginSyncResult, User>((ref, user) async {
  final syncService = ref.read(postLoginSyncServiceProvider);
  final isOnline = ref.read(isOnlineProvider);
  final isWeb = ref.read(isWebProvider);

  return await syncService.executeSyncFlow(
    user: user,
    isOnline: isOnline,
    isWeb: isWeb,
  );
});

// Provider para estado da sincronização em andamento
class PostLoginSyncNotifier extends StateNotifier<AsyncValue<PostLoginSyncResult?>> {
  final PostLoginSyncService _syncService;
  final Ref _ref;

  PostLoginSyncNotifier({
    required PostLoginSyncService syncService,
    required Ref ref,
  })  : _syncService = syncService,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Executa a sincronização pós-login
  Future<void> executeSync(User user) async {
    state = const AsyncValue.loading();

    try {
      final isOnline = _ref.read(isOnlineProvider);
      final isWeb = _ref.read(isWebProvider);

      final result = await _syncService.executeSyncFlow(
        user: user,
        isOnline: isOnline,
        isWeb: isWeb,
      );

      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Limpa o estado
  void clear() {
    state = const AsyncValue.data(null);
  }
}

// Provider para o notifier
final postLoginSyncNotifierProvider = StateNotifierProvider<PostLoginSyncNotifier, AsyncValue<PostLoginSyncResult?>>((ref) {
  final syncService = ref.read(postLoginSyncServiceProvider);
  
  return PostLoginSyncNotifier(
    syncService: syncService,
    ref: ref,
  );
});

// Providers de conveniência para status específicos
final isSyncingProvider = Provider<bool>((ref) {
  final syncState = ref.watch(postLoginSyncNotifierProvider);
  return syncState.isLoading;
});

final syncErrorProvider = Provider<String?>((ref) {
  final syncState = ref.watch(postLoginSyncNotifierProvider);
  return syncState.maybeWhen(
    error: (error, _) => error.toString(),
    orElse: () => null,
  );
});

final syncResultProvider = Provider<PostLoginSyncResult?>((ref) {
  final syncState = ref.watch(postLoginSyncNotifierProvider);
  return syncState.maybeWhen(
    data: (result) => result,
    orElse: () => null,
  );
});

// Provider para verificar se deve mostrar indicador de sincronização
final shouldShowSyncIndicatorProvider = Provider<bool>((ref) {
  final syncState = ref.watch(postLoginSyncNotifierProvider);
  return syncState.isLoading;
});

// Provider para progresso da sincronização (para UX)
final syncProgressProvider = Provider<SyncProgress>((ref) {
  final syncState = ref.watch(postLoginSyncNotifierProvider);
  final isLoading = syncState.isLoading;
  
  if (!isLoading) {
    return SyncProgress.completed();
  }
  
  // Durante loading, assumir progresso básico
  return SyncProgress(
    isActive: true,
    currentStep: SyncStep.checkingFiles,
    totalSteps: 3,
    currentStepProgress: 0.5,
    message: 'Verificando atualizações...',
  );
});

/// Informações de progresso da sincronização
class SyncProgress {
  final bool isActive;
  final SyncStep currentStep;
  final int totalSteps;
  final double currentStepProgress; // 0.0 to 1.0
  final String message;

  SyncProgress({
    required this.isActive,
    required this.currentStep,
    required this.totalSteps,
    required this.currentStepProgress,
    required this.message,
  });

  factory SyncProgress.completed() => SyncProgress(
    isActive: false,
    currentStep: SyncStep.completed,
    totalSteps: 3,
    currentStepProgress: 1.0,
    message: 'Sincronização concluída',
  );

  double get overallProgress => 
    (currentStep.index + currentStepProgress) / totalSteps;

  int get currentStepNumber => currentStep.index + 1;
}

/// Etapas da sincronização
enum SyncStep {
  checkingFiles,
  downloadingFiles,
  syncingMenus,
  completed,
}