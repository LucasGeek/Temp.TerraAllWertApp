import 'package:freezed_annotation/freezed_annotation.dart';

part 'suite.freezed.dart';
part 'suite.g.dart';

/// Status da unidade
enum SuiteStatus { available, reserved, sold, blocked }

@freezed
abstract class Suite with _$Suite {
  const factory Suite({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto
    String? remoteId,

    /// FK para floor
    required String floorLocalId,

    /// Número da unidade
    required String unitNumber,

    /// Título
    required String title,

    /// Descrição opcional
    String? description,

    /// Posição X/Y no mapa
    double? positionX,
    double? positionY,

    /// Área em m²
    required double areaSqm,

    /// Dormitórios
    @Default(0) int bedrooms,

    /// Quantidade de suítes
    @Default(0) int suitesCount,

    /// Banheiros
    @Default(0) int bathrooms,

    /// Vagas de garagem
    @Default(0) int parkingSpaces,

    /// Posição do sol (ex: N, S, L, O)
    String? sunPosition,

    /// Status da unidade
    @Default(SuiteStatus.available) SuiteStatus status,

    /// Planta baixa (arquivo local)
    String? floorPlanFileLocalId,

    /// Preço
    double? price,

    /// Favorito local
    @Default(false) bool isFavorite,

    /// Quando foi favoritado
    DateTime? favoritedAt,

    /// Notas locais do usuário
    String? localNotes,

    /// Controle de sync
    @Default(1) int syncVersion,
    @Default(false) bool isModified,
    DateTime? lastModifiedAt,

    /// Datas de ciclo de vida
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _Suite;

  factory Suite.fromJson(Map<String, dynamic> json) => _$SuiteFromJson(json);
}
