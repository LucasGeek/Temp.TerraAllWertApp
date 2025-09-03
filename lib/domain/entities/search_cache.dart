import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_cache.freezed.dart';
part 'search_cache.g.dart';

@freezed
abstract class SearchCache with _$SearchCache {
  const factory SearchCache({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,

    /// Tipo da busca (ex: suites, towers, etc.)
    required String searchType,

    /// Query ou filtros aplicados
    required String searchQuery,

    /// Hash SHA-256 da query
    required String searchHash,

    /// IDs dos resultados (JSON array)
    @Default([]) List<String> resultIds,

    /// Número de resultados
    required int resultCount,

    /// Quando expira
    required DateTime expiresAt,

    /// Criado em
    required DateTime createdAt,

    /// Último acesso
    DateTime? lastAccessedAt,
  }) = _SearchCache;

  factory SearchCache.fromJson(Map<String, dynamic> json) => _$SearchCacheFromJson(json);
}
