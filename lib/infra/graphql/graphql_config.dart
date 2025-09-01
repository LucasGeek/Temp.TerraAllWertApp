import 'package:graphql/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';

class GraphQLConfig {
  static GraphQLClient createClient({
    required String httpUrl,
    required String wsUrl,
    String? authToken,
  }) {
    final httpLink = HttpLink(httpUrl);
    final wsLink = WebSocketLink(wsUrl);
    
    final authLink = AuthLink(
      getToken: () async => authToken != null ? 'Bearer $authToken' : null,
    );
    
    final splitLink = Link.split(
      (request) => request.isSubscription,
      wsLink,
      httpLink,
    );
    
    final link = authLink.concat(splitLink);
    
    return GraphQLClient(
      cache: GraphQLCache(
        store: InMemoryStore(),
      ),
      link: link,
      defaultPolicies: DefaultPolicies(
        watchQuery: Policies(
          fetch: FetchPolicy.cacheAndNetwork,
        ),
        query: Policies(
          fetch: FetchPolicy.cacheFirst,
        ),
      ),
    );
  }
}

final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final config = ref.watch(envConfigProvider);
  
  return GraphQLConfig.createClient(
    httpUrl: '${config.baseUrl}/graphql',
    wsUrl: 'ws://${config.baseUrl.replaceFirst('http://', '').replaceFirst('https://', '')}/ws',
    authToken: null, // TODO: Implement auth token from auth provider
  );
});