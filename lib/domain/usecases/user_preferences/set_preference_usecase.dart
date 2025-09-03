import '../../repositories/user_preferences_repository.dart';
import '../usecase.dart';

class SetPreferenceParams {
  final String key;
  final dynamic value;
  
  SetPreferenceParams({
    required this.key,
    required this.value,
  });
}

class SetPreferenceUseCase implements VoidUseCase<SetPreferenceParams> {
  final UserPreferencesRepository _repository;
  
  SetPreferenceUseCase(this._repository);
  
  @override
  Future<void> call(SetPreferenceParams params) async {
    try {
      // Validate key
      if (params.key.trim().isEmpty) {
        throw Exception('Preference key cannot be empty');
      }
      
      await _repository.setPreference(params.key, params.value);
    } catch (e) {
      throw Exception('Failed to set preference: ${e.toString()}');
    }
  }
}