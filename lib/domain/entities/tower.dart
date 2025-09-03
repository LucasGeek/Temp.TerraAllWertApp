import 'package:freezed_annotation/freezed_annotation.dart';

part 'tower.freezed.dart';
part 'tower.g.dart';

@freezed
abstract class Tower with _$Tower {
  const factory Tower({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto
    String? remoteId,

    /// FK para menu
    required String menuLocalId,

    /// Título da torre
    required String title,

    /// Descrição opcional
    String? description,

    /// Número total de andares
    required int totalFloors,

    /// Quantidade de unidades por andar
    int? unitsPerFloor,

    /// Posição na ordenação
    @Default(0) int position,

    /// Versão de sincronização
    @Default(1) int syncVersion,

    /// Modificado localmente?
    @Default(false) bool isModified,

    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,

    /// Atualizado em
    DateTime? updatedAt,

    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _Tower;

  factory Tower.fromJson(Map<String, dynamic> json) => _$TowerFromJson(json);
}
