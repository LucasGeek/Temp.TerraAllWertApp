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

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(envConfigProvider);
    final router = ref.watch(routerProvider);

    // Inicializar verificação de autenticação
    ref.listen(authProvider, (previous, next) {
      // Verificar status de auth apenas na primeira inicialização
      if (previous == null && next.status == AuthStatus.initial) {
        Future.microtask(() {
          ref.read(authProvider.notifier).checkAuthStatus();
        });
      }
    });

    return MaterialApp.router(
      title: config.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      routerConfig: router,
      // debugShowCheckedModeBanner: config.environment != 'production',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarNotification.messengerKey,
    );
  }
}
