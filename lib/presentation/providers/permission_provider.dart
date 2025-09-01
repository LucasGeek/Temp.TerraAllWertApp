import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/permission_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

final canCreateProvider = Provider<bool>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  final userAsync = ref.watch(authControllerProvider);
  
  return userAsync.when(
    data: (user) => permissionService.canCreate(user),
    loading: () => false,
    error: (_, _) => false,
  );
});

final canUpdateProvider = Provider<bool>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  final userAsync = ref.watch(authControllerProvider);
  
  return userAsync.when(
    data: (user) => permissionService.canUpdate(user),
    loading: () => false,
    error: (_, _) => false,
  );
});

final canDeleteProvider = Provider<bool>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  final userAsync = ref.watch(authControllerProvider);
  
  return userAsync.when(
    data: (user) => permissionService.canDelete(user),
    loading: () => false,
    error: (_, _) => false,
  );
});

final canViewProvider = Provider<bool>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  final userAsync = ref.watch(authControllerProvider);
  
  return userAsync.when(
    data: (user) => permissionService.canView(user),
    loading: () => false,
    error: (_, _) => false,
  );
});

final isAdminProvider = Provider<bool>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  final userAsync = ref.watch(authControllerProvider);
  
  return userAsync.when(
    data: (user) => permissionService.isAdmin(user),
    loading: () => false,
    error: (_, _) => false,
  );
});