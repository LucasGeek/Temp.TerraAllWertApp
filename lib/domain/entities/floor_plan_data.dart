import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/apartment_status.dart';
import '../enums/sun_position.dart';
import '../enums/marker_type.dart';

part 'floor_plan_data.freezed.dart';
part 'floor_plan_data.g.dart';

/// Entidade para apartamento
@freezed
abstract class Apartment with _$Apartment {
  const factory Apartment({
    required String id,
    required String number,
    required double area, // em m²
    required int bedrooms, // quantidade de dormitórios
    required int suites, // quantidade de suítes
    required SunPosition sunPosition,
    required ApartmentStatus status,
    String? floorPlanImageUrl, // planta baixa do apartamento
    String? floorPlanImagePath, // path local da planta baixa
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Apartment;

  factory Apartment.fromJson(Map<String, dynamic> json) => _$ApartmentFromJson(json);
}

/// Entidade para marcador na planta
@freezed
abstract class FloorMarker with _$FloorMarker {
  const factory FloorMarker({
    required String id,
    required String title,
    String? description,
    required double positionX, // Posição X normalizada (0.0 a 1.0)
    required double positionY, // Posição Y normalizada (0.0 a 1.0)
    required MarkerType markerType,
    String? apartmentId, // ID do apartamento (se for apartamento existente)
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FloorMarker;

  factory FloorMarker.fromJson(Map<String, dynamic> json) => _$FloorMarkerFromJson(json);
}

/// Entidade para pavimento
@freezed
abstract class Floor with _$Floor {
  const factory Floor({
    required String id,
    required String number, // número/nome do pavimento
    String? floorPlanImageUrl, // imagem principal do pavimento
    String? floorPlanImagePath, // path local da imagem
    @Default([]) List<FloorMarker> markers, // marcadores no pavimento
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Floor;

  factory Floor.fromJson(Map<String, dynamic> json) => _$FloorFromJson(json);
}

/// Entidade principal para dados de plantas de pavimento
@freezed
abstract class FloorPlanData with _$FloorPlanData {
  const factory FloorPlanData({
    required String id,
    required String routeId, // ID da rota associada
    @Default([]) List<Floor> floors, // lista de pavimentos
    @Default([]) List<Apartment> apartments, // lista de apartamentos
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FloorPlanData;

  factory FloorPlanData.fromJson(Map<String, dynamic> json) => _$FloorPlanDataFromJson(json);
}