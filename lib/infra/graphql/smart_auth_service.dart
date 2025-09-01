import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../infra/logging/app_logger.dart';
import 'auth_service.dart';

/// Authentication service usando apenas GraphQL real
class SmartAuthService {
  final GraphQLAuthService _graphqlAuth;
  
  SmartAuthService({
    required GraphQLAuthService graphqlAuth,
  }) : _graphqlAuth = graphqlAuth;

  /// Login usando GraphQL real
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    AuthLogger.info('Authenticating user via GraphQL');
    return await _graphqlAuth.login(email: email, password: password);
  }

  /// Refresh token usando GraphQL real
  Future<AuthToken> refreshToken() async {
    AuthLogger.debug('Refreshing token via GraphQL');
    return await _graphqlAuth.refreshToken();
  }

  /// Logout via GraphQL
  Future<void> logout() async {
    AuthLogger.info('Performing logout via GraphQL');
    await _graphqlAuth.logout();
  }

  /// Obtém usuário atual via GraphQL
  Future<User?> getCurrentUser() async {
    return await _graphqlAuth.getCurrentUser();
  }

  /// Verifica se tem token válido
  Future<bool> hasValidToken() async {
    return await _graphqlAuth.hasValidToken();
  }

  /// Signup via GraphQL
  Future<AuthToken> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    AuthLogger.info('Creating new user via GraphQL');
    return await _graphqlAuth.signup(
      email: email, 
      password: password, 
      name: name,
    );
  }

  /// Obtém usuário armazenado
  Future<User?> getStoredUser() async {
    return await _graphqlAuth.getStoredUser();
  }

  /// Obtém token de acesso armazenado
  Future<String?> getStoredAccessToken() async {
    return await _graphqlAuth.getStoredAccessToken();
  }
}

// Provider para authentication service
final smartAuthServiceProvider = Provider<SmartAuthService>((ref) {
  final graphqlAuth = ref.watch(graphQLAuthServiceProvider);
  
  return SmartAuthService(
    graphqlAuth: graphqlAuth,
  );
});