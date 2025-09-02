import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker/talker.dart';

import 'infra/config/env_config.dart';
import 'infra/logging/app_logger.dart';
import 'infra/storage/secure_storage_service.dart';
import 'presentation/design_system/app_theme.dart';
import 'presentation/notification/snackbar_notification.dart';
import 'presentation/router/app_router.dart';

final talkerProvider = Provider<Talker>((ref) => Talker());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.info('🚀 Terra Allwert app starting...');

  // Initialize storage service
  try {
    final storageService = SecureStorageService();
    await storageService.init();
    AppLogger.info('📦 Storage service initialized');
  } catch (e, stackTrace) {
    AppLogger.error('❌ Failed to initialize storage service', error: e, stackTrace: stackTrace);
  }

  AppLogger.info('🏁 Terra Allwert app initialization complete');

  runApp(const ProviderScope(child: TerraAllwertApp()));
}

class TerraAllwertApp extends ConsumerWidget {
  const TerraAllwertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(envConfigProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: config.appName,
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme,
      darkTheme: AppTheme.lightTheme,
      routerConfig: router,
      // debugShowCheckedModeBanner: config.environment != 'production',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarNotification.messengerKey,
    );
  }
}
