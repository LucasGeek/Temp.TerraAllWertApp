import '../../repositories/user_preferences_repository.dart';
import '../usecase.dart';

class ResetPreferencesUseCase implements NoParamsUseCase<void> {
  final UserPreferencesRepository _repository;
  
  ResetPreferencesUseCase(this._repository);
  
  @override
  Future<void> call() async {
    try {
      await _repository.resetToDefaults();
    } catch (e) {
      throw Exception('Failed to reset preferences: ${e.toString()}');
    }
  }
}