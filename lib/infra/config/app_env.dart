import 'package:envied/envied.dart';

part 'app_env.g.dart';

@Envied(path: '.env')
abstract class AppEnv {
  @EnviedField(varName: 'GRAPHQL_ENDPOINT', defaultValue: 'http://localhost:3000/graphql')
  static const String graphqlEndpoint = _AppEnv.graphqlEndpoint;

  @EnviedField(varName: 'GRAPHQL_WS_ENDPOINT', defaultValue: 'ws://localhost:3000/ws')
  static const String graphqlWsEndpoint = _AppEnv.graphqlWsEndpoint;

  @EnviedField(varName: 'JWT_SECRET_KEY', defaultValue: 'default-secret-key')
  static const String jwtSecretKey = _AppEnv.jwtSecretKey;

  @EnviedField(varName: 'MINIO_ENDPOINT', defaultValue: 'localhost:9000')
  static const String minioEndpoint = _AppEnv.minioEndpoint;

  @EnviedField(varName: 'MINIO_ACCESS_KEY', defaultValue: 'minioadmin')
  static const String minioAccessKey = _AppEnv.minioAccessKey;

  @EnviedField(varName: 'MINIO_SECRET_KEY', defaultValue: 'minioadmin')
  static const String minioSecretKey = _AppEnv.minioSecretKey;

  @EnviedField(varName: 'MINIO_BUCKET_NAME', defaultValue: 'terra-allwert')
  static const String minioBucketName = _AppEnv.minioBucketName;

  @EnviedField(varName: 'MINIO_USE_SSL', defaultValue: 'false')
  static const String minioUseSSL = _AppEnv.minioUseSSL;

  @EnviedField(varName: 'APP_NAME', defaultValue: 'Terra Allwert')
  static const String appName = _AppEnv.appName;

  @EnviedField(varName: 'APP_ENVIRONMENT', defaultValue: 'development')
  static const String environment = _AppEnv.environment;

  @EnviedField(varName: 'DEBUG_MODE', defaultValue: 'true')
  static const String debugMode = _AppEnv.debugMode;

  @EnviedField(varName: 'MAX_UPLOAD_SIZE', defaultValue: '10485760')
  static const String maxUploadSize = _AppEnv.maxUploadSize;

  @EnviedField(varName: 'ALLOWED_FILE_TYPES', defaultValue: 'jpg,jpeg,png,pdf,doc,docx')
  static const String allowedFileTypes = _AppEnv.allowedFileTypes;

  @EnviedField(varName: 'CACHE_TTL', defaultValue: '3600')
  static const String cacheTtl = _AppEnv.cacheTtl;

  @EnviedField(varName: 'ENABLE_CACHE', defaultValue: 'true')
  static const String enableCache = _AppEnv.enableCache;

  @EnviedField(varName: 'NETWORK_TIMEOUT', defaultValue: '30000')
  static const String networkTimeout = _AppEnv.networkTimeout;

  @EnviedField(varName: 'ENABLE_LOGGING', defaultValue: 'true')
  static const String enableLogging = _AppEnv.enableLogging;
}
