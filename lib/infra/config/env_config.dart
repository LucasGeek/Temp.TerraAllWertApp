import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_env.dart';

class EnvConfig {
  final String appName;
  final String environment;
  final bool debugMode;
  final String restApiEndpoint;
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
    required this.restApiEndpoint,
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
      appName: AppEnv.appName,
      environment: AppEnv.environment,
      debugMode: AppEnv.debugMode == 'true',
      restApiEndpoint: AppEnv.restApiEndpoint,
      jwtSecretKey: AppEnv.jwtSecretKey,
      minioEndpoint: AppEnv.minioEndpoint,
      minioAccessKey: AppEnv.minioAccessKey,
      minioSecretKey: AppEnv.minioSecretKey,
      minioBucketName: AppEnv.minioBucketName,
      minioUseSSL: AppEnv.minioUseSSL == 'true',
      maxUploadSize: int.tryParse(AppEnv.maxUploadSize) ?? 10485760,
      allowedFileTypes: AppEnv.allowedFileTypes.split(','),
      cacheTtl: int.tryParse(AppEnv.cacheTtl) ?? 3600,
      enableCache: AppEnv.enableCache == 'true',
      timeout: int.tryParse(AppEnv.networkTimeout) ?? 30000,
      enableLogging: AppEnv.enableLogging == 'true',
    );
  }

  // Getters para compatibilidade
  String get baseUrl => restApiEndpoint;
  bool get enableDebugMode => debugMode;
}

final envConfigProvider = Provider<EnvConfig>((ref) {
  return EnvConfig.fromEnvironment();
});