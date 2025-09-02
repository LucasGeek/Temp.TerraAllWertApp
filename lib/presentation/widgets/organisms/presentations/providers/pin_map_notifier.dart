import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../../domain/entities/map_pin.dart';
import '../../../../../domain/enums/pin_content_type.dart';
import '../../../../../infra/logging/app_logger.dart';
import '../../../../../infra/graphql/presentation_sync_service.dart';
import '../../../../providers/presentation_sync_provider.dart';
import 'pin_map_state.dart';

/// StateNotifier para gerenciar estado do PinMapPresentation
class PinMapNotifier extends StateNotifier<PinMapState> {
  final PresentationSyncService _syncService;
  final String _route;
  final Uuid _uuid = const Uuid();

  PinMapNotifier(
    this._syncService,
    this._route,
  ) : super(PinMapState.initial());

  /// Carrega dados do mapa do storage com sync da API
  Future<void> loadMapData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Tentar buscar da API primeiro, com fallback para cache local
      var data = await _syncService.fetchPinMapData(_route);
      
      // Se não há dados salvos, cria estrutura básica
      final mapData = data ?? InteractiveMapData(
        id: _uuid.v4(),
        routeId: _route,
        backgroundImageUrl: null,
        pins: [],
        createdAt: DateTime.now(),
      );
      
      state = state.copyWith(
        mapData: mapData,
        isLoading: false,
      );
      
      AppLogger.debug(
        'Dados do mapa carregados: ${state.mapData?.pins.length ?? 0} pins',
        tag: 'PinMap',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        error: 'Erro ao carregar dados do mapa: $e',
      );
      AppLogger.error('Erro ao carregar MapData: $e', tag: 'PinMap');
    }
  }

  /// Salva dados no storage e sincroniza com API
  Future<void> saveMapData() async {
    if (state.mapData == null) return;

    try {
      // Salva localmente e sincroniza com API
      final updatedData = await _syncService.savePinMapData(state.mapData!);
      if (updatedData != null) {
        state = state.copyWith(mapData: updatedData);
      }
      AppLogger.debug('Dados do mapa salvos e sincronizados', tag: 'PinMap');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao salvar dados: $e');
      AppLogger.error('Erro ao salvar MapData: $e', tag: 'PinMap');
    }
  }

  /// Alterna modo de edição
  void toggleEditMode() {
    state = state.copyWith(
      isEditMode: !state.isEditMode,
      selectedPin: null, // Limpa seleção ao mudar modo
    );
    AppLogger.debug(
      'Modo edição: ${state.isEditMode ? "ATIVO" : "INATIVO"}',
      tag: 'PinMap',
    );
  }

  /// Define pin selecionado
  void selectPin(MapPin pin) {
    state = state.copyWith(selectedPin: pin);
    AppLogger.debug('Pin selecionado: ${pin.title}', tag: 'PinMap');
  }

  /// Limpa seleção de pin
  void clearSelection() {
    state = state.clearSelectedPin();
    AppLogger.debug('Seleção de pin limpa', tag: 'PinMap');
  }

  /// Adiciona novo pin
  Future<void> addPin({
    required String title,
    required String description,
    required double positionX,
    required double positionY,
    required PinContentType contentType,
    List<String> imageUrls = const [],
    List<String> imagePaths = const [],
  }) async {
    if (state.mapData == null) return;

    try {
      final newPin = MapPin(
        id: _uuid.v4(),
        title: title,
        description: description,
        positionX: positionX,
        positionY: positionY,
        contentType: contentType,
        imageUrls: imageUrls,
        imagePaths: imagePaths,
        createdAt: DateTime.now(),
      );

      // Usar sync service para adicionar o pin
      final syncedPin = await _syncService.upsertMapPin(state.mapData!.routeId, newPin);
      
      if (syncedPin != null) {
        final updatedPins = [...state.mapData!.pins, syncedPin];
        final updatedData = state.mapData!.copyWith(pins: updatedPins);
        state = state.copyWith(mapData: updatedData);
      }
      
      AppLogger.debug('Pin adicionado: $title', tag: 'PinMap');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao adicionar pin: $e');
      AppLogger.error('Erro ao adicionar pin: $e', tag: 'PinMap');
    }
  }

  /// Remove pin
  Future<void> removePin(String pinId) async {
    if (state.mapData == null) return;

    try {
      // Usar sync service para deletar o pin
      final success = await _syncService.deleteMapPin(state.mapData!.routeId, pinId);
      
      if (success) {
        final updatedPins = state.mapData!.pins.where((p) => p.id != pinId).toList();
        final updatedData = state.mapData!.copyWith(pins: updatedPins);

        state = state.copyWith(
          mapData: updatedData,
          selectedPin: state.selectedPin?.id == pinId ? null : state.selectedPin,
        );
        
        AppLogger.debug('Pin removido e sincronizado: $pinId', tag: 'PinMap');
      } else {
        throw Exception('Falha ao deletar pin');
      }
    } catch (e) {
      state = state.copyWith(error: 'Erro ao remover pin: $e');
      AppLogger.error('Erro ao remover pin: $e', tag: 'PinMap');
    }
  }

  /// Atualiza pin existente
  Future<void> updatePin(MapPin updatedPin) async {
    if (state.mapData == null) return;

    try {
      final updatedPins = state.mapData!.pins.map((pin) =>
          pin.id == updatedPin.id ? updatedPin : pin).toList();
      final updatedData = state.mapData!.copyWith(pins: updatedPins);

      state = state.copyWith(
        mapData: updatedData,
        selectedPin: state.selectedPin?.id == updatedPin.id ? updatedPin : state.selectedPin,
      );
      
      await saveMapData();
      AppLogger.debug('Pin atualizado: ${updatedPin.title}', tag: 'PinMap');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao atualizar pin: $e');
      AppLogger.error('Erro ao atualizar pin: $e', tag: 'PinMap');
    }
  }

  /// Define estado de zoom
  void setZoomed(bool isZoomed) {
    state = state.copyWith(isZoomed: isZoomed);
  }

  /// Define controlador de vídeo
  void setVideoController(VideoPlayerController? controller) {
    state = state.copyWith(videoController: controller);
  }

  /// Atualiza dados do mapa (imagem de fundo, vídeo, etc.)
  Future<void> updateMapData({
    String? backgroundImageUrl,
    String? backgroundImagePath,
    String? videoUrl,
    String? videoPath,
    String? videoTitle,
  }) async {
    if (state.mapData == null) return;

    try {
      final updatedData = state.mapData!.copyWith(
        backgroundImageUrl: backgroundImageUrl ?? state.mapData!.backgroundImageUrl,
        backgroundImagePath: backgroundImagePath ?? state.mapData!.backgroundImagePath,
        videoUrl: videoUrl ?? state.mapData!.videoUrl,
        videoPath: videoPath ?? state.mapData!.videoPath,
        videoTitle: videoTitle ?? state.mapData!.videoTitle,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(mapData: updatedData);
      await saveMapData();
      
      AppLogger.debug('Dados do mapa atualizados', tag: 'PinMap');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao atualizar dados do mapa: $e');
      AppLogger.error('Erro ao atualizar dados do mapa: $e', tag: 'PinMap');
    }
  }

  /// Limpa erro
  void clearError() {
    state = state.clearError();
  }

}

/// Provider do StateNotifier
final pinMapNotifierProvider = StateNotifierProviderFamily<PinMapNotifier, PinMapState, String>(
  (ref, route) {
    final syncService = ref.watch(presentationSyncServiceProvider);
    return PinMapNotifier(syncService, route);
  },
);

/// Provider apenas do estado atual
final pinMapStateProvider = ProviderFamily<PinMapState, String>(
  (ref, route) => ref.watch(pinMapNotifierProvider(route)),
);

/// Provider apenas do pin selecionado
final selectedPinProvider = ProviderFamily<MapPin?, String>(
  (ref, route) => ref.watch(pinMapStateProvider(route)).selectedPin,
);

/// Provider para verificar se está carregando
final isLoadingPinMapProvider = ProviderFamily<bool, String>(
  (ref, route) => ref.watch(pinMapStateProvider(route)).isLoading,
);

/// Provider para verificar se está em modo de edição
final isEditModeProvider = ProviderFamily<bool, String>(
  (ref, route) => ref.watch(pinMapStateProvider(route)).isEditMode,
);

/// Provider para verificar se está com zoom
final isZoomedProvider = ProviderFamily<bool, String>(
  (ref, route) => ref.watch(pinMapStateProvider(route)).isZoomed,
);