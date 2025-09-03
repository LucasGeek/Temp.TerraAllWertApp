import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para verificar se o usuário pode atualizar
final canUpdateProvider = Provider<bool>((ref) {
  // TODO: Implementar lógica real de permissão baseada no usuário logado
  // Por enquanto, todos podem editar para demonstração
  return true;
});

/// Provider para verificar se o usuário pode deletar
final canDeleteProvider = Provider<bool>((ref) {
  // TODO: Implementar lógica real de permissão baseada no usuário logado
  // Por enquanto, todos podem deletar para demonstração
  return true;
});