import '../entities/user.dart';

abstract class PermissionService {
  bool canCreate(User? user);
  bool canUpdate(User? user);
  bool canDelete(User? user);
  bool canView(User? user);
  bool isAdmin(User? user);
}

class PermissionServiceImpl implements PermissionService {
  @override
  bool canCreate(User? user) {
    if (user == null) return false;
    return user.canCreate;
  }

  @override
  bool canUpdate(User? user) {
    if (user == null) return false;
    return user.canUpdate;
  }

  @override
  bool canDelete(User? user) {
    if (user == null) return false;
    return user.canDelete;
  }

  @override
  bool canView(User? user) {
    if (user == null) return false;
    return user.canView;
  }

  @override
  bool isAdmin(User? user) {
    if (user == null) return false;
    return user.isAdmin;
  }
}