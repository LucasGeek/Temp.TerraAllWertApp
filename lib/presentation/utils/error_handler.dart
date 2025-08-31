import 'package:graphql_flutter/graphql_flutter.dart';

/// Utilitário para tratar erros e convertê-los em mensagens amigáveis
class ErrorHandler {
  /// Converte erros de autenticação em mensagens amigáveis para o usuário
  static String getAuthErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // GraphQL errors específicos - verificar primeiro
    if (error is OperationException) {
      if (error.graphqlErrors.isNotEmpty) {
        final graphqlError = error.graphqlErrors.first;
        final graphqlMessage = graphqlError.message.toLowerCase();
        
        // Erros de autenticação do GraphQL
        if (graphqlMessage.contains('email ou senha incorretos') ||
            graphqlMessage.contains('invalid credentials') ||
            graphqlMessage.contains('invalid email or password') ||
            graphqlMessage.contains('authentication failed') ||
            graphqlMessage.contains('authentication_error')) {
          return 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.';
        }
        
        // Retorna a mensagem do servidor se for específica
        if (graphqlError.message.isNotEmpty && !graphqlMessage.contains('exception')) {
          return graphqlError.message;
        }
      }
      
      // Se tem linkException, é erro de conexão
      if (error.linkException != null) {
        return 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.';
      }
    }
    
    // Erros de autenticação específicos
    if (errorString.contains('email ou senha incorretos') ||
        errorString.contains('invalid credentials') ||
        errorString.contains('invalid email or password') ||
        errorString.contains('authentication failed') ||
        errorString.contains('unauthorized') ||
        errorString.contains('authentication_error') ||
        errorString.contains('401')) {
      return 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.';
    }
    
    // Erros de conexão - verificar depois dos erros de auth
    if (errorString.contains('failed to fetch') ||
        errorString.contains('clientexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network error') ||
        errorString.contains('timeout')) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.';
    }
    
    // Erro de usuário não encontrado
    if (errorString.contains('user not found') ||
        errorString.contains('user does not exist')) {
      return 'Usuário não encontrado. Verifique o email digitado.';
    }
    
    // Erro de conta desabilitada/suspensa
    if (errorString.contains('account disabled') ||
        errorString.contains('account suspended') ||
        errorString.contains('account locked')) {
      return 'Sua conta está desabilitada. Entre em contato com o suporte.';
    }
    
    // Erro de validação de formato
    if (errorString.contains('invalid email format') ||
        errorString.contains('email format')) {
      return 'Formato de email inválido. Verifique e tente novamente.';
    }
    
    // Erro de senha muito fraca
    if (errorString.contains('password too weak') ||
        errorString.contains('weak password')) {
      return 'Senha muito fraca. Use pelo menos 8 caracteres com letras e números.';
    }
    
    // Erro de rate limiting
    if (errorString.contains('too many requests') ||
        errorString.contains('rate limit') ||
        errorString.contains('429')) {
      return 'Muitas tentativas de login. Aguarde alguns minutos e tente novamente.';
    }
    
    // Erro de servidor
    if (errorString.contains('500') ||
        errorString.contains('server error') ||
        errorString.contains('internal server error') ||
        errorString.contains('erro interno do servidor')) {
      return 'Erro interno do servidor. Possível problema com credenciais ou configuração do servidor. Tente com diferentes credenciais ou entre em contato com o administrador.';
    }
    
    // Erro de serviço indisponível
    if (errorString.contains('503') ||
        errorString.contains('service unavailable')) {
      return 'Serviço temporariamente indisponível. Tente novamente mais tarde.';
    }
    
    // Fallback para erro genérico de autenticação
    return 'Erro ao fazer login. Verifique suas credenciais e tente novamente.';
  }
  
  /// Trata erros específicos do GraphQL
  static String getGraphQLErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('authentication failed')) {
      return 'Email ou senha incorretos.';
    }
    
    if (lowerMessage.contains('user not found')) {
      return 'Usuário não encontrado.';
    }
    
    if (lowerMessage.contains('validation')) {
      return 'Dados inválidos. Verifique as informações digitadas.';
    }
    
    return 'Erro ao processar solicitação. Tente novamente.';
  }
  
  /// Trata erros de conexão/link
  static String getLinkErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('timeout')) {
      return 'Problema de conexão. Verifique sua internet.';
    }
    
    return 'Erro de comunicação com o servidor.';
  }
  
  /// Converte erros gerais em mensagens amigáveis
  static String getGenericErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // Erros de validação de formulário
    if (errorString.contains('validation') ||
        errorString.contains('invalid input')) {
      return 'Por favor, verifique os dados digitados.';
    }
    
    // Erros de permissão
    if (errorString.contains('forbidden') ||
        errorString.contains('permission denied') ||
        errorString.contains('403')) {
      return 'Você não tem permissão para realizar esta ação.';
    }
    
    // Erro genérico
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}