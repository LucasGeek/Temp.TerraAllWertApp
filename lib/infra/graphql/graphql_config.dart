import 'package:graphql/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';
import '../storage/secure_storage_service.dart';

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

final graphqlClientProvider = FutureProvider<GraphQLClient>((ref) async {
  final config = ref.watch(envConfigProvider);
  
  // Obter token de autenticação do storage seguro
  String? authToken;
  try {
    final secureStorage = SecureStorageService();
    await secureStorage.init();
    authToken = await secureStorage.getAccessToken();
  } catch (e) {
    // Se falhar ao obter token, continuar sem autenticação
    authToken = null;
  }
  
  return GraphQLConfig.createClient(
    httpUrl: '${config.baseUrl}/graphql',
    wsUrl: 'ws://${config.baseUrl.replaceFirst('http://', '').replaceFirst('https://', '')}/ws',
    authToken: authToken,
  );
});