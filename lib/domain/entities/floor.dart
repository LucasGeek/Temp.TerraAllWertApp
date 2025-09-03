import 'package:freezed_annotation/freezed_annotation.dart';

part 'floor.freezed.dart';
part 'floor.g.dart';

@freezed
abstract class Floor with _$Floor {
  const factory Floor({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto
    String? remoteId,

    /// FK para tower
    required String towerLocalId,

    /// Número do andar
    required int floorNumber,

    /// Nome opcional do andar
    String? floorName,

    /// Arquivo de banner (local)
    String? bannerFileLocalId,

    /// Arquivo de planta do andar (local)
    String? floorPlanFileLocalId,

    /// Versão de sincronização
    @Default(1) int syncVersion,

    /// Modificado localmente?
    @Default(false) bool isModified,

    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Se o andar está ativo
    @Default(true) bool isActive,

    /// Se o andar está disponível
    @Default(true) bool isAvailable,

    /// Criado em
    required DateTime createdAt,

    /// Atualizado em
    DateTime? updatedAt,

    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _Floor;

  factory Floor.fromJson(Map<String, dynamic> json) => _$FloorFromJson(json);
}
