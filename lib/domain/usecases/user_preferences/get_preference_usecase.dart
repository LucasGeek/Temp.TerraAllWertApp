import '../../repositories/user_preferences_repository.dart';
import '../usecase.dart';

class GetPreferenceParams<T> {
  final String key;
  final T defaultValue;
  
  GetPreferenceParams({
    required this.key,
    required this.defaultValue,
  });
}

class GetPreferenceUseCase<T> implements UseCase<T?, GetPreferenceParams<T>> {
  final UserPreferencesRepository _repository;
  
  GetPreferenceUseCase(this._repository);
  
  @override
  Future<T?> call(GetPreferenceParams<T> params) async {
    try {
      return await _repository.getPreference<T>(params.key, params.defaultValue);
    } catch (e) {
      throw Exception('Failed to get preference: ${e.toString()}');
    }
  }
}