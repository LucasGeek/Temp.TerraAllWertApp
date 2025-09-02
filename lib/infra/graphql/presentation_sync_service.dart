import 'package:graphql/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/map_pin.dart';
import '../../domain/entities/carousel_data.dart';
import '../../domain/entities/floor_plan_data.dart';
import '../logging/app_logger.dart';
import '../storage/map_data_storage.dart';
import '../storage/carousel_data_storage.dart';
import '../storage/floor_plan_storage.dart';
import 'graphql_client.dart';
import 'queries/presentation_queries.dart';
import 'mutations/presentation_mutations.dart';

/// Serviço de sincronização para presentations
class PresentationSyncService {
  final GraphQLClientService _graphqlClient;
  final MapDataStorage _mapStorage;
  final CarouselDataStorage _carouselStorage;
  final FloorPlanStorage _floorPlanStorage;
  
  static const String _syncTimestampPrefix = 'presentation_sync_';

  PresentationSyncService({
    required GraphQLClientService graphqlClient,
    MapDataStorage? mapStorage,
    CarouselDataStorage? carouselStorage,
    FloorPlanStorage? floorPlanStorage,
  }) : _graphqlClient = graphqlClient,
       _mapStorage = mapStorage ?? MapDataStorage(),
       _carouselStorage = carouselStorage ?? CarouselDataStorage(),
       _floorPlanStorage = floorPlanStorage ?? FloorPlanStorage();

  // ========== PinMapPresentation Sync ==========

  /// Busca dados do PinMap da API
  Future<InteractiveMapData?> fetchPinMapData(String routeId) async {
    try {
      AppLogger.info('Fetching PinMap data for route: $routeId', tag: 'PresentationSync');

      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(getPinMapDataQuery),
          variables: {'routeId': routeId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error fetching PinMap data: ${result.exception}', tag: 'PresentationSync');
        
        // Tentar buscar do cache local se a API falhar
        return await _mapStorage.loadMapData(routeId);
      }

      final data = result.data?['getPinMapData'];
      if (data != null) {
        final mapData = InteractiveMapData.fromJson(data as Map<String, dynamic>);
        
        // Salvar no cache local
        await _mapStorage.saveMapData(mapData);
        await _updateSyncTimestamp('pinmap_$routeId');
        
        AppLogger.info('PinMap data fetched and cached for route: $routeId', tag: 'PresentationSync');
        return mapData;
      }

      // Se não houver dados na API, verificar cache local
      return await _mapStorage.loadMapData(routeId);
      
    } catch (e) {
      AppLogger.error('Failed to fetch PinMap data: $e', tag: 'PresentationSync');
      
      // Fallback para cache local
      return await _mapStorage.loadMapData(routeId);
    }
  }

  /// Salva ou atualiza PinMapData
  Future<InteractiveMapData?> savePinMapData(InteractiveMapData mapData) async {
    try {
      AppLogger.info('Saving PinMap data for route: ${mapData.routeId}', tag: 'PresentationSync');

      // Salvar localmente primeiro
      await _mapStorage.saveMapData(mapData);

      // Sincronizar com a API
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(upsertPinMapDataMutation),
          variables: {
            'input': {
              'id': mapData.id,
              'routeId': mapData.routeId,
              'backgroundImageUrl': mapData.backgroundImageUrl,
              'backgroundImagePath': mapData.backgroundImagePath,
              'videoUrl': mapData.videoUrl,
              'videoPath': mapData.videoPath,
              'videoTitle': mapData.videoTitle,
              'pins': mapData.pins.map((pin) => {
                'id': pin.id,
                'title': pin.title,
                'description': pin.description,
                'positionX': pin.positionX,
                'positionY': pin.positionY,
                'contentType': pin.contentType.toString().split('.').last,
                'imageUrls': pin.imageUrls,
                'imagePaths': pin.imagePaths,
              }).toList(),
            }
          },
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error saving PinMap data: ${result.exception}', tag: 'PresentationSync');
        return mapData; // Retornar dados locais mesmo se API falhar
      }

      final updatedData = result.data?['upsertPinMapData'];
      if (updatedData != null) {
        final syncedMapData = InteractiveMapData.fromJson(updatedData as Map<String, dynamic>);
        
        // Atualizar cache local com dados sincronizados
        await _mapStorage.saveMapData(syncedMapData);
        await _updateSyncTimestamp('pinmap_${syncedMapData.routeId}');
        
        AppLogger.info('PinMap data synchronized successfully', tag: 'PresentationSync');
        return syncedMapData;
      }

      return mapData;
      
    } catch (e) {
      AppLogger.error('Failed to save PinMap data: $e', tag: 'PresentationSync');
      return mapData; // Retornar dados locais em caso de erro
    }
  }

  /// Adiciona ou atualiza um pin
  Future<MapPin?> upsertMapPin(String routeId, MapPin pin) async {
    try {
      AppLogger.info('Upserting pin ${pin.id} for route: $routeId', tag: 'PresentationSync');

      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(upsertMapPinMutation),
          variables: {
            'routeId': routeId,
            'pin': {
              'id': pin.id,
              'title': pin.title,
              'description': pin.description,
              'positionX': pin.positionX,
              'positionY': pin.positionY,
              'contentType': pin.contentType.toString().split('.').last,
              'imageUrls': pin.imageUrls,
              'imagePaths': pin.imagePaths,
            }
          },
        ),
      );

      if (!result.hasException && result.data?['upsertMapPin'] != null) {
        final updatedPin = MapPin.fromJson(result.data!['upsertMapPin'] as Map<String, dynamic>);
        
        // Atualizar cache local
        final mapData = await _mapStorage.loadMapData(routeId);
        if (mapData != null) {
          final pins = List<MapPin>.from(mapData.pins);
          final index = pins.indexWhere((p) => p.id == updatedPin.id);
          if (index >= 0) {
            pins[index] = updatedPin;
          } else {
            pins.add(updatedPin);
          }
          
          final updatedMapData = mapData.copyWith(
            pins: pins,
            updatedAt: DateTime.now(),
          );
          await _mapStorage.saveMapData(updatedMapData);
        }
        
        return updatedPin;
      }

      return pin;
      
    } catch (e) {
      AppLogger.error('Failed to upsert pin: $e', tag: 'PresentationSync');
      return pin;
    }
  }

  /// Deleta um pin
  Future<bool> deleteMapPin(String routeId, String pinId) async {
    try {
      AppLogger.info('Deleting pin $pinId from route: $routeId', tag: 'PresentationSync');

      // Remover do cache local primeiro
      final mapData = await _mapStorage.loadMapData(routeId);
      if (mapData != null) {
        final pins = mapData.pins.where((p) => p.id != pinId).toList();
        final updatedMapData = mapData.copyWith(
          pins: pins,
          updatedAt: DateTime.now(),
        );
        await _mapStorage.saveMapData(updatedMapData);
      }

      // Sincronizar com a API
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(deleteMapPinMutation),
          variables: {
            'routeId': routeId,
            'pinId': pinId,
          },
        ),
      );

      return !result.hasException && result.data?['deleteMapPin']?['success'] == true;
      
    } catch (e) {
      AppLogger.error('Failed to delete pin: $e', tag: 'PresentationSync');
      return true; // Considerar sucesso se removido localmente
    }
  }

  // ========== ImageCarouselPresentation Sync ==========

  /// Busca dados do Carousel da API
  Future<CarouselData?> fetchCarouselData(String routeId) async {
    try {
      AppLogger.info('Fetching Carousel data for route: $routeId', tag: 'PresentationSync');

      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(getCarouselDataQuery),
          variables: {'routeId': routeId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error fetching Carousel data: ${result.exception}', tag: 'PresentationSync');
        
        // Tentar buscar do cache local se a API falhar
        return await _carouselStorage.loadCarouselData(routeId);
      }

      final data = result.data?['getCarouselData'];
      if (data != null) {
        final carouselData = CarouselData.fromJson(data as Map<String, dynamic>);
        
        // Salvar no cache local
        await _carouselStorage.saveCarouselData(carouselData);
        await _updateSyncTimestamp('carousel_$routeId');
        
        AppLogger.info('Carousel data fetched and cached for route: $routeId', tag: 'PresentationSync');
        return carouselData;
      }

      // Se não houver dados na API, verificar cache local
      return await _carouselStorage.loadCarouselData(routeId);
      
    } catch (e) {
      AppLogger.error('Failed to fetch Carousel data: $e', tag: 'PresentationSync');
      
      // Fallback para cache local
      return await _carouselStorage.loadCarouselData(routeId);
    }
  }

  /// Salva ou atualiza CarouselData
  Future<CarouselData?> saveCarouselData(CarouselData carouselData) async {
    try {
      AppLogger.info('Saving Carousel data for route: ${carouselData.routeId}', tag: 'PresentationSync');

      // Salvar localmente primeiro
      await _carouselStorage.saveCarouselData(carouselData);

      // Sincronizar com a API
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(upsertCarouselDataMutation),
          variables: {
            'input': {
              'id': carouselData.id,
              'routeId': carouselData.routeId,
              'imageUrls': carouselData.imageUrls,
              'imagePaths': carouselData.imagePaths,
              'videoUrl': carouselData.videoUrl,
              'videoPath': carouselData.videoPath,
              'videoTitle': carouselData.videoTitle,
              'textBox': carouselData.textBox != null ? {
                'id': carouselData.textBox!.id,
                'text': carouselData.textBox!.text,
                'fontSize': carouselData.textBox!.fontSize,
                'fontColor': carouselData.textBox!.fontColor,
                'backgroundColor': carouselData.textBox!.backgroundColor,
                'positionX': carouselData.textBox!.positionX,
                'positionY': carouselData.textBox!.positionY,
              } : null,
              'mapConfig': carouselData.mapConfig != null ? {
                'id': carouselData.mapConfig!.id,
                'latitude': carouselData.mapConfig!.latitude,
                'longitude': carouselData.mapConfig!.longitude,
                'mapType': carouselData.mapConfig!.mapType.toString().split('.').last,
                'zoom': carouselData.mapConfig!.zoom,
              } : null,
            }
          },
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error saving Carousel data: ${result.exception}', tag: 'PresentationSync');
        return carouselData; // Retornar dados locais mesmo se API falhar
      }

      final updatedData = result.data?['upsertCarouselData'];
      if (updatedData != null) {
        final syncedCarouselData = CarouselData.fromJson(updatedData as Map<String, dynamic>);
        
        // Atualizar cache local com dados sincronizados
        await _carouselStorage.saveCarouselData(syncedCarouselData);
        await _updateSyncTimestamp('carousel_${syncedCarouselData.routeId}');
        
        AppLogger.info('Carousel data synchronized successfully', tag: 'PresentationSync');
        return syncedCarouselData;
      }

      return carouselData;
      
    } catch (e) {
      AppLogger.error('Failed to save Carousel data: $e', tag: 'PresentationSync');
      return carouselData; // Retornar dados locais em caso de erro
    }
  }

  // ========== FloorPlanPresentation Sync ==========

  /// Busca dados do FloorPlan da API
  Future<FloorPlanData?> fetchFloorPlanData(String routeId) async {
    try {
      AppLogger.info('Fetching FloorPlan data for route: $routeId', tag: 'PresentationSync');

      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(getFloorPlanDataQuery),
          variables: {'routeId': routeId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error fetching FloorPlan data: ${result.exception}', tag: 'PresentationSync');
        
        // Tentar buscar do cache local se a API falhar
        return await _floorPlanStorage.loadFloorPlanData(routeId);
      }

      final data = result.data?['getFloorPlanData'];
      if (data != null) {
        final floorPlanData = FloorPlanData.fromJson(data as Map<String, dynamic>);
        
        // Salvar no cache local
        await _floorPlanStorage.saveFloorPlanData(floorPlanData);
        await _updateSyncTimestamp('floorplan_$routeId');
        
        AppLogger.info('FloorPlan data fetched and cached for route: $routeId', tag: 'PresentationSync');
        return floorPlanData;
      }

      // Se não houver dados na API, verificar cache local
      return await _floorPlanStorage.loadFloorPlanData(routeId);
      
    } catch (e) {
      AppLogger.error('Failed to fetch FloorPlan data: $e', tag: 'PresentationSync');
      
      // Fallback para cache local
      return await _floorPlanStorage.loadFloorPlanData(routeId);
    }
  }

  /// Salva ou atualiza FloorPlanData
  Future<FloorPlanData?> saveFloorPlanData(FloorPlanData floorPlanData) async {
    try {
      AppLogger.info('Saving FloorPlan data for route: ${floorPlanData.routeId}', tag: 'PresentationSync');

      // Salvar localmente primeiro
      await _floorPlanStorage.saveFloorPlanData(floorPlanData);

      // Sincronizar com a API
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(upsertFloorPlanDataMutation),
          variables: {
            'input': {
              'id': floorPlanData.id,
              'routeId': floorPlanData.routeId,
              'floors': floorPlanData.floors.map((floor) => {
                'id': floor.id,
                'number': floor.number,
                'floorPlanImageUrl': floor.floorPlanImageUrl,
                'floorPlanImagePath': floor.floorPlanImagePath,
                'markers': floor.markers.map((marker) => {
                  'id': marker.id,
                  'title': marker.title,
                  'description': marker.description,
                  'positionX': marker.positionX,
                  'positionY': marker.positionY,
                  'markerType': marker.markerType.toString().split('.').last,
                  'apartmentId': marker.apartmentId,
                }).toList(),
                'description': floor.description,
              }).toList(),
              'apartments': floorPlanData.apartments.map((apt) => {
                'id': apt.id,
                'number': apt.number,
                'area': apt.area,
                'bedrooms': apt.bedrooms,
                'suites': apt.suites,
                'sunPosition': apt.sunPosition.toString().split('.').last,
                'status': apt.status.toString().split('.').last,
                'floorPlanImageUrl': apt.floorPlanImageUrl,
                'floorPlanImagePath': apt.floorPlanImagePath,
                'description': apt.description,
              }).toList(),
            }
          },
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error saving FloorPlan data: ${result.exception}', tag: 'PresentationSync');
        return floorPlanData; // Retornar dados locais mesmo se API falhar
      }

      final updatedData = result.data?['upsertFloorPlanData'];
      if (updatedData != null) {
        final syncedFloorPlanData = FloorPlanData.fromJson(updatedData as Map<String, dynamic>);
        
        // Atualizar cache local com dados sincronizados
        await _floorPlanStorage.saveFloorPlanData(syncedFloorPlanData);
        await _updateSyncTimestamp('floorplan_${syncedFloorPlanData.routeId}');
        
        AppLogger.info('FloorPlan data synchronized successfully', tag: 'PresentationSync');
        return syncedFloorPlanData;
      }

      return floorPlanData;
      
    } catch (e) {
      AppLogger.error('Failed to save FloorPlan data: $e', tag: 'PresentationSync');
      return floorPlanData; // Retornar dados locais em caso de erro
    }
  }

  /// Adiciona ou atualiza um Floor
  Future<Floor?> upsertFloor(String routeId, Floor floor) async {
    try {
      AppLogger.info('Upserting floor ${floor.id} for route: $routeId', tag: 'PresentationSync');

      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(upsertFloorMutation),
          variables: {
            'routeId': routeId,
            'floor': {
              'id': floor.id,
              'number': floor.number,
              'floorPlanImageUrl': floor.floorPlanImageUrl,
              'floorPlanImagePath': floor.floorPlanImagePath,
              'markers': floor.markers.map((marker) => {
                'id': marker.id,
                'title': marker.title,
                'description': marker.description,
                'positionX': marker.positionX,
                'positionY': marker.positionY,
                'markerType': marker.markerType.toString().split('.').last,
                'apartmentId': marker.apartmentId,
              }).toList(),
              'description': floor.description,
            }
          },
        ),
      );

      if (!result.hasException && result.data?['upsertFloor'] != null) {
        final updatedFloor = Floor.fromJson(result.data!['upsertFloor'] as Map<String, dynamic>);
        
        // Atualizar cache local
        final floorPlanData = await _floorPlanStorage.loadFloorPlanData(routeId);
        if (floorPlanData != null) {
          final floors = List<Floor>.from(floorPlanData.floors);
          final index = floors.indexWhere((f) => f.id == updatedFloor.id);
          if (index >= 0) {
            floors[index] = updatedFloor;
          } else {
            floors.add(updatedFloor);
          }
          
          final updatedFloorPlanData = floorPlanData.copyWith(
            floors: floors,
            updatedAt: DateTime.now(),
          );
          await _floorPlanStorage.saveFloorPlanData(updatedFloorPlanData);
        }
        
        return updatedFloor;
      }

      return floor;
      
    } catch (e) {
      AppLogger.error('Failed to upsert floor: $e', tag: 'PresentationSync');
      return floor;
    }
  }

  /// Adiciona ou atualiza um Apartment
  Future<Apartment?> upsertApartment(String routeId, Apartment apartment) async {
    try {
      AppLogger.info('Upserting apartment ${apartment.id} for route: $routeId', tag: 'PresentationSync');

      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(upsertApartmentMutation),
          variables: {
            'routeId': routeId,
            'apartment': {
              'id': apartment.id,
              'number': apartment.number,
              'area': apartment.area,
              'bedrooms': apartment.bedrooms,
              'suites': apartment.suites,
              'sunPosition': apartment.sunPosition.toString().split('.').last,
              'status': apartment.status.toString().split('.').last,
              'floorPlanImageUrl': apartment.floorPlanImageUrl,
              'floorPlanImagePath': apartment.floorPlanImagePath,
              'description': apartment.description,
            }
          },
        ),
      );

      if (!result.hasException && result.data?['upsertApartment'] != null) {
        final updatedApartment = Apartment.fromJson(result.data!['upsertApartment'] as Map<String, dynamic>);
        
        // Atualizar cache local
        final floorPlanData = await _floorPlanStorage.loadFloorPlanData(routeId);
        if (floorPlanData != null) {
          final apartments = List<Apartment>.from(floorPlanData.apartments);
          final index = apartments.indexWhere((a) => a.id == updatedApartment.id);
          if (index >= 0) {
            apartments[index] = updatedApartment;
          } else {
            apartments.add(updatedApartment);
          }
          
          final updatedFloorPlanData = floorPlanData.copyWith(
            apartments: apartments,
            updatedAt: DateTime.now(),
          );
          await _floorPlanStorage.saveFloorPlanData(updatedFloorPlanData);
        }
        
        return updatedApartment;
      }

      return apartment;
      
    } catch (e) {
      AppLogger.error('Failed to upsert apartment: $e', tag: 'PresentationSync');
      return apartment;
    }
  }

  // ========== Sync Utilities ==========

  /// Verifica se há atualizações disponíveis para as presentations
  Future<bool> checkForUpdates(String routeId) async {
    try {
      final lastSyncTime = await _getLastSyncTime(routeId);
      
      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(checkPresentationsUpdatesQuery),
          variables: {
            'routeId': routeId,
            'lastSyncTime': lastSyncTime?.toIso8601String(),
          },
        ),
      );

      if (!result.hasException && result.data?['checkPresentationsUpdates'] != null) {
        final updates = result.data!['checkPresentationsUpdates'];
        return updates['hasUpdates'] == true;
      }

      return false;
      
    } catch (e) {
      AppLogger.error('Failed to check for updates: $e', tag: 'PresentationSync');
      return false;
    }
  }

  /// Sincroniza todas as presentations de uma rota
  Future<void> syncAllPresentations(String routeId) async {
    try {
      AppLogger.info('Starting full sync for route: $routeId', tag: 'PresentationSync');

      // Buscar dados atualizados da API
      await Future.wait([
        fetchPinMapData(routeId),
        fetchCarouselData(routeId),
        fetchFloorPlanData(routeId),
      ]);

      AppLogger.info('Full sync completed for route: $routeId', tag: 'PresentationSync');
      
    } catch (e) {
      AppLogger.error('Failed to sync all presentations: $e', tag: 'PresentationSync');
    }
  }

  /// Obtém timestamp da última sincronização
  Future<DateTime?> _getLastSyncTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString('$_syncTimestampPrefix$key');
      
      if (timestampString != null) {
        return DateTime.tryParse(timestampString);
      }
      
      return null;
    } catch (e) {
      AppLogger.warning('Failed to get last sync time: $e', tag: 'PresentationSync');
      return null;
    }
  }

  /// Atualiza timestamp da última sincronização
  Future<void> _updateSyncTimestamp(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_syncTimestampPrefix$key', DateTime.now().toIso8601String());
    } catch (e) {
      AppLogger.warning('Failed to update sync timestamp: $e', tag: 'PresentationSync');
    }
  }

  /// Limpa todos os dados de presentations localmente
  Future<void> clearAllLocalData(String routeId) async {
    try {
      await Future.wait([
        _mapStorage.deleteMapData(routeId),
        _carouselStorage.deleteCarouselData(routeId),
        _floorPlanStorage.deleteFloorPlanData(routeId),
      ]);
      
      AppLogger.info('Cleared all local presentation data for route: $routeId', tag: 'PresentationSync');
    } catch (e) {
      AppLogger.error('Failed to clear local data: $e', tag: 'PresentationSync');
    }
  }
}