import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/permission_provider.dart';

enum PermissionType {
  create,
  update,
  delete,
  view,
  admin,
}

class PermissionWrapper extends ConsumerWidget {
  final PermissionType permission;
  final Widget child;
  final Widget? fallback;
  final bool hideOnNoPermission;

  const PermissionWrapper({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.hideOnNoPermission = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = _checkPermission(ref);

    if (hasPermission) {
      return child;
    }

    if (hideOnNoPermission) {
      return const SizedBox.shrink();
    }

    return fallback ?? const SizedBox.shrink();
  }

  bool _checkPermission(WidgetRef ref) {
    switch (permission) {
      case PermissionType.create:
        return ref.watch(canCreateProvider);
      case PermissionType.update:
        return ref.watch(canUpdateProvider);
      case PermissionType.delete:
        return ref.watch(canDeleteProvider);
      case PermissionType.view:
        return ref.watch(canViewProvider);
      case PermissionType.admin:
        return ref.watch(isAdminProvider);
    }
  }
}

class CreatePermission extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const CreatePermission({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWrapper(
      permission: PermissionType.create,
      fallback: fallback,
      child: child,
    );
  }
}

class UpdatePermission extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const UpdatePermission({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWrapper(
      permission: PermissionType.update,
      fallback: fallback,
      child: child,
    );
  }
}

class DeletePermission extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const DeletePermission({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWrapper(
      permission: PermissionType.delete,
      fallback: fallback,
      child: child,
    );
  }
}

class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWrapper(
      permission: PermissionType.admin,
      fallback: fallback,
      child: child,
    );
  }
}