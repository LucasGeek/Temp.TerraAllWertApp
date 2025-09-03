import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Enum de papéis do usuário
enum UserRole { visitor, admin, manager, editor, staff }

@freezed
abstract class User with _$User {
  const factory User({
    /// UUID local (PK)
    required String localId,

    /// UUID remoto do servidor
    String? remoteId,

    /// FK local para enterprise
    String? enterpriseLocalId,

    /// Nome do usuário
    required String name,

    /// Email único
    required String email,

    /// Papel/Role do usuário (default visitor)
    @Default(UserRole.visitor) UserRole role,

    /// URL do avatar (cacheado)
    String? avatarUrl,

    /// Token de acesso (encrypted)
    String? accessToken,

    /// Token de refresh (encrypted)
    String? refreshToken,

    /// Expiração do token
    DateTime? tokenExpiresAt,

    /// Se é o usuário atual no app
    @Default(false) bool isCurrentUser,

    /// Controle de versão de sync
    @Default(1) int syncVersion,

    /// Se foi modificado localmente
    @Default(false) bool isModified,

    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,

    /// Atualizado em
    DateTime? updatedAt,
    
    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
