import 'package:freezed_annotation/freezed_annotation.dart';

part 'pin_marker.freezed.dart';
part 'pin_marker.g.dart';

/// Tipo de ícone do pin
enum PinIconType {
  @JsonValue('default')
  defaultIcon,
  marker,
  star,
  heart,
  custom,
}

/// Tipo de ação do pin
enum PinActionType { info, link, navigation, custom }

@freezed
abstract class PinMarker with _$PinMarker {
  const factory PinMarker({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto
    String? remoteId,

    /// FK para menu
    required String menuLocalId,

    /// Título do pin
    required String title,

    /// Descrição opcional
    String? description,

    /// Coordenadas X/Y
    required double positionX,
    required double positionY,
    
    /// Aliases para x/y (compatibilidade)
    required double x,
    required double y,

    /// Tipo de ícone
    @Default(PinIconType.defaultIcon) PinIconType iconType,

    /// Cor do ícone (hex)
    @Default('#FF0000') String iconColor,

    /// Tipo de ação
    @Default(PinActionType.info) PinActionType actionType,

    /// Dados da ação em JSON
    Map<String, dynamic>? actionData,

    /// Se o pin está ativo
    @Default(true) bool isActive,
    
    /// Se o pin está visível
    @Default(true) bool isVisible,

    /// Se já foi visualizado
    @Default(false) bool wasViewed,

    /// Quando foi visualizado
    DateTime? viewedAt,

    /// Controle de sincronização
    @Default(1) int syncVersion,
    @Default(false) bool isModified,
    DateTime? lastModifiedAt,

    /// Datas de ciclo de vida
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _PinMarker;

  factory PinMarker.fromJson(Map<String, dynamic> json) => _$PinMarkerFromJson(json);
}
