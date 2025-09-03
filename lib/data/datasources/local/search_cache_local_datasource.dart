import '../../../domain/entities/search_cache.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class SearchCacheLocalDataSource {
  Future<List<SearchCache>> getAll();
  Future<SearchCache?> getById(String localId);
  Future<SearchCache?> getByQuery(String query);
  Future<List<SearchCache>> getByCategory(String category);
  Future<void> save(SearchCache searchCache);
  Future<void> saveAll(List<SearchCache> searchCaches);
  Future<void> delete(String localId);
  Future<void> clear();
  Future<void> clearExpired();
  Future<List<SearchCache>> getModified();
  Future<List<SearchCache>> getRecent(int limit);
  Future<void> updateSyncStatus(String localId, String? remoteId);
}

class SearchCacheLocalDataSourceImpl implements SearchCacheLocalDataSource {
  final LocalStorageAdapter _storage;
  static const String _key = 'search_cache';
  
  SearchCacheLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<SearchCache>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      if (data == null || data.isEmpty) return [];
      
      return data.map((json) => SearchCache.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<SearchCache?> getById(String localId) async {
    try {
      final all = await getAll();
      return all.cast<SearchCache?>().firstWhere(
        (cache) => cache?.localId == localId,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<SearchCache?> getByQuery(String query) async {
    try {
      final all = await getAll();
      return all.cast<SearchCache?>().firstWhere(
        (cache) => cache?.searchQuery.toLowerCase() == query.toLowerCase(),
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<SearchCache>> getByCategory(String category) async {
    try {
      final all = await getAll();
      return all.where((cache) => cache.searchType == category).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(SearchCache searchCache) async {
    try {
      final data = await getAll();
      
      final index = data.indexWhere((c) => c.localId == searchCache.localId);
      if (index >= 0) {
        data[index] = searchCache.copyWith(
          lastAccessedAt: DateTime.now(),
        );
      } else {
        data.add(searchCache);
      }
      
      // Keep only the latest 100 cache entries
      if (data.length > 100) {
        data.sort((a, b) => (b.lastAccessedAt ?? b.createdAt).compareTo(a.lastAccessedAt ?? a.createdAt));
        data.removeRange(100, data.length);
      }
      
      await _storage.setJsonList(
        _key,
        data.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to save search cache: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<SearchCache> searchCaches) async {
    try {
      await _storage.setJsonList(
        _key,
        searchCaches.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to save all search caches: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final data = await getAll();
      data.removeWhere((c) => c.localId == localId);
      
      await _storage.setJsonList(
        _key,
        data.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to delete search cache: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear search cache: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearExpired() async {
    try {
      final data = await getAll();
      final now = DateTime.now();
      
      // Remove entries older than 7 days
      final validData = data.where((cache) {
        final daysSinceCreation = now.difference(cache.createdAt).inDays;
        return daysSinceCreation <= 7;
      }).toList();
      
      await _storage.setJsonList(
        _key,
        validData.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to clear expired cache: ${e.toString()}');
    }
  }
  
  @override
  Future<List<SearchCache>> getModified() async {
    try {
      // SearchCache não tem campo isModified, retornar lista vazia
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<SearchCache>> getRecent(int limit) async {
    try {
      final all = await getAll();
      all.sort((a, b) => (b.lastAccessedAt ?? b.createdAt).compareTo(a.lastAccessedAt ?? a.createdAt));
      return all.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String? remoteId) async {
    try {
      final cache = await getById(localId);
      if (cache != null) {
        // SearchCache não tem esses campos, apenas salvar sem modificar
        final syncedCache = cache;
        await save(syncedCache);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
}