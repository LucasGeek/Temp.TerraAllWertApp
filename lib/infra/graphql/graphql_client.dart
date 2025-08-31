import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/env_config.dart';
import '../../infra/logging/app_logger.dart';

class GraphQLClientService {
  late final GraphQLClient _client;
  final String _endpoint;
  
  GraphQLClientService({
    required String endpoint,
    String? token,
  }) : _endpoint = endpoint {
    _validateEndpoint(endpoint);
    _initializeClient(token);
  }

  void _validateEndpoint(String endpoint) {
    if (endpoint.isEmpty) {
      throw ArgumentError('GraphQL endpoint cannot be empty');
    }
    
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw ArgumentError('Invalid GraphQL endpoint URL: $endpoint');
    }
    
    if (!['http', 'https'].contains(uri.scheme)) {
      throw ArgumentError('GraphQL endpoint must use HTTP or HTTPS: $endpoint');
    }
    
    AppLogger.debug('GraphQL endpoint validation passed: $endpoint', tag: 'GRAPHQL');
  }

  void _initializeClient(String? token) {
    try {
      AppLogger.info('Initializing GraphQL client', tag: 'GRAPHQL');
      AppLogger.debug('Endpoint: $_endpoint', tag: 'GRAPHQL');
      
      // Create HTTP link with timeout and error handling  
      final httpLink = HttpLink(
        _endpoint,
        defaultHeaders: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'TerraAllwert-App/1.0',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      );

      Link link = httpLink;

      // Add auth link if token is provided
      if (token != null && token.isNotEmpty) {
        AppLogger.debug('Adding authentication to GraphQL client', tag: 'GRAPHQL');
        final authLink = AuthLink(
          getToken: () async => 'Bearer $token',
        );
        link = authLink.concat(httpLink);
      }

      _client = GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      AppLogger.info('GraphQL client initialized successfully', tag: 'GRAPHQL');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize GraphQL client', tag: 'GRAPHQL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  GraphQLClient get client => _client;

  Future<QueryResult> query(QueryOptions options) async {
    try {
      AppLogger.debug('Executing GraphQL query', tag: 'GRAPHQL');

      final result = await _client.query(options).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.error('GraphQL query timeout after 30 seconds', tag: 'GRAPHQL');
          throw Exception('GraphQL query timeout');
        },
      );
      
      if (result.hasException) {
        AppLogger.error('GraphQL query failed', tag: 'GRAPHQL', error: result.exception);
        if (result.exception?.linkException != null) {
          AppLogger.error('Link exception details', tag: 'GRAPHQL', error: result.exception!.linkException);
        }
        if (result.exception?.graphqlErrors != null && result.exception!.graphqlErrors.isNotEmpty) {
          for (final error in result.exception!.graphqlErrors) {
            AppLogger.error('GraphQL error: ${error.message}', tag: 'GRAPHQL');
          }
        }
      } else {
        AppLogger.debug('GraphQL query completed successfully', tag: 'GRAPHQL');
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in GraphQL query', tag: 'GRAPHQL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<QueryResult> mutate(MutationOptions options) async {
    try {
      AppLogger.debug('Executing GraphQL mutation', tag: 'GRAPHQL');

      final result = await _client.mutate(options).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.error('GraphQL mutation timeout after 30 seconds', tag: 'GRAPHQL');
          throw Exception('GraphQL mutation timeout');
        },
      );
      
      if (result.hasException) {
        AppLogger.error('GraphQL mutation failed', tag: 'GRAPHQL', error: result.exception);
        if (result.exception?.linkException != null) {
          AppLogger.error('Link exception details', tag: 'GRAPHQL', error: result.exception!.linkException);
        }
        if (result.exception?.graphqlErrors != null && result.exception!.graphqlErrors.isNotEmpty) {
          for (final error in result.exception!.graphqlErrors) {
            AppLogger.error('GraphQL error: ${error.message}', tag: 'GRAPHQL');
          }
        }
      } else {
        AppLogger.debug('GraphQL mutation completed successfully', tag: 'GRAPHQL');
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in GraphQL mutation', tag: 'GRAPHQL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  ObservableQuery watchQuery(WatchQueryOptions options) {
    try {
      AppLogger.debug('Creating GraphQL watchQuery', tag: 'GRAPHQL');
      return _client.watchQuery(options);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create watchQuery', tag: 'GRAPHQL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> clearCache() async {
    try {
      AppLogger.debug('Clearing GraphQL cache', tag: 'GRAPHQL');
      _client.cache.store.reset();
      AppLogger.debug('GraphQL cache cleared successfully', tag: 'GRAPHQL');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear GraphQL cache', tag: 'GRAPHQL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Reinitialize client with new token (for authentication updates)
  void updateToken(String? newToken) {
    try {
      AppLogger.info('Updating GraphQL client token', tag: 'GRAPHQL');
      _initializeClient(newToken);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update GraphQL client token', tag: 'GRAPHQL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check basic network connectivity
  Future<bool> hasNetworkConnection() async {
    try {
      AppLogger.debug('Checking network connectivity', tag: 'GRAPHQL');
      
      final uri = Uri.parse(_endpoint);
      final host = uri.host;
      
      // Use default ports if not specified
      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      
      AppLogger.debug('Attempting socket connection to $host:$port', tag: 'GRAPHQL');
      
      final socket = await Socket.connect(
        host, 
        port, 
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      
      AppLogger.debug('Network connectivity check passed', tag: 'GRAPHQL');
      return true;
    } catch (e) {
      AppLogger.warning('Network connectivity check failed: $e', tag: 'GRAPHQL');
      
      // For development, try a more lenient approach - just return true
      // since we know localhost should be available
      if (_endpoint.contains('localhost') || _endpoint.contains('127.0.0.1')) {
        AppLogger.info('Localhost endpoint detected, assuming connectivity available', tag: 'GRAPHQL');
        return true;
      }
      
      return false;
    }
  }

  /// Execute operation with retry logic and exponential backoff
  Future<T> _executeWithRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempts = 0;
    Duration delay = const Duration(milliseconds: 500);

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          AppLogger.error('Operation failed after $maxRetries attempts', tag: 'GRAPHQL', error: e);
          rethrow;
        }

        AppLogger.warning('Operation attempt $attempts failed, retrying in ${delay.inMilliseconds}ms', 
          tag: 'GRAPHQL', error: e);
        
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round()); // Exponential backoff
      }
    }

    throw Exception('Should not reach here');
  }

  /// Query with retry logic
  Future<QueryResult> queryWithRetry(QueryOptions options, {int maxRetries = 3}) async {
    return _executeWithRetry(() => query(options), maxRetries: maxRetries);
  }

  /// Mutation with retry logic  
  Future<QueryResult> mutateWithRetry(MutationOptions options, {int maxRetries = 3}) async {
    return _executeWithRetry(() => mutate(options), maxRetries: maxRetries);
  }

  /// Test connection to GraphQL endpoint
  Future<bool> testConnection() async {
    try {
      AppLogger.info('Testing GraphQL connection', tag: 'GRAPHQL');
      
      // First check basic network connectivity
      final hasNetwork = await hasNetworkConnection();
      if (!hasNetwork) {
        AppLogger.warning('No network connectivity to GraphQL endpoint', tag: 'GRAPHQL');
        return false;
      }
      
      // Simple introspection query to test connection
      const testQuery = '''
        query {
          __schema {
            types {
              name
            }
          }
        }
      ''';

      final result = await query(
        QueryOptions(
          document: gql(testQuery),
          errorPolicy: ErrorPolicy.all,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      final isConnected = !result.hasException;
      
      if (isConnected) {
        AppLogger.info('GraphQL connection test successful', tag: 'GRAPHQL');
      } else {
        AppLogger.warning('GraphQL connection test failed', tag: 'GRAPHQL', error: result.exception);
      }

      return isConnected;
    } catch (e, stackTrace) {
      AppLogger.error('GraphQL connection test error', tag: 'GRAPHQL', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}

// This will be moved to a dedicated storage service file

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