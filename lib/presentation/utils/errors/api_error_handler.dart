import 'package:dio/dio.dart';

class ApiErrorHandler {
  /// Extrai a mensagem de erro específica da API
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is Exception) {
      return _extractExceptionMessage(error);
    } else {
      return 'Erro inesperado. Tente novamente.';
    }
  }

  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo limite excedido. Verifique sua conexão.';
        
      case DioExceptionType.badResponse:
        return _extractResponseError(error) ?? 'Erro no servidor.';
        
      case DioExceptionType.connectionError:
        return 'Erro de conexão. Verifique sua internet.';
        
      case DioExceptionType.cancel:
        return 'Operação cancelada.';
        
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        return _extractResponseError(error) ?? 'Erro de comunicação com o servidor.';
    }
  }

  static String? _extractResponseError(DioException error) {
    try {
      final response = error.response;
      if (response == null) return null;

      // Tentar extrair mensagem do corpo da resposta
      final data = response.data;
      
      if (data is Map<String, dynamic>) {
        // Prioridade para campos comuns de erro
        if (data.containsKey('error') && data['error'] is String) {
          return data['error'] as String;
        }
        if (data.containsKey('message') && data['message'] is String) {
          return data['message'] as String;
        }
        if (data.containsKey('detail') && data['detail'] is String) {
          return data['detail'] as String;
        }
        if (data.containsKey('errorMessage') && data['errorMessage'] is String) {
          return data['errorMessage'] as String;
        }
      }

      // Fallback baseado no status code
      return _getStatusCodeMessage(response.statusCode);
    } catch (e) {
      return null;
    }
  }

  static String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos. Verifique as informações.';
      case 401:
        return 'Email ou senha incorretos.';
      case 403:
        return 'Acesso negado.';
      case 404:
        return 'Recurso não encontrado.';
      case 422:
        return 'Dados inválidos. Verifique as informações.';
      case 429:
        return 'Muitas tentativas. Tente novamente em alguns minutos.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Erro no servidor. Tente novamente mais tarde.';
      default:
        return 'Erro no servidor (${statusCode ?? 'desconhecido'}).';
    }
  }

  static String _extractExceptionMessage(Exception exception) {
    final message = exception.toString();
    
    // Remover prefixos comuns de Exception
    final cleanMessage = message
        .replaceFirst('Exception: ', '')
        .replaceFirst('Failed to login: ', '')
        .replaceFirst('Login failed: ', '')
        .replaceFirst('DioException [', '')
        .replaceFirst(']: ', '');

    // Se a mensagem ainda contém termos técnicos, usar mensagem amigável
    if (cleanMessage.toLowerCase().contains('dioexception') ||
        cleanMessage.toLowerCase().contains('sockexception') ||
        cleanMessage.toLowerCase().contains('httpsexception')) {
      return 'Erro de conexão. Verifique sua internet.';
    }

    return cleanMessage.isNotEmpty ? cleanMessage : 'Erro inesperado.';
  }
}