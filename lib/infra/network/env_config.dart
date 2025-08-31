import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvConfig {
  final String appName;
  final String environment;
  final bool debugMode;
  final String graphqlEndpoint;
  final String graphqlWsEndpoint;
  final String jwtSecretKey;
  final String minioEndpoint;
  final String minioAccessKey;
  final String minioSecretKey;
  final String minioBucketName;
  final bool minioUseSSL;
  final int maxUploadSize;
  final List<String> allowedFileTypes;
  final int cacheTtl;
  final bool enableCache;
  final int timeout;
  final bool enableLogging;
  
  const EnvConfig({
    required this.appName,
    required this.environment,
    required this.debugMode,
    required this.graphqlEndpoint,
    required this.graphqlWsEndpoint,
    required this.jwtSecretKey,
    required this.minioEndpoint,
    required this.minioAccessKey,
    required this.minioSecretKey,
    required this.minioBucketName,
    required this.minioUseSSL,
    required this.maxUploadSize,
    required this.allowedFileTypes,
    required this.cacheTtl,
    required this.enableCache,
    required this.timeout,
    required this.enableLogging,
  });

  factory EnvConfig.fromEnvironment() {
    return EnvConfig(
      appName: _getEnv('APP_NAME', 'Terra Allwert'),
      environment: _getEnv('APP_ENVIRONMENT', 'development'),
      debugMode: _getEnv('DEBUG_MODE', 'true') == 'true',
      graphqlEndpoint: _getEnv('GRAPHQL_ENDPOINT', 'http://localhost:8080/graphql'),
      graphqlWsEndpoint: _getEnv('GRAPHQL_WS_ENDPOINT', 'ws://localhost:8080/ws'),
      jwtSecretKey: _getEnv('JWT_SECRET_KEY', 'default-secret-key'),
      minioEndpoint: _getEnv('MINIO_ENDPOINT', 'localhost:9000'),
      minioAccessKey: _getEnv('MINIO_ACCESS_KEY', 'minioadmin'),
      minioSecretKey: _getEnv('MINIO_SECRET_KEY', 'minioadmin'),
      minioBucketName: _getEnv('MINIO_BUCKET_NAME', 'terra-allwert'),
      minioUseSSL: _getEnv('MINIO_USE_SSL', 'false') == 'true',
      maxUploadSize: int.tryParse(_getEnv('MAX_UPLOAD_SIZE', '10485760')) ?? 10485760,
      allowedFileTypes: _getEnv('ALLOWED_FILE_TYPES', 'jpg,jpeg,png,pdf,doc,docx').split(','),
      cacheTtl: int.tryParse(_getEnv('CACHE_TTL', '3600')) ?? 3600,
      enableCache: _getEnv('ENABLE_CACHE', 'true') == 'true',
      timeout: int.tryParse(_getEnv('NETWORK_TIMEOUT', '30000')) ?? 30000,
      enableLogging: _getEnv('ENABLE_LOGGING', 'true') == 'true',
    );
  }

  static String _getEnv(String key, String defaultValue) {
    return String.fromEnvironment(key, defaultValue: defaultValue);
  }

  // Getters para compatibilidade
  String get baseUrl => graphqlEndpoint.replaceAll('/graphql', '');
  bool get enableDebugMode => debugMode;
}

final envConfigProvider = Provider<EnvConfig>((ref) {
  return EnvConfig.fromEnvironment();
});