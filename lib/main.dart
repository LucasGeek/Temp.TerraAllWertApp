import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker/talker.dart';

import 'infra/network/env_config.dart';
import 'infra/router/app_router.dart';
import 'presentation/design_system/app_theme.dart';
import 'infra/services/snackbar_service.dart';

final talkerProvider = Provider<Talker>((ref) => Talker());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: TerraAllwertApp(),
    ),
  );
}

class TerraAllwertApp extends ConsumerWidget {
  const TerraAllwertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(envConfigProvider);
    
    return MaterialApp.router(
      title: config.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: config.environment != 'production',
      scaffoldMessengerKey: SnackbarService.messengerKey,
    );
  }
}
