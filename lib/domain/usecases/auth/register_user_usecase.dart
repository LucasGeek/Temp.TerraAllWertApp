import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../usecase.dart';

class RegisterUserParams {
  final String email;
  final String password;
  final String name;
  final String? enterpriseId;
  
  RegisterUserParams({
    required this.email,
    required this.password,
    required this.name,
    this.enterpriseId,
  });
}

class RegisterUserUseCase implements UseCase<User, RegisterUserParams> {
  final UserRepository _userRepository;
  
  RegisterUserUseCase(this._userRepository);
  
  @override
  Future<User> call(RegisterUserParams params) async {
    // Validate email format
    if (!_isValidEmail(params.email)) {
      throw Exception('Invalid email format');
    }
    
    // Validate password strength
    if (params.password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }
    
    // Create new user (checking for duplicates would be done at repository level)
    final newUser = User(
      localId: '', // Will be set by repository
      email: params.email,
      name: params.name,
      enterpriseLocalId: params.enterpriseId,
      role: UserRole.visitor,
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );
    
    await _userRepository.saveUserLocal(newUser);
    return newUser;
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}