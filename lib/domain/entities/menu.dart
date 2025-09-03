import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu.freezed.dart';
part 'menu.g.dart';

/// Tipos de tela que o menu pode abrir
enum ScreenType { carousel, pin, floorplan }

/// Tipos de menu
enum MenuType { standard, submenu }

@freezed
abstract class Menu with _$Menu {
  const factory Menu({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto
    String? remoteId,

    /// FK para enterprise
    required String enterpriseLocalId,

    /// FK auto-referência para submenu
    String? parentMenuLocalId,

    /// Título do menu
    required String title,
    
    /// Nome do menu (alias para title)
    String? name,
    
    /// Descrição do menu
    String? description,

    /// Slug único
    required String slug,

    /// Tipo de tela (list, detail, etc.)
    required ScreenType screenType,

    /// Tipo de menu (default: standard)
    @Default(MenuType.standard) MenuType menuType,

    /// Posição na ordenação
    @Default(0) int position,

    /// Ícone (nome ou chave)
    String? icon,
    
    /// URL do ícone
    String? iconUrl,
    
    /// Configurações específicas do menu
    Map<String, dynamic>? configuration,

    /// Se o menu está visível
    @Default(true) bool isVisible,
    
    /// Se o menu está ativo
    @Default(true) bool isActive,

    /// Caminho materializado (ex: root/parent/child)
    String? pathHierarchy,

    /// Nível de profundidade
    @Default(0) int depthLevel,

    /// Disponível offline?
    @Default(true) bool isAvailableOffline,

    /// Requer sync para acessar?
    @Default(false) bool requiresSync,

    /// Versão de sync
    @Default(1) int syncVersion,

    /// Se foi modificado localmente
    @Default(false) bool isModified,

    /// Última modificação
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,

    /// Atualizado em
    DateTime? updatedAt,

    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _Menu;

  factory Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);
}
