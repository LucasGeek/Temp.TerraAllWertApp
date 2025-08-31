import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../network/env_config.dart';

class GraphQLClientService {
  late final GraphQLClient _client;
  
  GraphQLClientService({
    required String endpoint,
    String? token,
  }) {
    final httpLink = HttpLink(endpoint);
    
    Link link = httpLink;
    
    if (token != null) {
      final authLink = AuthLink(
        getToken: () async => 'Bearer $token',
      );
      link = authLink.concat(httpLink);
    }

    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  GraphQLClient get client => _client;

  Future<QueryResult> query(QueryOptions options) async {
    return await _client.query(options);
  }

  Future<QueryResult> mutate(MutationOptions options) async {
    return await _client.mutate(options);
  }

  ObservableQuery watchQuery(WatchQueryOptions options) {
    return _client.watchQuery(options);
  }

  Future<void> clearCache() async {
    _client.cache.store.reset();
  }
}

// Secure Storage Service
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<String?> getAccessToken() async {
    return null;
  }

  Future<String?> getRefreshToken() async {
    return null;
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
  }

  Future<void> clearTokens() async {
  }
}

// Providers
final graphQLClientProvider = Provider<GraphQLClientService>((ref) {
  final config = ref.watch(envConfigProvider);
  return GraphQLClientService(
    endpoint: config.graphqlEndpoint,
  );
});

final graphQLClientStateProvider = StateProvider<GraphQLClientService?>((ref) {
  return null;
});