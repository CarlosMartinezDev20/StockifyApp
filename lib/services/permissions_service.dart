/// Servicio para gestión de permisos por rol
class PermissionsService {
  /// Permisos por acción
  static final Map<String, List<String>> _permissions = {
    // USUARIOS - Solo ADMIN
    'users.view': ['ADMIN'],
    'users.create': ['ADMIN'],
    'users.edit': ['ADMIN'],
    'users.delete': ['ADMIN'],
    
    // PRODUCTOS - ADMIN y MANAGER pueden todo, CLERK solo ver
    'products.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'products.create': ['ADMIN', 'MANAGER'],
    'products.edit': ['ADMIN', 'MANAGER'],
    'products.delete': ['ADMIN', 'MANAGER'],
    
    // CATEGORÍAS - ADMIN y MANAGER pueden todo, CLERK solo ver
    'categories.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'categories.create': ['ADMIN', 'MANAGER'],
    'categories.edit': ['ADMIN', 'MANAGER'],
    'categories.delete': ['ADMIN', 'MANAGER'],
    
    // ALMACENES - ADMIN y MANAGER pueden todo, CLERK solo ver
    'warehouses.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'warehouses.create': ['ADMIN', 'MANAGER'],
    'warehouses.edit': ['ADMIN', 'MANAGER'],
    'warehouses.delete': ['ADMIN', 'MANAGER'],
    
    // INVENTARIO - ADMIN y MANAGER pueden ajustar, todos pueden ver
    'inventory.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'inventory.adjust': ['ADMIN', 'MANAGER'],
    
    // MOVIMIENTOS DE STOCK - Todos pueden ver, solo ADMIN y MANAGER crean
    'stock_movements.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'stock_movements.create': ['ADMIN', 'MANAGER'],
    
    // ÓRDENES DE VENTA - Todos pueden crear y ver, MANAGER y ADMIN confirmar/cumplir
    'sales_orders.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'sales_orders.create': ['ADMIN', 'MANAGER', 'CLERK'],
    'sales_orders.edit': ['ADMIN', 'MANAGER', 'CLERK'],
    'sales_orders.confirm': ['ADMIN', 'MANAGER'],
    'sales_orders.fulfill': ['ADMIN', 'MANAGER'],
    'sales_orders.cancel': ['ADMIN', 'MANAGER'],
    'sales_orders.delete': ['ADMIN', 'MANAGER'],
    
    // ÓRDENES DE COMPRA - ADMIN y MANAGER pueden todo, CLERK solo ver
    'purchase_orders.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'purchase_orders.create': ['ADMIN', 'MANAGER'],
    'purchase_orders.edit': ['ADMIN', 'MANAGER'],
    'purchase_orders.receive': ['ADMIN', 'MANAGER'],
    'purchase_orders.cancel': ['ADMIN', 'MANAGER'],
    'purchase_orders.delete': ['ADMIN', 'MANAGER'],
    
    // CLIENTES - Todos pueden ver y crear, ADMIN y MANAGER editar/eliminar
    'customers.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'customers.create': ['ADMIN', 'MANAGER', 'CLERK'],
    'customers.edit': ['ADMIN', 'MANAGER'],
    'customers.delete': ['ADMIN', 'MANAGER'],
    
    // PROVEEDORES - ADMIN y MANAGER pueden todo, CLERK solo ver
    'suppliers.view': ['ADMIN', 'MANAGER', 'CLERK'],
    'suppliers.create': ['ADMIN', 'MANAGER'],
    'suppliers.edit': ['ADMIN', 'MANAGER'],
    'suppliers.delete': ['ADMIN', 'MANAGER'],
    
    // CONFIGURACIÓN - Solo ADMIN
    'configuration.view': ['ADMIN'],
    'configuration.edit': ['ADMIN'],
  };

  /// Verificar si un rol tiene permiso para una acción
  static bool hasPermission(String? role, String permission) {
    if (role == null) return false;
    
    final allowedRoles = _permissions[permission];
    if (allowedRoles == null) return false;
    
    return allowedRoles.contains(role.toUpperCase());
  }

  /// Obtener descripción de permisos por rol
  static String getRoleDescription(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return '''
👑 ADMINISTRADOR - Acceso Total
• Gestión completa de usuarios
• Crear, editar y eliminar todo
• Acceso a configuración del sistema
• Confirmar y cumplir órdenes
• Ajustes de inventario
• Control total de productos, categorías y almacenes
''';
      
      case 'MANAGER':
        return '''
👔 GERENTE - Gestión Operativa
• Ver usuarios (sin editar)
• Gestión completa de productos y categorías
• Gestión de almacenes e inventario
• Crear, confirmar y cumplir órdenes de venta
• Gestión completa de órdenes de compra
• Editar y eliminar clientes/proveedores
• Ajustes de inventario
• Sin acceso a configuración del sistema
''';
      
      case 'CLERK':
        return '''
👤 EMPLEADO - Operaciones Básicas
• Ver productos, categorías y almacenes (sin editar)
• Ver inventario y movimientos de stock (sin ajustar)
• Crear y editar órdenes de venta (sin confirmar/cumplir)
• Ver órdenes de compra (sin editar)
• Crear clientes (sin editar/eliminar)
• Ver proveedores (sin editar)
• Sin acceso a usuarios ni configuración
''';
      
      default:
        return 'Rol desconocido';
    }
  }

  /// Obtener resumen de permisos por módulo
  static Map<String, Map<String, bool>> getPermissionsByModule(String? role) {
    if (role == null) return {};

    return {
      'Usuarios': {
        'Ver': hasPermission(role, 'users.view'),
        'Crear': hasPermission(role, 'users.create'),
        'Editar': hasPermission(role, 'users.edit'),
        'Eliminar': hasPermission(role, 'users.delete'),
      },
      'Productos': {
        'Ver': hasPermission(role, 'products.view'),
        'Crear': hasPermission(role, 'products.create'),
        'Editar': hasPermission(role, 'products.edit'),
        'Eliminar': hasPermission(role, 'products.delete'),
      },
      'Categorías': {
        'Ver': hasPermission(role, 'categories.view'),
        'Crear': hasPermission(role, 'categories.create'),
        'Editar': hasPermission(role, 'categories.edit'),
        'Eliminar': hasPermission(role, 'categories.delete'),
      },
      'Almacenes': {
        'Ver': hasPermission(role, 'warehouses.view'),
        'Crear': hasPermission(role, 'warehouses.create'),
        'Editar': hasPermission(role, 'warehouses.edit'),
        'Eliminar': hasPermission(role, 'warehouses.delete'),
      },
      'Inventario': {
        'Ver': hasPermission(role, 'inventory.view'),
        'Ajustar': hasPermission(role, 'inventory.adjust'),
      },
      'Órdenes de Venta': {
        'Ver': hasPermission(role, 'sales_orders.view'),
        'Crear': hasPermission(role, 'sales_orders.create'),
        'Editar': hasPermission(role, 'sales_orders.edit'),
        'Confirmar': hasPermission(role, 'sales_orders.confirm'),
        'Cumplir': hasPermission(role, 'sales_orders.fulfill'),
        'Cancelar': hasPermission(role, 'sales_orders.cancel'),
      },
      'Órdenes de Compra': {
        'Ver': hasPermission(role, 'purchase_orders.view'),
        'Crear': hasPermission(role, 'purchase_orders.create'),
        'Editar': hasPermission(role, 'purchase_orders.edit'),
        'Recibir': hasPermission(role, 'purchase_orders.receive'),
        'Cancelar': hasPermission(role, 'purchase_orders.cancel'),
      },
      'Clientes': {
        'Ver': hasPermission(role, 'customers.view'),
        'Crear': hasPermission(role, 'customers.create'),
        'Editar': hasPermission(role, 'customers.edit'),
        'Eliminar': hasPermission(role, 'customers.delete'),
      },
      'Proveedores': {
        'Ver': hasPermission(role, 'suppliers.view'),
        'Crear': hasPermission(role, 'suppliers.create'),
        'Editar': hasPermission(role, 'suppliers.edit'),
        'Eliminar': hasPermission(role, 'suppliers.delete'),
      },
    };
  }

  /// Verificar permisos múltiples (requiere todos)
  static bool hasAllPermissions(String? role, List<String> permissions) {
    return permissions.every((permission) => hasPermission(role, permission));
  }

  /// Verificar permisos múltiples (requiere al menos uno)
  static bool hasAnyPermission(String? role, List<String> permissions) {
    return permissions.any((permission) => hasPermission(role, permission));
  }
}
