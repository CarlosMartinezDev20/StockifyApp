
# 📱 Inventory App - Sistema de Gestión de Inventario

Aplicación móvil Flutter desarrollada con **Material Design 3** para gestionar inventarios, productos, órdenes de venta/compra, clientes y proveedores.

## 🎨 Características Principales

### ✅ Material Design 3 (M3)
- **Color Dinámico** habilitado con el paquete `dynamic_color`
- **Paleta Verde Esmeralda** (`Colors.teal`) como color de reserva
- **Temas claro y oscuro** que se adaptan automáticamente al sistema
- **Componentes modernos M3**: Cards, ListTiles, TextField, Buttons, FAB, NavigationBar

### 🔐 Autenticación
- Login con JWT
- Almacenamiento seguro de tokens con `shared_preferences`
- Gestión automática de sesión
- Verificación de token al iniciar la app

### 📊 Módulos Implementados

#### 1. **Dashboard Principal**
- Vista de resumen con tarjetas de acceso rápido
- **BottomNavigationBar M3** con 3 secciones:
  - 🏠 Dashboard
  - 📦 Productos
  - 🛒 Órdenes de Venta
- **Drawer (Menú Lateral)** con secciones adicionales:
  - 📊 Inventario
  - 🔄 Movimientos de Stock
  - 🛍️ Órdenes de Compra
  - 👥 Clientes
  - 🏢 Proveedores
  - ⚙️ Configuración

#### 2. **Gestión de Productos**
- Listado de productos con búsqueda
- Visualización de stock total (suma de todos los almacenes)
- Indicadores de stock (Verde/Naranja/Rojo según disponibilidad)
- Categorización de productos
- Información de SKU, unidad de medida y código de barras

#### 3. **Inventario Multi-Almacén**
- Visualización de niveles de inventario por almacén
- Filtrado por almacén específico
- Indicadores visuales de stock disponible
- Integración con múltiples warehouses

#### 4. **Movimientos de Stock**
- Historial completo de movimientos
- Tipos de movimiento:
  - 📥 **IN** (Entrada) - Verde
  - 📤 **OUT** (Salida) - Rojo
  - 🔧 **ADJUST** (Ajuste) - Naranja
- Visualización de razón y documento de referencia
- Timestamps detallados

#### 5. **Órdenes de Venta**
- Listado de órdenes con estados:
  - 📝 DRAFT (Borrador)
  - ✅ CONFIRMED (Confirmada)
  - ✔️ FULFILLED (Completada)
  - ❌ CANCELLED (Cancelada)
- Información de cliente y items
- Acciones de confirmación y fulfillment

#### 6. **Órdenes de Compra**
- Gestión de órdenes a proveedores
- Estados:
  - 📝 DRAFT (Borrador)
  - 📦 ORDERED (Ordenada)
  - ✅ RECEIVED (Recibida)
  - ❌ CANCELLED (Cancelada)
- Tracking de cantidades ordenadas vs recibidas

#### 7. **Clientes**
- Listado de clientes con información de contacto
- Visualización de email, teléfono y dirección
- Integración con órdenes de venta

#### 8. **Proveedores**
- Gestión de proveedores
- Información de contacto y representante
- Relación con órdenes de compra

#### 9. **Configuración**
- Gestión de tema (claro/oscuro)
- Configuración de idioma
- Notificaciones
- Perfil de usuario
- Cerrar sesión

## 🛠️ Tecnologías Utilizadas

### Dependencias Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.6.0                  # Cliente HTTP para API REST
  dynamic_color: latest          # Color dinámico del sistema
  shared_preferences: ^2.5.3     # Almacenamiento local seguro
```

### Paquetes de Desarrollo
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart                          # Configuración principal y temas M3
├── models/
│   └── product.dart                   # Modelos de datos:
│                                      # - Product, SalesOrder, PurchaseOrder
│                                      # - Customer, Supplier, User
│                                      # - Category, Warehouse
│                                      # - InventoryLevel, StockMovement
├── services/
│   └── api_service.dart               # Servicio API con todos los endpoints
└── screens/
    ├── login_screen.dart              # Pantalla de login
    ├── dashboard_screen.dart          # Dashboard con navegación
    ├── products_screen.dart           # Gestión de productos
    ├── inventory_screen.dart          # Inventario por almacén
    ├── stock_movements_screen.dart    # Historial de movimientos
    ├── sales_orders_screen.dart       # Órdenes de venta
    ├── purchase_orders_screen.dart    # Órdenes de compra
    ├── clients_screen.dart            # Gestión de clientes
    ├── suppliers_screen.dart          # Gestión de proveedores
    └── configuration_screen.dart      # Configuración de la app
```

## 🔌 Integración con Backend

### URL Base de la API
```dart
static const String baseUrl = 'https://inventory-backend-v2.onrender.com';
```

### Endpoints Implementados

#### Autenticación
- `POST /auth/login` - Iniciar sesión

#### Productos
- `GET /products` - Listar productos (con paginación y búsqueda)
- `GET /products/:id` - Obtener producto específico
- `POST /products` - Crear producto
- `PATCH /products/:id` - Actualizar producto
- `DELETE /products/:id` - Eliminar producto

#### Inventario
- `GET /inventory` - Obtener niveles de inventario
- `POST /inventory/adjust` - Ajustar inventario
- `GET /inventory/product/:id` - Inventario por producto
- `GET /inventory/warehouse/:id` - Inventario por almacén

#### Movimientos de Stock
- `GET /stock-movements` - Historial de movimientos

#### Órdenes de Venta
- `GET /sales-orders` - Listar órdenes
- `GET /sales-orders/:id` - Obtener orden específica
- `POST /sales-orders` - Crear orden
- `POST /sales-orders/:id/confirm` - Confirmar orden
- `POST /sales-orders/:id/fulfill` - Cumplir orden

#### Órdenes de Compra
- `GET /purchase-orders` - Listar órdenes
- `GET /purchase-orders/:id` - Obtener orden específica
- `POST /purchase-orders` - Crear orden

#### Clientes y Proveedores
- `GET /customers` - Listar clientes
- `GET /suppliers` - Listar proveedores

#### Almacenes y Categorías
- `GET /warehouses` - Listar almacenes
- `GET /categories` - Listar categorías

### Manejo de Respuestas

El backend devuelve respuestas en formato estandarizado:
```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 100
  }
}
```

## 🚀 Instalación y Ejecución

### Requisitos Previos
- Flutter SDK 3.10.0 o superior
- Dart SDK
- Android Studio / VS Code con extensiones de Flutter
- Dispositivo físico o emulador

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
cd inventoryapp
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Verificar instalación**
```bash
flutter doctor
```

4. **Ejecutar la aplicación**
```bash
flutter run
```

### Credenciales de Prueba

**Usuario Administrador:**
- Email: `admin@local`
- Password: `Admin123!`

## 🎨 Tema y Diseño

### Configuración de Tema M3

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
);
```

### Color Dinámico

La aplicación utiliza `dynamic_color` para adaptarse automáticamente a los colores del sistema operativo (Android 12+), con un fallback a verde esmeralda.

## 📱 Características de UX/UI

### Estados de Carga
- Indicadores de progreso circulares
- Mensajes de error amigables
- Botones de reintento

### Interacciones
- Pull-to-refresh en todas las listas
- Búsqueda en tiempo real
- Navegación fluida con transiciones M3
- Feedback visual con SnackBars

### Diseño Responsivo
- Adaptación automática a diferentes tamaños de pantalla
- Componentes escalables
- Grid layouts para tabletas

## 🔒 Seguridad

- **JWT Tokens** almacenados de forma segura
- **Headers de autenticación** en todas las peticiones protegidas
- **Validación de sesión** al iniciar la app
- **Cierre de sesión** seguro con limpieza de tokens

## 📊 Modelos de Datos

### Product
```dart
{
  id, sku, name, description, categoryId, categoryName,
  unit, minStock, barcode, stockTotal, createdAt, updatedAt
}
```

### InventoryLevel
```dart
{
  id, productId, warehouseId, productName, 
  warehouseName, quantity
}
```

### StockMovement
```dart
{
  id, productId, warehouseId, type (IN/OUT/ADJUST),
  quantity, reason, refDocument, createdAt,
  productName, warehouseName
}
```

### SalesOrder
```dart
{
  id, customerId, customerName, status,
  items: [{ productId, qty, unitPrice, discount }],
  createdAt, updatedAt
}
```

## 🐛 Debugging

### Ver logs
```bash
flutter logs
```

### Análisis de código
```bash
flutter analyze
```

### Tests
```bash
flutter test
```

## 📈 Próximas Funcionalidades

- [ ] Creación de productos desde la app
- [ ] Creación de órdenes de venta/compra
- [ ] Ajuste manual de inventario
- [ ] Reportes y gráficas
- [ ] Escaneo de códigos de barras
- [ ] Notificaciones push
- [ ] Modo offline con sincronización
- [ ] Exportación de datos (PDF, Excel)

## 📄 Licencia

Este proyecto es parte del sistema de gestión de inventario backend desarrollado con NestJS.

## 👨‍💻 Autor

Desarrollado con ❤️ usando Flutter y Material Design 3

---

**Nota**: Esta aplicación requiere conexión a internet para funcionar, ya que se conecta a una API REST backend en Render.com.
