import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<AuthToken> call({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      throw ArgumentError('Email não pode estar vazio');
    }

    if (password.trim().isEmpty) {
      throw ArgumentError('Senha não pode estar vazia');
    }

    return await _repository.login(
      email: email.trim(),
      password: password,
    );
  }
}