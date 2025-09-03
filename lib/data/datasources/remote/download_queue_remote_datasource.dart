import '../../../infra/http/rest_client.dart';
import '../../models/download_queue_dto.dart';

abstract class DownloadQueueRemoteDataSource {
  Future<List<DownloadQueueDto>> getAll();
  Future<DownloadQueueDto> getById(String id);
  Future<List<DownloadQueueDto>> getPending();
  Future<List<DownloadQueueDto>> getCompleted();
  Future<List<DownloadQueueDto>> getFailed();
  Future<List<DownloadQueueDto>> getByResourceType(String resourceType);
  Future<DownloadQueueDto> create(DownloadQueueDto download);
  Future<DownloadQueueDto> update(String id, DownloadQueueDto download);
  Future<void> delete(String id);
  Future<void> updateProgress(String id, double progress);
  Future<void> markAsCompleted(String id);
  Future<void> markAsFailed(String id, String error);
}

class DownloadQueueRemoteDataSourceImpl implements DownloadQueueRemoteDataSource {
  final RestClient _client;
  
  DownloadQueueRemoteDataSourceImpl(this._client);
  
  @override
  Future<List<DownloadQueueDto>> getAll() async {
    try {
      final response = await _client.get('/download-queue');
      final List<dynamic> data = response.data;
      return data.map((json) => DownloadQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get download queue: ${e.toString()}');
    }
  }
  
  @override
  Future<DownloadQueueDto> getById(String id) async {
    try {
      final response = await _client.get('/download-queue/$id');
      return DownloadQueueDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueueDto>> getPending() async {
    try {
      final response = await _client.get('/download-queue/pending');
      final List<dynamic> data = response.data;
      return data.map((json) => DownloadQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pending downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueueDto>> getCompleted() async {
    try {
      final response = await _client.get('/download-queue/completed');
      final List<dynamic> data = response.data;
      return data.map((json) => DownloadQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get completed downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueueDto>> getFailed() async {
    try {
      final response = await _client.get('/download-queue/failed');
      final List<dynamic> data = response.data;
      return data.map((json) => DownloadQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get failed downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueueDto>> getByResourceType(String resourceType) async {
    try {
      final response = await _client.get('/download-queue/resource-type/$resourceType');
      final List<dynamic> data = response.data;
      return data.map((json) => DownloadQueueDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get downloads by resource type: ${e.toString()}');
    }
  }
  
  @override
  Future<DownloadQueueDto> create(DownloadQueueDto download) async {
    try {
      final response = await _client.post(
        '/download-queue',
        data: download.toJson(),
      );
      return DownloadQueueDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<DownloadQueueDto> update(String id, DownloadQueueDto download) async {
    try {
      final response = await _client.put(
        '/download-queue/$id',
        data: download.toJson(),
      );
      return DownloadQueueDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _client.delete('/download-queue/$id');
    } catch (e) {
      throw Exception('Failed to delete download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateProgress(String id, double progress) async {
    try {
      await _client.put(
        '/download-queue/$id/progress',
        data: {'progress': progress},
      );
    } catch (e) {
      throw Exception('Failed to update download progress: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsCompleted(String id) async {
    try {
      await _client.put('/download-queue/$id/completed');
    } catch (e) {
      throw Exception('Failed to mark as completed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsFailed(String id, String error) async {
    try {
      await _client.put(
        '/download-queue/$id/failed',
        data: {'error': error},
      );
    } catch (e) {
      throw Exception('Failed to mark as failed: ${e.toString()}');
    }
  }
}