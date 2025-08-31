class EnvConfig {
  static const String firebaseProjectId = 'your-project-id';
  static const String firebaseApiKey = 'your-api-key';
  static const String firebaseAuthDomain = 'your-project-id.firebaseapp.com';
  static const String firebaseStorageBucket = 'your-project-id.appspot.com';
  static const String firebaseMessagingSenderId = '123456789';
  static const String firebaseAppId = '1:123456789:web:abcdef123456789';
  static const String firebaseMeasurementId = 'G-XXXXXXXXXX';
  
  static const String googleAdsAppIdAndroid = 'ca-app-pub-test~test';
  static const String googleAdsAppIdIos = 'ca-app-pub-test~test';
  
  static const String apiBaseUrl = 'http://localhost:8080';
  static const int apiTimeout = 30000;
  
  static const String appName = 'Terra Allwert';
  static const String appEnv = 'development';
  
  static const bool enableLogging = true;
  static const bool enableDebugMode = true;
  static const bool enableCrashlytics = false;
  static const bool enablePerformance = false;
  static const bool enableAnalytics = false;

  static bool get isProduction => appEnv == 'production';
  static bool get isDevelopment => appEnv == 'development';
  static bool get isStaging => appEnv == 'staging';
}