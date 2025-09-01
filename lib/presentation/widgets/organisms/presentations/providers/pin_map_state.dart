import 'package:video_player/video_player.dart';

import '../../../../../domain/entities/map_pin.dart';

/// Estado do PinMapPresentation gerenciado pelo Riverpod
class PinMapState {
  final InteractiveMapData? mapData;
  final MapPin? selectedPin;
  final bool isEditMode;
  final bool isLoading;
  final bool hasError;
  final bool isZoomed;
  final VideoPlayerController? videoController;
  final String? error;

  const PinMapState({
    this.mapData,
    this.selectedPin,
    this.isEditMode = false,
    this.isLoading = false,
    this.hasError = false,
    this.isZoomed = false,
    this.videoController,
    this.error,
  });

  factory PinMapState.initial() => const PinMapState();

  PinMapState copyWith({
    InteractiveMapData? mapData,
    MapPin? selectedPin,
    bool? isEditMode,
    bool? isLoading,
    bool? hasError,
    bool? isZoomed,
    VideoPlayerController? videoController,
    String? error,
  }) {
    return PinMapState(
      mapData: mapData ?? this.mapData,
      selectedPin: selectedPin ?? this.selectedPin,
      isEditMode: isEditMode ?? this.isEditMode,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      isZoomed: isZoomed ?? this.isZoomed,
      videoController: videoController ?? this.videoController,
      error: error ?? this.error,
    );
  }

  PinMapState clearSelectedPin() {
    return copyWith(selectedPin: null);
  }

  PinMapState clearError() {
    return copyWith(error: null, hasError: false);
  }
}