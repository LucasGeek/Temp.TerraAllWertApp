import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Gerenciador de retry com backoff exponencial
class RetryManager {
  static const int defaultMaxRetries = 3;
  static const Duration defaultBaseDelay = Duration(seconds: 1);
  static const double defaultBackoffMultiplier = 2.0;
  static const Duration defaultMaxDelay = Duration(minutes: 5);
  
  /// Executa operação com retry automático
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    dynamic lastError;
    
    while (attempts <= maxRetries) {
      try {
        AppLogger.debug(
          'Executing $operationName (attempt ${attempts + 1}/${maxRetries + 1})',
          tag: 'RetryManager'
        );
        
        final result = await operation();
        
        if (attempts > 0) {
          AppLogger.info(
            'Operation $operationName succeeded after ${attempts + 1} attempts',
            tag: 'RetryManager'
          );
        }
        
        return result;
        
      } catch (error) {
        lastError = error;
        attempts++;
        
        // Verificar se deve fazer retry
        if (attempts > maxRetries || !_shouldRetryError(error, shouldRetry)) {
          AppLogger.error(
            'Operation $operationName failed permanently after $attempts attempts: $error',
            tag: 'RetryManager'
          );
          rethrow;
        }
        
        // Calcular delay com backoff exponencial
        final delay = _calculateDelay(
          attempt: attempts,
          baseDelay: baseDelay,
          backoffMultiplier: backoffMultiplier,
          maxDelay: maxDelay,
        );
        
        AppLogger.warning(
          'Operation $operationName failed (attempt $attempts/${maxRetries + 1}): $error. '
          'Retrying in ${delay.inMilliseconds}ms...',
          tag: 'RetryManager'
        );
        
        // Aguardar antes de tentar novamente
        await Future.delayed(delay);
      }
    }
    
    // Nunca deveria chegar aqui, mas por segurança
    throw lastError ?? Exception('Unknown retry error');
  }
  
  /// Executa múltiplas operações com retry individualizado
  static Future<List<RetryResult<T>>> executeMultipleWithRetry<T>({
    required List<RetryOperation<T>> operations,
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
    Function(String operationId, int attempt, dynamic error)? onRetry,
  }) async {
    final results = <RetryResult<T>>[];
    
    // Executar todas as operações em paralelo
    final futures = operations.map((operation) async {
      try {
        final result = await executeWithRetry<T>(
          operation: operation.operation,
          operationName: operation.name,
          maxRetries: maxRetries,
          baseDelay: baseDelay,
          backoffMultiplier: backoffMultiplier,
          maxDelay: maxDelay,
          shouldRetry: shouldRetry,
        );
        
        return RetryResult<T>(
          operationId: operation.id,
          operationName: operation.name,
          success: true,
          result: result,
          attemptCount: 1, // Será atualizado se houver retry
        );
        
      } catch (error) {
        onRetry?.call(operation.id, maxRetries + 1, error);
        
        return RetryResult<T>(
          operationId: operation.id,
          operationName: operation.name,
          success: false,
          error: error,
          attemptCount: maxRetries + 1,
        );
      }
    });
    
    results.addAll(await Future.wait(futures));
    
    final successCount = results.where((r) => r.success).length;
    final failureCount = results.length - successCount;
    
    AppLogger.info(
      'Batch retry operations completed: $successCount success, $failureCount failed',
      tag: 'RetryManager'
    );
    
    return results;
  }
  
  /// Stream com retry automático para downloads
  static Stream<T> streamWithRetry<T>({
    required Stream<T> Function() streamFactory,
    required String operationName,
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
  }) async* {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        AppLogger.debug(
          'Starting stream $operationName (attempt ${attempts + 1}/${maxRetries + 1})',
          tag: 'RetryManager'
        );
        
        await for (final item in streamFactory()) {
          yield item;
        }
        
        // Stream completou com sucesso
        if (attempts > 0) {
          AppLogger.info(
            'Stream $operationName succeeded after ${attempts + 1} attempts',
            tag: 'RetryManager'
          );
        }
        
        return; // Sair do loop
        
      } catch (error) {
        attempts++;
        
        if (attempts > maxRetries || !_shouldRetryError(error, shouldRetry)) {
          AppLogger.error(
            'Stream $operationName failed permanently after $attempts attempts: $error',
            tag: 'RetryManager'
          );
          rethrow;
        }
        
        final delay = _calculateDelay(
          attempt: attempts,
          baseDelay: baseDelay,
          backoffMultiplier: backoffMultiplier,
          maxDelay: maxDelay,
        );
        
        AppLogger.warning(
          'Stream $operationName failed (attempt $attempts/${maxRetries + 1}): $error. '
          'Retrying in ${delay.inMilliseconds}ms...',
          tag: 'RetryManager'
        );
        
        await Future.delayed(delay);
      }
    }
  }
  
  /// Calcula delay com backoff exponencial e jitter
  static Duration _calculateDelay({
    required int attempt,
    required Duration baseDelay,
    required double backoffMultiplier,
    required Duration maxDelay,
  }) {
    // Backoff exponencial: baseDelay * (backoffMultiplier ^ attempt)
    final exponentialDelay = baseDelay.inMilliseconds * 
        math.pow(backoffMultiplier, attempt - 1);
    
    // Aplicar jitter (±25%) para evitar thundering herd
    final jitter = 0.75 + (math.Random().nextDouble() * 0.5); // 0.75 - 1.25
    final delayWithJitter = (exponentialDelay * jitter).round();
    
    // Aplicar limite máximo
    final clampedDelay = math.min(delayWithJitter, maxDelay.inMilliseconds);
    
    return Duration(milliseconds: clampedDelay);
  }
  
  /// Determina se deve fazer retry baseado no tipo de erro
  static bool _shouldRetryError(
    dynamic error, 
    bool Function(dynamic error)? customShouldRetry
  ) {
    // Usar função customizada se fornecida
    if (customShouldRetry != null) {
      return customShouldRetry(error);
    }
    
    // Regras padrão de retry
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
          
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode != null) {
            // Retry para erros de servidor (5xx) e alguns 4xx específicos
            return statusCode >= 500 || // Server errors
                   statusCode == 408 || // Request Timeout
                   statusCode == 429;   // Too Many Requests
          }
          return false;
          
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return false;
      }
    }
    
    // Retry para erros de rede/IO
    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException) {
      return true;
    }
    
    // Não fazer retry para outros tipos de erro
    return false;
  }
}

/// Operação para retry em batch
class RetryOperation<T> {
  final String id;
  final String name;
  final Future<T> Function() operation;
  
  RetryOperation({
    required this.id,
    required this.name,
    required this.operation,
  });
}

/// Resultado de operação com retry
class RetryResult<T> {
  final String operationId;
  final String operationName;
  final bool success;
  final T? result;
  final dynamic error;
  final int attemptCount;
  
  RetryResult({
    required this.operationId,
    required this.operationName,
    required this.success,
    this.result,
    this.error,
    required this.attemptCount,
  });
  
  @override
  String toString() {
    return 'RetryResult{id: $operationId, success: $success, attempts: $attemptCount}';
  }
}

/// Configuração de retry personalizada
class RetryConfig {
  final int maxRetries;
  final Duration baseDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(dynamic error)? shouldRetry;
  
  const RetryConfig({
    this.maxRetries = RetryManager.defaultMaxRetries,
    this.baseDelay = RetryManager.defaultBaseDelay,
    this.backoffMultiplier = RetryManager.defaultBackoffMultiplier,
    this.maxDelay = RetryManager.defaultMaxDelay,
    this.shouldRetry,
  });
  
  /// Configuração para uploads (mais agressiva)
  static const RetryConfig upload = RetryConfig(
    maxRetries: 5,
    baseDelay: Duration(seconds: 2),
    backoffMultiplier: 1.5,
    maxDelay: Duration(minutes: 2),
  );
  
  /// Configuração para downloads (padrão)
  static const RetryConfig download = RetryConfig(
    maxRetries: 3,
    baseDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: Duration(minutes: 1),
  );
  
  /// Configuração para operações críticas (mais conservativa)
  static const RetryConfig critical = RetryConfig(
    maxRetries: 2,
    baseDelay: Duration(milliseconds: 500),
    backoffMultiplier: 3.0,
    maxDelay: Duration(seconds: 30),
  );
}