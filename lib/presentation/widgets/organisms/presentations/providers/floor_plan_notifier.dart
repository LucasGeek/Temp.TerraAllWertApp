import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../domain/entities/floor_plan_data.dart';
import '../../../../../infra/logging/app_logger.dart';
import '../../../../../infra/storage/floor_plan_storage.dart';
import 'floor_plan_state.dart';

/// StateNotifier para gerenciar estado do FloorPlanPresentation
class FloorPlanNotifier extends StateNotifier<FloorPlanState> {
  final FloorPlanStorage _floorPlanStorage;
  final String _route;
  final Uuid _uuid = const Uuid();

  FloorPlanNotifier(
    this._floorPlanStorage,
    this._route,
  ) : super(FloorPlanState.initial());

  /// Carrega dados da planta do storage
  Future<void> loadFloorPlanData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final data = await _floorPlanStorage.loadFloorPlanData(_route);
      
      // Se não há dados salvos, cria estrutura básica
      final floorPlanData = data ?? FloorPlanData(
        id: _uuid.v4(),
        routeId: _route,
        createdAt: DateTime.now(),
      );
      
      state = state.copyWith(
        floorPlanData: floorPlanData,
        isLoading: false,
      );

      // Define o pavimento atual se houver dados e pavimentos
      if (state.floorPlanData != null && state.floorPlanData!.floors.isNotEmpty) {
        state = state.copyWith(currentFloor: state.floorPlanData!.floors.first);
      }
      
      AppLogger.debug(
        'Dados da planta carregados: ${state.floorPlanData?.floors.length ?? 0} pavimentos',
        tag: 'FloorPlan',
      );
    } catch (e) {
      // Se há erro no carregamento (dados corrompidos, etc.), cria estrutura nova
      AppLogger.warning('Erro ao carregar dados existentes, criando nova estrutura: $e', tag: 'FloorPlan');
      
      // Tenta limpar dados corrompidos e criar nova estrutura
      try {
        await _floorPlanStorage.deleteFloorPlanData(_route);
      } catch (deleteError) {
        AppLogger.warning('Não foi possível limpar dados corrompidos: $deleteError', tag: 'FloorPlan');
      }
      
      // Cria estrutura básica nova
      final floorPlanData = FloorPlanData(
        id: _uuid.v4(),
        routeId: _route,
        createdAt: DateTime.now(),
      );
      
      state = state.copyWith(
        floorPlanData: floorPlanData,
        isLoading: false,
        error: null, // Remove o erro já que resolvemos criando nova estrutura
      );
      
      AppLogger.info('Nova estrutura de planta criada para rota: $_route', tag: 'FloorPlan');
    }
  }

  /// Salva dados no storage
  Future<void> saveFloorPlanData() async {
    if (state.floorPlanData == null) return;

    try {
      await _floorPlanStorage.saveFloorPlanData(state.floorPlanData!);
      AppLogger.debug('Dados da planta salvos com sucesso', tag: 'FloorPlan');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao salvar dados: $e');
      AppLogger.error('Erro ao salvar FloorPlanData: $e', tag: 'FloorPlan');
    }
  }

  /// Define o pavimento atual
  void setCurrentFloor(Floor floor) {
    state = state.copyWith(currentFloor: floor);
    AppLogger.debug('Pavimento atual alterado: ${floor.number}', tag: 'FloorPlan');
  }

  /// Alterna modo de edição de marcadores
  void toggleEditingMarkers() {
    state = state.copyWith(isEditingMarkers: !state.isEditingMarkers);
    AppLogger.debug(
      'Modo edição marcadores: ${state.isEditingMarkers ? "ATIVO" : "INATIVO"}',
      tag: 'FloorPlan',
    );
  }

  /// Adiciona novo pavimento
  Future<void> addFloor(String number, String? imagePath, Uint8List? imageBytes) async {
    if (state.floorPlanData == null) return;

    try {
      final newFloor = Floor(
        id: _uuid.v4(),
        number: number,
        floorPlanImagePath: imagePath,
        markers: [],
      );

      final updatedFloors = [...state.floorPlanData!.floors, newFloor];
      final updatedData = state.floorPlanData!.copyWith(floors: updatedFloors);

      // Adicionar bytes da imagem se fornecido
      Map<String, Uint8List> updatedImageBytesMap = Map.from(state.floorImageBytesMap);
      if (imageBytes != null) {
        updatedImageBytesMap[newFloor.id] = imageBytes;
      }

      state = state.copyWith(
        floorPlanData: updatedData,
        currentFloor: newFloor,
        floorImageBytesMap: updatedImageBytesMap,
      );

      await saveFloorPlanData();
      AppLogger.debug('Novo pavimento adicionado: $number', tag: 'FloorPlan');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao adicionar pavimento: $e');
      AppLogger.error('Erro ao adicionar pavimento: $e', tag: 'FloorPlan');
    }
  }

  /// Remove pavimento
  Future<void> removeFloor(String floorId) async {
    if (state.floorPlanData == null) return;

    try {
      final updatedFloors = state.floorPlanData!.floors.where((f) => f.id != floorId).toList();
      final updatedData = state.floorPlanData!.copyWith(floors: updatedFloors);

      // Remover bytes da imagem
      Map<String, Uint8List> updatedImageBytesMap = Map.from(state.floorImageBytesMap);
      updatedImageBytesMap.remove(floorId);

      Floor? newCurrentFloor;
      if (updatedFloors.isNotEmpty) {
        newCurrentFloor = state.currentFloor?.id == floorId 
            ? updatedFloors.first 
            : state.currentFloor;
      }

      state = state.copyWith(
        floorPlanData: updatedData,
        currentFloor: newCurrentFloor,
        floorImageBytesMap: updatedImageBytesMap,
      );

      await saveFloorPlanData();
      AppLogger.debug('Pavimento removido: $floorId', tag: 'FloorPlan');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao remover pavimento: $e');
      AppLogger.error('Erro ao remover pavimento: $e', tag: 'FloorPlan');
    }
  }

  /// Adiciona marcador ao pavimento atual
  Future<void> addMarker(FloorMarker marker) async {
    if (state.floorPlanData == null || state.currentFloor == null) return;

    try {
      final updatedMarkers = [...state.currentFloor!.markers, marker];
      final updatedFloor = state.currentFloor!.copyWith(markers: updatedMarkers);
      final updatedFloors = state.floorPlanData!.floors.map((floor) =>
          floor.id == updatedFloor.id ? updatedFloor : floor).toList();
      final updatedData = state.floorPlanData!.copyWith(floors: updatedFloors);

      state = state.copyWith(
        floorPlanData: updatedData,
        currentFloor: updatedFloor,
      );

      await saveFloorPlanData();
      AppLogger.debug('Marcador adicionado: ${marker.markerType}', tag: 'FloorPlan');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao adicionar marcador: $e');
      AppLogger.error('Erro ao adicionar marcador: $e', tag: 'FloorPlan');
    }
  }

  /// Remove marcador
  Future<void> removeMarker(String markerId) async {
    if (state.floorPlanData == null || state.currentFloor == null) return;

    try {
      final updatedMarkers = state.currentFloor!.markers.where((m) => m.id != markerId).toList();
      final updatedFloor = state.currentFloor!.copyWith(markers: updatedMarkers);
      final updatedFloors = state.floorPlanData!.floors.map((floor) =>
          floor.id == updatedFloor.id ? updatedFloor : floor).toList();
      final updatedData = state.floorPlanData!.copyWith(floors: updatedFloors);

      state = state.copyWith(
        floorPlanData: updatedData,
        currentFloor: updatedFloor,
      );

      await saveFloorPlanData();
      AppLogger.debug('Marcador removido: $markerId', tag: 'FloorPlan');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao remover marcador: $e');
      AppLogger.error('Erro ao remover marcador: $e', tag: 'FloorPlan');
    }
  }

  /// Atualiza imagem bytes do pavimento
  void updateFloorImageBytes(String floorId, Uint8List bytes) {
    final updatedMap = Map<String, Uint8List>.from(state.floorImageBytesMap);
    updatedMap[floorId] = bytes;
    state = state.copyWith(floorImageBytesMap: updatedMap);
  }

  /// Limpa erro
  void clearError() {
    state = state.copyWith(error: null);
  }

}

/// Provider do StateNotifier
final floorPlanNotifierProvider = StateNotifierProviderFamily<FloorPlanNotifier, FloorPlanState, String>(
  (ref, route) {
    final floorPlanStorage = FloorPlanStorage();
    return FloorPlanNotifier(floorPlanStorage, route);
  },
);

/// Provider apenas do estado atual
final floorPlanStateProvider = ProviderFamily<FloorPlanState, String>(
  (ref, route) => ref.watch(floorPlanNotifierProvider(route)),
);

/// Provider apenas do pavimento atual
final currentFloorProvider = ProviderFamily<Floor?, String>(
  (ref, route) => ref.watch(floorPlanStateProvider(route)).currentFloor,
);

/// Provider para verificar se está carregando
final isLoadingProvider = ProviderFamily<bool, String>(
  (ref, route) => ref.watch(floorPlanStateProvider(route)).isLoading,
);

/// Provider para verificar se está editando marcadores
final isEditingMarkersProvider = ProviderFamily<bool, String>(
  (ref, route) => ref.watch(floorPlanStateProvider(route)).isEditingMarkers,
);