import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../domain/entities/interactive_map_data.dart';
import '../../../../domain/entities/map_pin.dart';

/// Estado do mapa de pins
class PinMapState {
  final InteractiveMapData? mapData;
  final MapPin? selectedPin;
  final bool isEditMode;
  final bool isLoading;
  final bool hasError;
  final bool isZoomed;
  final VideoPlayerController? videoController;

  const PinMapState({
    this.mapData,
    this.selectedPin,
    this.isEditMode = false,
    this.isLoading = false,
    this.hasError = false,
    this.isZoomed = false,
    this.videoController,
  });

  PinMapState copyWith({
    InteractiveMapData? mapData,
    MapPin? selectedPin,
    bool? isEditMode,
    bool? isLoading,
    bool? hasError,
    bool? isZoomed,
    VideoPlayerController? videoController,
  }) {
    return PinMapState(
      mapData: mapData ?? this.mapData,
      selectedPin: selectedPin,
      isEditMode: isEditMode ?? this.isEditMode,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      isZoomed: isZoomed ?? this.isZoomed,
      videoController: videoController ?? this.videoController,
    );
  }
}

/// Provider de estado para o mapa de pins
final pinMapStateProvider = StateProvider.family<PinMapState, String>((ref, route) {
  return const PinMapState();
});

/// Notifier para gerenciar o estado do mapa de pins
class PinMapNotifier extends StateNotifier<PinMapState> {
  final String route;

  PinMapNotifier(this.route) : super(const PinMapState());

  Future<void> loadMapData() async {
    state = state.copyWith(isLoading: true, hasError: false);
    
    try {
      // TODO: Implementar carregamento real dos dados
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Para fins de demonstração, criar dados iniciais vazios
      final mapData = InteractiveMapData(
        id: 'map_$route',
        routeId: route,
        pins: [],
        createdAt: DateTime.now(),
      );
      
      state = state.copyWith(mapData: mapData, isLoading: false);
    } catch (e) {
      state = state.copyWith(hasError: true, isLoading: false);
    }
  }

  void selectPin(MapPin pin) {
    state = state.copyWith(selectedPin: pin);
  }

  void clearSelection() {
    state = state.copyWith(selectedPin: null);
  }

  void toggleEditMode() {
    state = state.copyWith(isEditMode: !state.isEditMode);
  }

  void setZoomed(bool isZoomed) {
    state = state.copyWith(isZoomed: isZoomed);
  }

  Future<void> addPin({
    required String title,
    required String description,
    required double positionX,
    required double positionY,
    required PinContentType contentType,
    required List<String> imageUrls,
  }) async {
    if (state.mapData == null) return;

    final newPin = MapPin(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      positionX: positionX,
      positionY: positionY,
      contentType: contentType,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    final updatedPins = [...state.mapData!.pins, newPin];
    final updatedMapData = state.mapData!.copyWith(
      pins: updatedPins,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(mapData: updatedMapData);
  }

  Future<void> updatePin(MapPin updatedPin) async {
    if (state.mapData == null) return;

    final updatedPins = state.mapData!.pins.map((pin) {
      return pin.id == updatedPin.id ? updatedPin : pin;
    }).toList();

    final updatedMapData = state.mapData!.copyWith(
      pins: updatedPins,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(mapData: updatedMapData);
  }

  Future<void> removePin(String pinId) async {
    if (state.mapData == null) return;

    final updatedPins = state.mapData!.pins.where((pin) => pin.id != pinId).toList();
    final updatedMapData = state.mapData!.copyWith(
      pins: updatedPins,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(mapData: updatedMapData);
  }

  Future<void> updateMapData({String? backgroundImageUrl}) async {
    if (state.mapData == null) return;

    final updatedMapData = state.mapData!.copyWith(
      backgroundImageUrl: backgroundImageUrl ?? state.mapData!.backgroundImageUrl,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(mapData: updatedMapData);
  }

  Future<void> saveMapData() async {
    // TODO: Implementar salvamento real
  }
}

/// Provider do notifier
final pinMapNotifierProvider = StateNotifierProvider.family<PinMapNotifier, PinMapState, String>(
  (ref, route) => PinMapNotifier(route),
);