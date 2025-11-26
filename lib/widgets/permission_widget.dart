import 'package:flutter/material.dart';
import '../services/services.dart';

/// Widget que muestra u oculta contenido basado en permisos
class PermissionWidget extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: HttpService().getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return fallback ?? const SizedBox.shrink();
        }

        final hasPermission = PermissionsService.hasPermission(
          snapshot.data,
          permission,
        );

        if (hasPermission) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget que deshabilita contenido basado en permisos
class PermissionBuilder extends StatelessWidget {
  final String permission;
  final Widget Function(BuildContext context, bool hasPermission) builder;

  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: HttpService().getUserRole(),
      builder: (context, snapshot) {
        final hasPermission = snapshot.hasData &&
            PermissionsService.hasPermission(
              snapshot.data,
              permission,
            );

        return builder(context, hasPermission);
      },
    );
  }
}

/// Mixin para facilitar verificación de permisos en pantallas
mixin PermissionsMixin<T extends StatefulWidget> on State<T> {
  String? _userRole;

  Future<void> loadUserRole() async {
    final role = await HttpService().getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  bool hasPermission(String permission) {
    return PermissionsService.hasPermission(_userRole, permission);
  }

  bool get isAdmin => _userRole?.toUpperCase() == 'ADMIN';
  bool get isManager => _userRole?.toUpperCase() == 'MANAGER';
  bool get isClerk => _userRole?.toUpperCase() == 'CLERK';
}
