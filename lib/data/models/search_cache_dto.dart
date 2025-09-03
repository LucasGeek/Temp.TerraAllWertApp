import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/search_cache.dart';

part 'search_cache_dto.freezed.dart';
part 'search_cache_dto.g.dart';

@freezed
abstract class SearchCacheDto with _$SearchCacheDto {
  const factory SearchCacheDto({
    required String id,
    required String searchType,
    required String searchQuery,
    required String searchHash,
    required List<String> resultIds,
    required int resultCount,
    required DateTime expiresAt,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    DateTime? updatedAt,
  }) = _SearchCacheDto;

  factory SearchCacheDto.fromJson(Map<String, dynamic> json) => 
      _$SearchCacheDtoFromJson(json);
}

extension SearchCacheDtoMapper on SearchCacheDto {
  SearchCache toEntity(String localId) {
    return SearchCache(
      localId: localId,
      remoteId: id,
      searchType: searchType,
      searchQuery: searchQuery,
      searchHash: searchHash,
      resultIds: resultIds,
      resultCount: resultCount,
      expiresAt: expiresAt,
      createdAt: createdAt ?? DateTime.now(),
      lastAccessedAt: lastAccessedAt,
    );
  }
}

extension SearchCacheEntityMapper on SearchCache {
  SearchCacheDto toDto() {
    return SearchCacheDto(
      id: remoteId ?? localId,
      searchType: searchType,
      searchQuery: searchQuery,
      searchHash: searchHash,
      resultIds: resultIds,
      resultCount: resultCount,
      expiresAt: expiresAt,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt,
      updatedAt: null,
    );
  }
}