import 'dart:typed_data';

import '../../../../../domain/entities/floor_plan_data.dart';

/// Estado do FloorPlanPresentation gerenciado pelo Riverpod
class FloorPlanState {
  final FloorPlanData? floorPlanData;
  final Floor? currentFloor;
  final bool isLoading;
  final bool isEditingMarkers;
  final Map<String, Uint8List> floorImageBytesMap;
  final String? error;

  const FloorPlanState({
    this.floorPlanData,
    this.currentFloor,
    this.isLoading = false,
    this.isEditingMarkers = false,
    this.floorImageBytesMap = const {},
    this.error,
  });

  factory FloorPlanState.initial() => const FloorPlanState();

  FloorPlanState copyWith({
    FloorPlanData? floorPlanData,
    Floor? currentFloor,
    bool? isLoading,
    bool? isEditingMarkers,
    Map<String, Uint8List>? floorImageBytesMap,
    String? error,
  }) {
    return FloorPlanState(
      floorPlanData: floorPlanData ?? this.floorPlanData,
      currentFloor: currentFloor ?? this.currentFloor,
      isLoading: isLoading ?? this.isLoading,
      isEditingMarkers: isEditingMarkers ?? this.isEditingMarkers,
      floorImageBytesMap: floorImageBytesMap ?? this.floorImageBytesMap,
      error: error ?? this.error,
    );
  }
}