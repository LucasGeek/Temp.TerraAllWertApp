import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
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
    final result = await _client.mutate(
      MutationOptions(
        document: gql(loginMutation),
        variables: {
          'email': email,
          'password': password,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data!['login'];
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
    try {
      await _client.mutate(
        MutationOptions(
          document: gql(logoutMutation),
        ),
      );
    } catch (e) {
      // Continue with local logout even if server logout fails
    }

    await _storage.clearTokens();
    await _client.clearCache();
  }

  Future<User?> getCurrentUser() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getCurrentUserQuery),
        ),
      );

      if (result.hasException || result.data == null) {
        return null;
      }

      final userData = result.data!['currentUser'];
      if (userData == null) return null;

      return User(
        id: userData['id'],
        email: userData['email'],
        name: userData['name'],
        avatar: userData['avatar'],
        role: UserRole(
          id: userData['role']['id'] ?? '',
          name: userData['role']['name'] ?? 'User',
          code: userData['role']['code'] ?? 'USER',
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getStoredAccessToken() async {
    return await _storage.getAccessToken();
  }

  Future<bool> hasValidToken() async {
    final token = await getStoredAccessToken();
    return token != null && token.isNotEmpty;
  }
}

// Provider
final graphQLAuthServiceProvider = Provider<GraphQLAuthService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  final storage = SecureStorageService();
  
  return GraphQLAuthService(
    client: client,
    storage: storage,
  );
});