import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker/talker.dart';

import 'infra/config/env_config.dart';
import 'infra/logging/app_logger.dart';
import 'presentation/core/di/dependency_injection.dart';
import 'presentation/layout/design_system/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/utils/notification/snackbar_notification.dart';

final talkerProvider = Provider<Talker>((ref) => Talker());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.info('🚀 Terra Allwert app starting...');

  // Initialize dependency injection
  try {
    await configureDependencies();
    AppLogger.info('✅ Dependency injection configured successfully');
  } catch (e, stackTrace) {
    AppLogger.error('❌ Failed to configure dependencies', error: e, stackTrace: stackTrace);
  }

  AppLogger.info('🏁 Terra Allwert app initialization complete');

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Inicializar verificação de autenticação imediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(envConfigProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: config.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarNotification.messengerKey,
    );
  }
}
