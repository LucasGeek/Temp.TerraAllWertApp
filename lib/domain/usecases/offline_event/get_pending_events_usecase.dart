import '../../entities/offline_event.dart';
import '../../repositories/offline_event_repository.dart';
import '../usecase.dart';

class GetPendingEventsUseCase implements NoParamsUseCase<List<OfflineEvent>> {
  final OfflineEventRepository _repository;
  
  GetPendingEventsUseCase(this._repository);
  
  @override
  Future<List<OfflineEvent>> call() async {
    try {
      return await _repository.getPending();
    } catch (e) {
      throw Exception('Failed to get pending events: ${e.toString()}');
    }
  }
}