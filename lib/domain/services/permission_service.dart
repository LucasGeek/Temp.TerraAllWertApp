import '../entities/user.dart';

abstract class PermissionService {
  bool canCreate(User? user, {bool isOnline = true, bool isWeb = false});
  bool canUpdate(User? user, {bool isOnline = true, bool isWeb = false});
  bool canDelete(User? user, {bool isOnline = true, bool isWeb = false});
  bool canView(User? user, {bool isOnline = true, bool isWeb = false});
  bool isAdmin(User? user);
}

class PermissionServiceImpl implements PermissionService {
  @override
  bool canCreate(User? user, {bool isOnline = true, bool isWeb = false}) {
    // Regra 1: Mobile offline -> apenas visualização
    if (!isWeb && !isOnline) return false;
    
    // Regra 2: Sem usuário -> apenas visualização offline, online exige login
    if (user == null) return false;
    
    // Regra 3: Apenas admin pode criar
    return user.canCreate;
  }

  @override
  bool canUpdate(User? user, {bool isOnline = true, bool isWeb = false}) {
    // Regra 1: Mobile offline -> apenas visualização
    if (!isWeb && !isOnline) return false;
    
    // Regra 2: Sem usuário -> apenas visualização offline, online exige login
    if (user == null) return false;
    
    // Regra 3: Apenas admin pode atualizar
    return user.canUpdate;
  }

  @override
  bool canDelete(User? user, {bool isOnline = true, bool isWeb = false}) {
    // Regra 1: Mobile offline -> apenas visualização
    if (!isWeb && !isOnline) return false;
    
    // Regra 2: Sem usuário -> apenas visualização offline, online exige login
    if (user == null) return false;
    
    // Regra 3: Apenas admin pode excluir
    return user.canDelete;
  }

  @override
  bool canView(User? user, {bool isOnline = true, bool isWeb = false}) {
    // Visualização sempre permitida
    // Offline sem credenciais é permitido
    // Online sem credenciais será tratado no router
    return true;
  }

  @override
  bool isAdmin(User? user) {
    if (user == null) return false;
    return user.isAdmin;
  }
}