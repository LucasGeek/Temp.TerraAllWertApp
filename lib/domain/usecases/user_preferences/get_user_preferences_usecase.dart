import '../../entities/user_preferences.dart';
import '../../repositories/user_preferences_repository.dart';
import '../usecase.dart';

class GetUserPreferencesParams {
  final String userLocalId;
  
  GetUserPreferencesParams({required this.userLocalId});
}

class GetUserPreferencesUseCase implements UseCase<UserPreferences?, GetUserPreferencesParams> {
  final UserPreferencesRepository _repository;
  
  GetUserPreferencesUseCase(this._repository);
  
  @override
  Future<UserPreferences?> call(GetUserPreferencesParams params) async {
    try {
      return await _repository.getByUserId(params.userLocalId);
    } catch (e) {
      throw Exception('Failed to get user preferences: ${e.toString()}');
    }
  }
}