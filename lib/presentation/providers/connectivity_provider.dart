import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infra/connectivity/connectivity_service.dart';

/// Provider para o serviço de conectividade
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider para status de conectividade
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectivityStream;
});

/// Provider para status atual de conectividade (síncrono)
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.isOnline;
});

/// Provider para verificar se é plataforma web
final isWebProvider = Provider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.isWeb;
});

/// Provider para verificar se é plataforma mobile
final isMobileProvider = Provider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.isMobile;
});