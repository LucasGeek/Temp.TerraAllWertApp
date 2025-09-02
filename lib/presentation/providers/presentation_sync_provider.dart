import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/graphql/presentation_sync_service.dart';
import '../../infra/graphql/graphql_client.dart';
import '../../infra/storage/map_data_storage.dart';
import '../../infra/storage/carousel_data_storage.dart';
import '../../infra/storage/floor_plan_storage.dart';

/// Provider para o serviço de sincronização de presentations
final presentationSyncServiceProvider = Provider<PresentationSyncService>((ref) {
  final graphqlClient = ref.watch(graphQLClientProvider);
  
  return PresentationSyncService(
    graphqlClient: graphqlClient,
    mapStorage: MapDataStorage(),
    carouselStorage: CarouselDataStorage(),
    floorPlanStorage: FloorPlanStorage(),
  );
});

/// Provider para verificar se há atualizações disponíveis
final checkPresentationUpdatesProvider = FutureProvider.family<bool, String>((ref, routeId) async {
  final syncService = ref.read(presentationSyncServiceProvider);
  return await syncService.checkForUpdates(routeId);
});

/// Provider para sincronizar todas as presentations de uma rota
final syncAllPresentationsProvider = FutureProvider.family<void, String>((ref, routeId) async {
  final syncService = ref.read(presentationSyncServiceProvider);
  await syncService.syncAllPresentations(routeId);
});