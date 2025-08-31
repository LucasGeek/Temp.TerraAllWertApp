import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../infra/logging/app_logger.dart';
import '../storage/secure_storage_service.dart';

/// Development authentication service para contornar problemas do servidor
/// IMPORTANTE: Usar apenas em desenvolvimento quando o servidor GraphQL tem problemas
class DevAuthService {
  final SecureStorageService _storage;
  
  DevAuthService({
    required SecureStorageService storage,
  }) : _storage = storage;

  /// Simula login com credenciais conhecidas para desenvolvimento
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    AuthLogger.warning('DEVELOPMENT MODE: Using mock authentication bypass');
    AuthLogger.info('Attempting dev login for: $email');

    await Future.delayed(const Duration(milliseconds: 500)); // Simula network delay

    // Credenciais válidas para desenvolvimento
    final validCredentials = {
      'admin@terraallwert.com': 'admin123',
      'admin': 'admin',
      'viewer@terraallwert.com': 'viewer123',
      'viewer': 'viewer',
      'user@terraallwert.com': 'user123',
      'test@terraallwert.com': 'test123',
    };

    if (!validCredentials.containsKey(email)) {
      AuthLogger.warning('Dev auth: Invalid email attempted: $email');
      throw Exception('Email não encontrado nas credenciais de desenvolvimento.');
    }

    if (validCredentials[email] != password) {
      AuthLogger.warning('Dev auth: Invalid password for email: $email');
      throw Exception('Senha incorreta para desenvolvimento.');
    }

    // Cria token mock para desenvolvimento
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 1));
    
    final token = AuthToken(
      accessToken: 'dev_token_${email}_${now.millisecondsSinceEpoch}',
      refreshToken: 'dev_refresh_token_${email}_${now.millisecondsSinceEpoch}',
      expiresAt: expiresAt,
      tokenType: 'Bearer',
    );

    AuthLogger.info('Dev auth: Generated mock token for: $email');

    // Armazena tokens
    await _storage.setTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresAt: token.expiresAt,
    );

    // Cria usuário mock baseado no email
    final user = _createMockUser(email);
    await _storage.setUserData(user);

    AuthLogger.info('Dev auth: Login successful for: $email');
    return token;
  }

  /// Cria usuário mock baseado no email
  User _createMockUser(String email) {
    final isAdmin = email.startsWith('admin');
    final isViewer = email.startsWith('viewer');
    
    return User(
      id: 'dev_user_${email.hashCode}',
      email: email,
      name: _extractNameFromEmail(email),
      avatar: null,
      isActive: true,
      role: UserRole(
        id: isAdmin ? 'admin_role' : (isViewer ? 'viewer_role' : 'user_role'),
        name: isAdmin ? 'Administrador' : (isViewer ? 'Visualizador' : 'Usuário'),
        code: isAdmin ? 'ADMIN' : (isViewer ? 'VIEWER' : 'USER'),
      ),
    );
  }

  String _extractNameFromEmail(String email) {
    if (email.contains('@')) {
      final username = email.split('@')[0];
      return username.substring(0, 1).toUpperCase() + 
             username.substring(1).toLowerCase();
    }
    return email.substring(0, 1).toUpperCase() + 
           email.substring(1).toLowerCase();
  }

  /// Simula refresh token
  Future<AuthToken> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || !refreshToken.startsWith('dev_refresh_token_')) {
      throw Exception('No valid development refresh token available');
    }

    AuthLogger.info('Dev auth: Refreshing development token');

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 1));
    
    final token = AuthToken(
      accessToken: 'dev_token_refresh_${now.millisecondsSinceEpoch}',
      refreshToken: 'dev_refresh_token_refresh_${now.millisecondsSinceEpoch}',
      expiresAt: expiresAt,
      tokenType: 'Bearer',
    );

    await _storage.setTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresAt: token.expiresAt,
    );

    return token;
  }

  /// Simula logout
  Future<void> logout() async {
    AuthLogger.info('Dev auth: Performing development logout');
    
    try {
      await _storage.clearTokens();
      AuthLogger.info('Dev auth: Logout successful');
    } catch (e, stackTrace) {
      AuthLogger.error('Dev auth: Logout failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retorna usuário armazenado
  Future<User?> getCurrentUser() async {
    return await _storage.getUserData();
  }

  /// Verifica se tem token válido
  Future<bool> hasValidToken() async {
    final token = await _storage.getAccessToken();
    return token != null && token.startsWith('dev_token_');
  }

  /// Lista credenciais válidas para desenvolvimento (apenas em debug)
  static Map<String, String> getValidCredentials() {
    return {
      'admin@terraallwert.com': 'admin123',
      'admin': 'admin', 
      'viewer@terraallwert.com': 'viewer123',
      'viewer': 'viewer',
      'user@terraallwert.com': 'user123',
      'test@terraallwert.com': 'test123',
    };
  }
}

// Provider para serviço de desenvolvimento
final devAuthServiceProvider = Provider<DevAuthService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  
  return DevAuthService(
    storage: storage,
  );
});