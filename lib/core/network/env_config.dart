import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvConfig {
  final String baseUrl;
  final int timeout;
  final String appName;
  final String environment;
  final bool enableLogging;
  final bool enableDebugMode;

  const EnvConfig({
    required this.baseUrl,
    required this.timeout,
    required this.appName,
    required this.environment,
    required this.enableLogging,
    required this.enableDebugMode,
  });
}

final envConfigProvider = Provider<EnvConfig>((ref) {
  return const EnvConfig(
    baseUrl: 'http://localhost:8080',
    timeout: 30000,
    appName: 'Terra Allwert',
    environment: 'development',
    enableLogging: true,
    enableDebugMode: true,
  );
});