import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../platform/platform_service.dart';
import '../logging/app_logger.dart';

/// Service para monitoramento de conectividade com internet
/// Ignorado para plataforma web conforme solicitado
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  /// Inicializa o monitoramento de conectividade
  /// Para web, sempre retorna true (online)
  Future<void> initialize() async {
    try {
      // Para web, não monitora conectividade (sempre online)
      if (PlatformService.isWeb) {
        _isOnline = true;
        NetworkLogger.info('Web platform detected: connectivity monitoring disabled');
        return;
      }
      
      // Para mobile e desktop, monitora conectividade real
      NetworkLogger.info('Initializing connectivity monitoring for ${PlatformService.platformName}');
      
      // Verifica conectividade inicial
      await checkConnectivity();
      
      // Monitor conectividade em tempo real
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          NetworkLogger.error('Connectivity monitoring error', error: error);
          // Em caso de erro, assume offline por segurança
          _updateConnectivityStatus(false);
        },
      );
      
      NetworkLogger.info('Connectivity service initialized successfully');
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to initialize connectivity service', error: e, stackTrace: stackTrace);
      // Em caso de erro, assume offline por segurança
      _updateConnectivityStatus(false);
    }
  }
  
  /// Verifica conectividade atual
  Future<bool> checkConnectivity() async {
    try {
      // Para web, sempre online
      if (PlatformService.isWeb) {
        return true;
      }
      
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = _hasInternetConnection(connectivityResult);
      
      _updateConnectivityStatus(hasConnection);
      
      NetworkLogger.debug('Connectivity check: ${hasConnection ? 'online' : 'offline'} (${connectivityResult.toString()})');
      
      return hasConnection;
    } catch (e, stackTrace) {
      NetworkLogger.error('Error checking connectivity', error: e, stackTrace: stackTrace);
      _updateConnectivityStatus(false);
      return false;
    }
  }
  
  /// Callback para mudanças de conectividade
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = _hasInternetConnection(results);
    
    NetworkLogger.info('Connectivity changed: ${hasConnection ? 'online' : 'offline'} (${results.toString()})');
    
    _updateConnectivityStatus(hasConnection);
  }
  
  /// Verifica se há conexão com internet baseado no resultado
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );
  }
  
  /// Atualiza status de conectividade
  void _updateConnectivityStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(_isOnline);
      
      NetworkLogger.info('Connectivity status updated: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
    }
  }
  
  /// Testa conectividade com internet real (ping test)
  Future<bool> testInternetConnection({String testUrl = 'https://www.google.com'}) async {
    try {
      // Para web, sempre online
      if (PlatformService.isWeb) {
        return true;
      }
      
      // Para mobile/desktop, faz teste real de conectividade
      // TODO: Implementar teste HTTP real se necessário
      // Por enquanto, usa apenas o resultado do connectivity_plus
      
      return await checkConnectivity();
    } catch (e) {
      NetworkLogger.warning('Internet connection test failed', error: e);
      return false;
    }
  }
  
  /// Força atualização do status de conectividade
  Future<void> forceConnectivityCheck() async {
    await checkConnectivity();
  }
  
  /// Cleanup resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    NetworkLogger.debug('Connectivity service disposed');
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityServiceInitProvider = FutureProvider<void>((ref) async {
  final connectivityService = ref.watch(connectivityServiceProvider);
  await connectivityService.initialize();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectivityStream;
});