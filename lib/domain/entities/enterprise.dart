import 'package:freezed_annotation/freezed_annotation.dart';

part 'enterprise.freezed.dart';
part 'enterprise.g.dart';

@freezed
abstract class Enterprise with _$Enterprise {
  const factory Enterprise({
    /// UUID v7 local (PK)
    required String localId,

    /// UUID remoto (servidor)
    String? remoteId,

    /// Nome da empresa
    required String title,

    /// Descrição opcional
    String? description,

    /// FK para arquivo de logo (local cache)
    String? logoFileLocalId,
    
    /// URL do logo
    String? logoUrl,

    /// Slug único
    required String slug,

    /// Endereço completo
    String? fullAddress,

    /// Localização (latitude/longitude)
    double? latitude,
    double? longitude,

    /// Status da empresa (default = active)
    @Default("active") String status,
    
    /// Se a empresa está ativa
    @Default(true) bool isActive,

    /// Controle de versão para conflitos
    @Default(1) int syncVersion,

    /// Flag se foi modificada localmente
    @Default(false) bool isModified,

    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criada em
    required DateTime createdAt,

    /// Atualizada em
    DateTime? updatedAt,

    /// Deletada em (soft delete)
    DateTime? deletedAt,
  }) = _Enterprise;

  factory Enterprise.fromJson(Map<String, dynamic> json) => _$EnterpriseFromJson(json);
}
