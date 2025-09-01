import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';

/// Serviço para monitorar conectividade de rede
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool _isWeb = false;
  
  /// Stream controller para mudanças de conectividade
  final _connectivityController = StreamController<bool>.broadcast();
  
  /// Getter para status online
  bool get isOnline => _isOnline;
  
  /// Getter para plataforma web
  bool get isWeb => _isWeb;
  
  /// Getter para plataforma mobile
  bool get isMobile => !_isWeb && (Platform.isAndroid || Platform.isIOS);
  
  /// Stream de mudanças de conectividade
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Inicializa o serviço de conectividade
  Future<void> initialize() async {
    try {
      _isWeb = kIsWeb;
      
      // Verificar conectividade inicial
      await _checkConnectivity();
      
      // Escutar mudanças de conectividade
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          AppLogger.error('Connectivity stream error: $error');
        },
      );
      
      AppLogger.info('ConnectivityService initialized - isOnline: $_isOnline, isWeb: $_isWeb');
    } catch (e) {
      AppLogger.error('Failed to initialize ConnectivityService: $e');
      // Em caso de erro, assumir que está online
      _isOnline = true;
    }
  }

  /// Verifica conectividade atual
  Future<void> _checkConnectivity() async {
    try {
      if (_isWeb) {
        // Para web, assumir sempre online (ou fazer ping para servidor)
        _isOnline = true;
      } else {
        final results = await _connectivity.checkConnectivity();
        _isOnline = _hasInternetConnection(results);
        
        // Teste adicional de conectividade real (ping)
        if (_isOnline) {
          _isOnline = await _testInternetConnection();
        }
      }
    } catch (e) {
      AppLogger.error('Error checking connectivity: $e');
      // Em caso de erro, assumir que está online
      _isOnline = true;
    }
  }

  /// Callback para mudanças de conectividade
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    try {
      final hadConnection = _isOnline;
      
      if (_isWeb) {
        _isOnline = true;
      } else {
        _isOnline = _hasInternetConnection(results);
        
        // Teste adicional se aparenta ter conexão
        if (_isOnline) {
          _isOnline = await _testInternetConnection();
        }
      }
      
      // Notificar apenas se houve mudança
      if (hadConnection != _isOnline) {
        AppLogger.info('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
        _connectivityController.add(_isOnline);
      }
    } catch (e) {
      AppLogger.error('Error handling connectivity change: $e');
    }
  }

  /// Verifica se há conexão com internet baseado nos resultados
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
      result != ConnectivityResult.none &&
      result != ConnectivityResult.bluetooth
    );
  }

  /// Testa conexão real com internet (ping)
  Future<bool> _testInternetConnection() async {
    try {
      if (_isWeb) return true;
      
      // Tentar conectar com Google DNS
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      AppLogger.debug('Internet connection test failed: $e');
      return false;
    }
  }

  /// Força verificação de conectividade
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isOnline;
  }

  /// Dispose do serviço
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}