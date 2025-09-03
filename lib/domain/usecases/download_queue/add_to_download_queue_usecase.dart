import '../../entities/download_queue.dart';
import '../../repositories/download_queue_repository.dart';
import '../usecase.dart';

class AddToDownloadQueueParams {
  final String resourceType;
  final String resourceLocalId;
  final String resourceUrl;
  final int priority;
  final int? fileSizeBytes;
  
  AddToDownloadQueueParams({
    required this.resourceType,
    required this.resourceLocalId,
    required this.resourceUrl,
    this.priority = 5,
    this.fileSizeBytes,
  });
}

class AddToDownloadQueueUseCase implements UseCase<DownloadQueue, AddToDownloadQueueParams> {
  final DownloadQueueRepository _repository;
  
  AddToDownloadQueueUseCase(this._repository);
  
  @override
  Future<DownloadQueue> call(AddToDownloadQueueParams params) async {
    try {
      // Validate parameters
      if (params.resourceType.trim().isEmpty) {
        throw Exception('Resource type cannot be empty');
      }
      
      if (params.resourceLocalId.trim().isEmpty) {
        throw Exception('Resource local ID cannot be empty');
      }
      
      if (params.resourceUrl.trim().isEmpty) {
        throw Exception('Resource URL cannot be empty');
      }
      
      if (params.priority < 1 || params.priority > 10) {
        throw Exception('Priority must be between 1 and 10');
      }
      
      // Check if already in queue
      final existing = await _repository.getByResourceUrl(params.resourceUrl);
      if (existing != null && existing.status != DownloadStatus.failed) {
        return existing;
      }
      
      // Create download queue item
      final downloadItem = DownloadQueue(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        resourceType: params.resourceType.trim(),
        resourceLocalId: params.resourceLocalId.trim(),
        resourceUrl: params.resourceUrl.trim(),
        priority: params.priority,
        fileSizeBytes: params.fileSizeBytes,
        createdAt: DateTime.now(),
      );
      
      return await _repository.create(downloadItem);
    } catch (e) {
      throw Exception('Failed to add to download queue: ${e.toString()}');
    }
  }
}