import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para controlar o modo de desenvolvimento
/// Quando ativo, usa dados mockados ao invés de fazer chamadas reais
final developmentModeProvider = StateProvider<bool>((ref) {
  // Ativa modo desenvolvimento quando não conseguir conectar ao backend
  return true;
});

/// Provider para indicar se deve fazer bypass de autenticação
final bypassAuthProvider = Provider<bool>((ref) {
  return ref.watch(developmentModeProvider);
});