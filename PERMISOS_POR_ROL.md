# 🔐 SISTEMA DE PERMISOS POR ROL

## 📊 Resumen de Roles

### 👑 ADMINISTRADOR (ADMIN)
**Acceso Total al Sistema**

#### ✅ Permisos Completos:
- **Usuarios**: Ver, Crear, Editar, Eliminar
- **Productos**: Ver, Crear, Editar, Eliminar
- **Categorías**: Ver, Crear, Editar, Eliminar
- **Almacenes**: Ver, Crear, Editar, Eliminar
- **Inventario**: Ver, Ajustar cantidades
- **Movimientos de Stock**: Ver, Crear
- **Órdenes de Venta**: Ver, Crear, Editar, Confirmar, Cumplir, Cancelar, Eliminar
- **Órdenes de Compra**: Ver, Crear, Editar, Recibir, Cancelar, Eliminar
- **Clientes**: Ver, Crear, Editar, Eliminar
- **Proveedores**: Ver, Crear, Editar, Eliminar
- **Configuración**: Ver, Editar

#### 🎯 Casos de Uso:
- Gestión completa del sistema
- Creación y administración de usuarios
- Configuración del sistema
- Supervisión de todas las operaciones
- Resolución de problemas críticos

---

### 👔 GERENTE (MANAGER)
**Gestión Operativa y Supervisión**

#### ✅ Puede Hacer:
- **Usuarios**: Ver (sin editar ni eliminar)
- **Productos**: Ver, Crear, Editar, Eliminar
- **Categorías**: Ver, Crear, Editar, Eliminar
- **Almacenes**: Ver, Crear, Editar, Eliminar
- **Inventario**: Ver, Ajustar cantidades
- **Movimientos de Stock**: Ver, Crear
- **Órdenes de Venta**: Ver, Crear, Editar, Confirmar, Cumplir, Cancelar, Eliminar
- **Órdenes de Compra**: Ver, Crear, Editar, Recibir, Cancelar, Eliminar
- **Clientes**: Ver, Crear, Editar, Eliminar
- **Proveedores**: Ver, Crear, Editar, Eliminar

#### ❌ No Puede Hacer:
- Crear, editar o eliminar usuarios
- Acceder a configuración del sistema

#### 🎯 Casos de Uso:
- Supervisión diaria de operaciones
- Gestión de inventario y stock
- Confirmación y cumplimiento de órdenes
- Gestión de productos y categorías
- Relación con clientes y proveedores
- Reportes y análisis

---

### 👤 EMPLEADO (CLERK)
**Operaciones Básicas del Día a Día**

#### ✅ Puede Hacer:
- **Productos**: Ver
- **Categorías**: Ver
- **Almacenes**: Ver
- **Inventario**: Ver
- **Movimientos de Stock**: Ver
- **Órdenes de Venta**: Ver, Crear, Editar (sin confirmar ni cumplir)
- **Órdenes de Compra**: Ver
- **Clientes**: Ver, Crear
- **Proveedores**: Ver

#### ❌ No Puede Hacer:
- Ver, crear o editar usuarios
- Crear, editar o eliminar productos
- Crear, editar o eliminar categorías
- Crear, editar o eliminar almacenes
- Ajustar inventario
- Crear movimientos de stock
- Confirmar, cumplir o cancelar órdenes de venta
- Crear, editar, recibir o cancelar órdenes de compra
- Editar o eliminar clientes
- Crear, editar o eliminar proveedores
- Acceder a configuración

#### 🎯 Casos de Uso:
- Atención al cliente
- Registro de ventas
- Consulta de inventario
- Creación de clientes nuevos
- Consulta de información

---

## 📋 Tabla Comparativa de Permisos

| Módulo | Acción | ADMIN | MANAGER | CLERK |
|--------|--------|-------|---------|-------|
| **Usuarios** | Ver | ✅ | ❌ | ❌ |
| | Crear | ✅ | ❌ | ❌ |
| | Editar | ✅ | ❌ | ❌ |
| | Eliminar | ✅ | ❌ | ❌ |
| **Productos** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ❌ |
| | Editar | ✅ | ✅ | ❌ |
| | Eliminar | ✅ | ✅ | ❌ |
| **Categorías** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ❌ |
| | Editar | ✅ | ✅ | ❌ |
| | Eliminar | ✅ | ✅ | ❌ |
| **Almacenes** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ❌ |
| | Editar | ✅ | ✅ | ❌ |
| | Eliminar | ✅ | ✅ | ❌ |
| **Inventario** | Ver | ✅ | ✅ | ✅ |
| | Ajustar | ✅ | ✅ | ❌ |
| **Mov. Stock** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ❌ |
| **Órd. Venta** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ✅ |
| | Editar | ✅ | ✅ | ✅ |
| | Confirmar | ✅ | ✅ | ❌ |
| | Cumplir | ✅ | ✅ | ❌ |
| | Cancelar | ✅ | ✅ | ❌ |
| | Eliminar | ✅ | ✅ | ❌ |
| **Órd. Compra** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ❌ |
| | Editar | ✅ | ✅ | ❌ |
| | Recibir | ✅ | ✅ | ❌ |
| | Cancelar | ✅ | ✅ | ❌ |
| | Eliminar | ✅ | ✅ | ❌ |
| **Clientes** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ✅ |
| | Editar | ✅ | ✅ | ❌ |
| | Eliminar | ✅ | ✅ | ❌ |
| **Proveedores** | Ver | ✅ | ✅ | ✅ |
| | Crear | ✅ | ✅ | ❌ |
| | Editar | ✅ | ✅ | ❌ |
| | Eliminar | ✅ | ✅ | ❌ |
| **Configuración** | Ver | ✅ | ❌ | ❌ |
| | Editar | ✅ | ❌ | ❌ |

---

## 🎨 Identificación Visual

### Colores por Rol:
- **ADMIN**: 🔴 Rojo (Error color) - Poder y precaución
- **MANAGER**: 🟣 Morado (Tertiary color) - Gestión y liderazgo
- **CLERK**: 🔵 Azul (Primary color) - Operaciones estándar

### Iconos por Rol:
- **ADMIN**: 👑 `admin_panel_settings`
- **MANAGER**: 👔 `manage_accounts`
- **CLERK**: 👤 `person`

---

## 🔐 Implementación Técnica

### Servicio de Permisos
```dart
// Verificar permiso individual
PermissionsService.hasPermission('ADMIN', 'products.create'); // true
PermissionsService.hasPermission('CLERK', 'products.create'); // false

// Verificar múltiples permisos (todos)
PermissionsService.hasAllPermissions('MANAGER', [
  'products.view',
  'products.edit'
]); // true

// Verificar múltiples permisos (al menos uno)
PermissionsService.hasAnyPermission('CLERK', [
  'products.create',
  'products.view'
]); // true (puede ver)

// Obtener descripción del rol
PermissionsService.getRoleDescription('ADMIN');

// Obtener todos los permisos por módulo
PermissionsService.getPermissionsByModule('MANAGER');
```

### En las Vistas
```dart
// Ocultar botón de crear si no tiene permiso
if (PermissionsService.hasPermission(userRole, 'products.create'))
  FloatingActionButton(
    onPressed: () => createProduct(),
    child: Icon(Icons.add),
  )

// Deshabilitar acción si no tiene permiso
onPressed: PermissionsService.hasPermission(userRole, 'orders.confirm')
    ? () => confirmOrder()
    : null
```

---

## 📱 Pantallas del Sistema

### 1. **Pantalla de Permisos por Rol**
Ubicación: Configuración → "Permisos por Rol"

Muestra:
- Cards expandibles para cada rol
- Descripción detallada del rol
- Tabla visual de permisos por módulo
- Chips verdes (permitido) / rojos (denegado)

### 2. **Formulario de Usuario**
Botón: "Ver Permisos"
- Permite ver permisos antes de asignar rol
- Ayuda a tomar decisión informada

---

## 🚀 Recomendaciones de Uso

### Para ADMIN:
1. Crear solo los usuarios necesarios
2. Asignar el rol más bajo que cumpla las necesidades
3. Revisar periódicamente los permisos
4. Cambiar contraseñas regularmente
5. No compartir credenciales de admin

### Para MANAGER:
1. Supervisar las operaciones diarias
2. Capacitar a los empleados (CLERK)
3. Validar inventarios regularmente
4. Revisar órdenes pendientes
5. Mantener actualizado el catálogo

### Para CLERK:
1. Registrar ventas correctamente
2. Consultar disponibilidad antes de vender
3. Crear clientes nuevos cuando sea necesario
4. No intentar acceder a áreas restringidas
5. Reportar problemas al gerente

---

## 🔄 Flujos de Trabajo Típicos

### Venta (CLERK):
1. Consultar inventario ✅
2. Crear cliente si es nuevo ✅
3. Crear orden de venta ✅
4. Esperar confirmación del MANAGER ⏳

### Confirmación de Venta (MANAGER):
1. Revisar orden de venta ✅
2. Confirmar orden ✅
3. Cumplir orden (despachar) ✅

### Compra a Proveedor (MANAGER):
1. Verificar inventario bajo ✅
2. Crear orden de compra ✅
3. Recibir mercancía ✅
4. Ajustar inventario ✅

### Gestión de Usuarios (ADMIN):
1. Crear nuevo usuario ✅
2. Asignar rol apropiado ✅
3. Informar credenciales ✅
4. Solicitar cambio de contraseña ✅

---

## 📞 Soporte

Para cambios en permisos o escalamiento de rol, contactar al administrador del sistema.

**Nota**: Este sistema de permisos está implementado tanto en el frontend (Flutter) como en el backend (NestJS) para máxima seguridad.
