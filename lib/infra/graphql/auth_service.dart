import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../core/logging/app_logger.dart';
import '../storage/secure_storage_service.dart';
import 'graphql_client.dart';
import 'mutations/auth_mutations.dart';

class GraphQLAuthService {
  final GraphQLClientService _client;
  final SecureStorageService _storage;
  
  GraphQLAuthService({
    required GraphQLClientService client,
    required SecureStorageService storage,
  }) : _client = client, _storage = storage;

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    AuthLogger.loginAttempt(email);

    try {
      final result = await _client.mutateWithRetry(
        MutationOptions(
          document: gql(loginMutation),
          variables: {
            'input': {
              'email': email,
              'password': password,
            },
          },
        ),
        maxRetries: 2, // Retry login attempts up to 2 times
      );

      if (result.hasException) {
        final errorMsg = result.exception.toString();
        AuthLogger.loginFailure(email, errorMsg);
        throw Exception(errorMsg);
      }

      final data = result.data!['login'];
      AuthLogger.debug('Login response received from server');
      
      final token = AuthToken(
        accessToken: data['token'],
        refreshToken: data['refreshToken'],
        expiresAt: DateTime.parse(data['expiresAt']),
        tokenType: 'Bearer',
      );

      // Log token information (without exposing actual tokens)
      final expiresInSeconds = token.expiresAt.difference(DateTime.now()).inSeconds;
      AuthLogger.tokenReceived(token.tokenType, expiresInSeconds);

      // Store tokens with expiry
      await _storage.setTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        expiresAt: token.expiresAt,
      );

      // Get and store user data
      final user = await getCurrentUser();
      if (user != null) {
        await _storage.setUserData(user);
        AuthLogger.loginSuccess(email, user.id);
      }

      return token;
    } catch (e, stackTrace) {
      AuthLogger.loginFailure(email, e.toString());
      
      // Log apenas como info para erros de autenticação, evitando stack trace feio
      if (e is OperationException && e.graphqlErrors.isNotEmpty) {
        AuthLogger.info('Login failed with GraphQL error: ${e.graphqlErrors.first.message}');
      } else {
        AuthLogger.error('Login failed with exception', error: e, stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  Future<AuthToken> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final result = await _client.mutate(
      MutationOptions(
        document: gql(refreshTokenMutation),
        variables: {
          'refreshToken': refreshToken,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data!['refreshToken'];
    final token = AuthToken(
      accessToken: data['token'],
      refreshToken: data['refreshToken'],
      expiresAt: DateTime.parse(data['expiresAt']),
      tokenType: 'Bearer',
    );

    await _storage.setTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );

    return token;
  }

  Future<AuthToken> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(signupMutation),
        variables: {
          'email': email,
          'password': password,
          'name': name,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data!['signup'];
    final token = AuthToken(
      accessToken: data['token'],
      refreshToken: data['refreshToken'],
      expiresAt: DateTime.parse(data['expiresAt']),
      tokenType: 'Bearer',
    );

    await _storage.setTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );

    return token;
  }

  Future<void> logout() async {
    AuthLogger.logoutAttempt();
    
    try {
      // Try to logout from server
      await _client.mutate(
        MutationOptions(
          document: gql(logoutMutation),
        ),
      );
      AuthLogger.debug('Server logout successful');
    } catch (e) {
      // Continue with local logout even if server logout fails
      AuthLogger.warning('Server logout failed, continuing with local logout', error: e);
    }

    try {
      // Clear local storage
      await _storage.clearTokens();
      await _client.clearCache();
      
      AuthLogger.logoutSuccess();
    } catch (e, stackTrace) {
      AuthLogger.logoutFailure(e.toString());
      AuthLogger.error('Local logout failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      AuthLogger.debug('Fetching current user data from server');
      
      final result = await _client.queryWithRetry(
        QueryOptions(
          document: gql(getCurrentUserQuery),
        ),
        maxRetries: 2, // Retry user data fetching
      );

      if (result.hasException || result.data == null) {
        AuthLogger.warning('Failed to fetch user data from server');
        return null;
      }

      final userData = result.data!['currentUser'];
      if (userData == null) {
        AuthLogger.warning('No user data returned from server');
        return null;
      }

      final user = User(
        id: userData['id'],
        email: userData['email'],
        name: userData['username'] ?? userData['email'], // Use username or fallback to email
        avatar: null, // API doesn't return avatar
        isActive: userData['active'] ?? true,
        role: UserRole(
          id: '1', // API returns role as string, not object
          name: userData['role'] ?? 'User',
          code: userData['role']?.toString().toUpperCase() ?? 'USER',
        ),
      );

      AuthLogger.userDataReceived({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': {
          'name': user.role.name,
          'code': user.role.code,
        }
      });

      return user;
    } catch (e, stackTrace) {
      AuthLogger.error('Failed to get current user', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<String?> getStoredAccessToken() async {
    return await _storage.getAccessToken();
  }

  Future<bool> hasValidToken() async {
    return await _storage.isAuthenticated();
  }

  Future<User?> getStoredUser() async {
    return await _storage.getUserData();
  }
}

// Provider
final graphQLAuthServiceProvider = Provider<GraphQLAuthService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  
  return GraphQLAuthService(
    client: client,
    storage: storage,
  );
});