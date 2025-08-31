import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../infra/logging/app_logger.dart';
import '../config/env_config.dart';
import 'auth_service.dart';
import 'dev_auth_service.dart';

/// Smart authentication service que tenta GraphQL real primeiro,
/// mas usa desenvolvimento como fallback quando server tem problemas
class SmartAuthService {
  final GraphQLAuthService _graphqlAuth;
  final DevAuthService _devAuth;
  final EnvConfig _config;
  
  SmartAuthService({
    required GraphQLAuthService graphqlAuth,
    required DevAuthService devAuth,
    required EnvConfig config,
  }) : _graphqlAuth = graphqlAuth, _devAuth = devAuth, _config = config;

  /// Tenta login real primeiro, fallback para dev se server falha
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    // Se não está em modo debug, usa apenas GraphQL real
    if (!_config.debugMode) {
      return await _graphqlAuth.login(email: email, password: password);
    }

    try {
      AuthLogger.info('Smart auth: Attempting GraphQL authentication first');
      
      // Primeira tentativa: GraphQL real
      return await _graphqlAuth.login(email: email, password: password);
      
    } catch (error) {
      final errorString = error.toString().toLowerCase();
      
      // Se é erro de servidor interno, conexão ou parsing, tenta desenvolvimento
      if (errorString.contains('erro interno do servidor') ||
          errorString.contains('internal server error') ||
          errorString.contains('500') ||
          errorString.contains('connection refused') ||
          errorString.contains('network error') ||
          errorString.contains('connection failed') ||
          errorString.contains('failed to fetch') ||
          errorString.contains('parsedresponse: null') ||
          errorString.contains('link exception')) {
        
        AuthLogger.warning('Smart auth: GraphQL authentication failed with server error, trying development mode');
        AuthLogger.warning('GraphQL error: $error');
        
        try {
          // Segunda tentativa: Desenvolvimento
          final token = await _devAuth.login(email: email, password: password);
          
          AuthLogger.info('Smart auth: Development authentication successful');
          return token;
          
        } catch (devError) {
          AuthLogger.error('Smart auth: Both GraphQL and development authentication failed');
          
          // Se desenvolvimento também falha, propaga erro original do GraphQL
          throw Exception('Autenticação falhou. GraphQL: $error. Desenvolvimento: $devError');
        }
      }
      
      // Para outros tipos de erro (credenciais inválidas etc), propaga original
      AuthLogger.error('Smart auth: GraphQL authentication failed with non-server error');
      rethrow;
    }
  }

  /// Refresh token com fallback inteligente
  Future<AuthToken> refreshToken() async {
    // Verifica se é token de desenvolvimento
    final currentToken = await _graphqlAuth.getStoredAccessToken();
    if (currentToken != null && currentToken.startsWith('dev_token_')) {
      AuthLogger.debug('Smart auth: Refreshing development token');
      return await _devAuth.refreshToken();
    }

    // Se não está em debug mode ou é token real, usa GraphQL
    if (!_config.debugMode) {
      return await _graphqlAuth.refreshToken();
    }

    try {
      return await _graphqlAuth.refreshToken();
    } catch (error) {
      AuthLogger.warning('Smart auth: GraphQL token refresh failed, trying development fallback');
      return await _devAuth.refreshToken();
    }
  }

  /// Logout com limpeza completa
  Future<void> logout() async {
    AuthLogger.info('Smart auth: Performing logout');
    
    try {
      // Tenta logout do GraphQL primeiro
      await _graphqlAuth.logout();
    } catch (e) {
      AuthLogger.warning('Smart auth: GraphQL logout failed, continuing with local cleanup');
    }

    try {
      // Sempre faz logout do desenvolvimento também (limpeza local)
      await _devAuth.logout();
    } catch (e) {
      AuthLogger.warning('Smart auth: Development logout failed', error: e);
    }
  }

  /// Obtém usuário atual com preferência para real
  Future<User?> getCurrentUser() async {
    // Primeiro tenta GraphQL
    final user = await _graphqlAuth.getCurrentUser();
    if (user != null) {
      return user;
    }

    // Se GraphQL falha, tenta desenvolvimento
    return await _devAuth.getCurrentUser();
  }

  /// Verifica se tem token válido (qualquer tipo)
  Future<bool> hasValidToken() async {
    final graphqlValid = await _graphqlAuth.hasValidToken();
    if (graphqlValid) return true;

    final devValid = await _devAuth.hasValidToken();
    return devValid;
  }

  /// Signup com fallback inteligente  
  Future<AuthToken> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    // Se não está em modo debug, usa apenas GraphQL real
    if (!_config.debugMode) {
      return await _graphqlAuth.signup(email: email, password: password, name: name);
    }

    try {
      AuthLogger.info('Smart auth: Attempting GraphQL signup first');
      
      // Primeira tentativa: GraphQL real
      return await _graphqlAuth.signup(email: email, password: password, name: name);
      
    } catch (error) {
      // Se é erro de servidor interno, não tem fallback para signup
      // Signup precisa de servidor funcionando
      AuthLogger.error('Smart auth: GraphQL signup failed: $error');
      rethrow;
    }
  }

  /// Obtém usuário armazenado
  Future<User?> getStoredUser() async {
    return await _graphqlAuth.getStoredUser();
  }

  /// Obtém token de acesso armazenado
  Future<String?> getStoredAccessToken() async {
    return await _graphqlAuth.getStoredAccessToken();
  }

  /// Verifica se está usando modo desenvolvimento
  Future<bool> isUsingDevMode() async {
    final token = await getStoredAccessToken();
    return token != null && token.startsWith('dev_token_');
  }

  /// Mostra credenciais de desenvolvimento válidas (apenas debug)
  static Map<String, String> getDevCredentials() {
    return DevAuthService.getValidCredentials();
  }

  /// Força uso de modo desenvolvimento (apenas debug)
  Future<AuthToken> forceDevLogin({
    required String email, 
    required String password,
  }) async {
    if (!_config.debugMode) {
      throw Exception('Development mode forced login is only available in debug mode');
    }
    
    AuthLogger.warning('Smart auth: Forcing development mode login');
    return await _devAuth.login(email: email, password: password);
  }
}

// Provider para smart authentication service
final smartAuthServiceProvider = Provider<SmartAuthService>((ref) {
  final graphqlAuth = ref.watch(graphQLAuthServiceProvider);
  final devAuth = ref.watch(devAuthServiceProvider);
  final config = ref.watch(envConfigProvider);
  
  return SmartAuthService(
    graphqlAuth: graphqlAuth,
    devAuth: devAuth,
    config: config,
  );
});