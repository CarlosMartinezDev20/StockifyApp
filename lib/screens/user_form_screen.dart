import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'role_permissions_screen.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  
  String _selectedRole = 'CLERK';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool get _isEditing => widget.user != null;

  final List<Map<String, dynamic>> _roles = [
    {'value': 'ADMIN', 'label': 'Administrador', 'icon': Icons.admin_panel_settings},
    {'value': 'MANAGER', 'label': 'Gerente', 'icon': Icons.manage_accounts},
    {'value': 'CLERK', 'label': 'Empleado', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController(text: widget.user?.fullName ?? '');
    _selectedRole = widget.user?.role.toUpperCase() ?? 'CLERK';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Si estamos editando y no hay contraseña, validar que al menos un campo cambió
    if (_isEditing && _passwordController.text.trim().isEmpty) {
      final hasChanges = _emailController.text.trim() != widget.user?.email ||
          _fullNameController.text.trim() != widget.user?.fullName ||
          _selectedRole != widget.user?.role.toUpperCase();
      
      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay cambios para guardar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final Map<String, dynamic> updateData = {
          'email': _emailController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'role': _selectedRole,
        };
        
        // Solo incluir password si se especificó uno nuevo
        if (_passwordController.text.trim().isNotEmpty) {
          updateData['password'] = _passwordController.text.trim();
        }
        
        await _userService.update(widget.user!.id, updateData);
      } else {
        await _userService.create(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          role: _selectedRole,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                ? 'Usuario actualizado correctamente' 
                : 'Usuario creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Icono decorativo
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEditing ? Icons.edit : Icons.person_add,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Nombre completo
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo *',
                hintText: 'Ej: Juan Pérez',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'usuario@ejemplo.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El email es requerido';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contraseña
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Nueva Contraseña (opcional)' : 'Contraseña *',
                hintText: 'Mínimo 6 caracteres',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                // Si estamos creando, la contraseña es obligatoria
                if (!_isEditing && (value == null || value.trim().isEmpty)) {
                  return 'La contraseña es requerida';
                }
                // Si se proporciona una contraseña, validar longitud
                if (value != null && value.trim().isNotEmpty && value.trim().length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _isEditing 
                  ? 'Deja en blanco para mantener la contraseña actual'
                  : 'Debe tener al menos 6 caracteres',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rol
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rol *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RolePermissionsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Ver Permisos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._roles.map((role) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  value: role['value'],
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    setState(() => _selectedRole = value!);
                  },
                  title: Text(role['label']),
                  subtitle: Text(_getRoleDescription(role['value'])),
                  secondary: Icon(role['icon']),
                ),
              );
            }),
            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveUser,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: LoadingIndicator.small(),
                          )
                        : Text(_isEditing ? 'Actualizar' : 'Crear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Acceso completo al sistema';
      case 'MANAGER':
        return 'Gestión de operaciones y reportes';
      case 'CLERK':
        return 'Operaciones básicas del día a día';
      default:
        return '';
    }
  }
}
