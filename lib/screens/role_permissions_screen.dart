import 'package:flutter/material.dart';
import '../services/services.dart';

class RolePermissionsScreen extends StatelessWidget {
  const RolePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos por Rol'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RoleCard(
            role: 'ADMIN',
            color: Theme.of(context).colorScheme.error,
            icon: Icons.admin_panel_settings,
          ),
          const SizedBox(height: 16),
          _RoleCard(
            role: 'MANAGER',
            color: Theme.of(context).colorScheme.tertiary,
            icon: Icons.manage_accounts,
          ),
          const SizedBox(height: 16),
          _RoleCard(
            role: 'CLERK',
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.person,
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String role;
  final Color color;
  final IconData icon;

  const _RoleCard({
    required this.role,
    required this.color,
    required this.icon,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isExpanded = false;

  String _getRoleName() {
    switch (widget.role) {
      case 'ADMIN':
        return 'Administrador';
      case 'MANAGER':
        return 'Gerente';
      case 'CLERK':
        return 'Empleado';
      default:
        return widget.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionsService.getPermissionsByModule(widget.role);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.color.withValues(alpha: 0.2),
              child: Icon(widget.icon, color: widget.color),
            ),
            title: Text(
              _getRoleName(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            subtitle: Text(
              _isExpanded ? 'Toca para contraer' : 'Toca para ver permisos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción del rol
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      PermissionsService.getRoleDescription(widget.role),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tabla de permisos
                  Text(
                    'Permisos Detallados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ...permissions.entries.map((entry) {
                    return _ModulePermissions(
                      module: entry.key,
                      permissions: entry.value,
                      color: widget.color,
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModulePermissions extends StatelessWidget {
  final String module;
  final Map<String, bool> permissions;
  final Color color;

  const _ModulePermissions({
    required this.module,
    required this.permissions,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                _getModuleIcon(),
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                module,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: permissions.entries.map((entry) {
            return _PermissionChip(
              label: entry.key,
              allowed: entry.value,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  IconData _getModuleIcon() {
    switch (module) {
      case 'Usuarios':
        return Icons.people;
      case 'Productos':
        return Icons.inventory_2;
      case 'Categorías':
        return Icons.category;
      case 'Almacenes':
        return Icons.warehouse;
      case 'Inventario':
        return Icons.storage;
      case 'Órdenes de Venta':
        return Icons.shopping_cart;
      case 'Órdenes de Compra':
        return Icons.shopping_bag;
      case 'Clientes':
        return Icons.person;
      case 'Proveedores':
        return Icons.business;
      default:
        return Icons.settings;
    }
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool allowed;

  const _PermissionChip({
    required this.label,
    required this.allowed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: allowed
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allowed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: allowed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: allowed ? Colors.green[800] : Colors.red[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
