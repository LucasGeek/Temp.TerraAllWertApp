import 'package:freezed_annotation/freezed_annotation.dart';

part 'carousel_item.freezed.dart';
part 'carousel_item.g.dart';

/// Tipo de item do carrossel
enum CarouselItemType { banner, video, map, card, custom }

@freezed
abstract class CarouselItem with _$CarouselItem {
  const factory CarouselItem({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto
    String? remoteId,

    /// FK para menu
    required String menuLocalId,

    /// Tipo do item
    required CarouselItemType itemType,

    /// Arquivo de fundo (local)
    String? backgroundFileLocalId,

    /// Posição do item no carrossel
    @Default(0) int position,

    /// Título
    String? title,

    /// Subtítulo
    String? subtitle,

    /// Texto do botão (CTA)
    String? ctaText,

    /// URL do botão (CTA)
    String? ctaUrl,

    /// Dados do mapa em JSON
    Map<String, dynamic>? mapData,

    /// Prioridade de pré-carregamento
    @Default(5) int preloadPriority,

    /// Se o item está ativo
    @Default(true) bool isActive,

    /// Controle de sincronização
    @Default(1) int syncVersion,
    @Default(false) bool isModified,
    DateTime? lastModifiedAt,

    /// Datas de ciclo de vida
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _CarouselItem;

  factory CarouselItem.fromJson(Map<String, dynamic> json) => _$CarouselItemFromJson(json);
}
