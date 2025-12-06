import 'dart:async';
import 'package:flutter/foundation.dart';
import 'product_service.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para monitorear el stock y enviar notificaciones
class StockMonitorService {
  static final StockMonitorService _instance = StockMonitorService._internal();
  factory StockMonitorService() => _instance;
  StockMonitorService._internal();

  final ProductService _productService = ProductService();
  final NotificationService _notificationService = NotificationService();
  Timer? _monitorTimer;
  Set<String> _notifiedProducts = {}; // IDs de productos ya notificados

  /// Iniciar monitoreo periódico (cada 2 minutos)
  Future<void> startMonitoring() async {
    try {
      // Cargar productos ya notificados
      await _loadNotifiedProducts();
      
      // Verificar inmediatamente al iniciar (sin esperar)
      _checkStockLevels().catchError((e) {
        debugPrint('Error en verificación inicial de stock: $e');
      });
      
      // Luego verificar cada 2 minutos
      _monitorTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        _checkStockLevels();
      });
    } catch (e) {
      debugPrint('Error al iniciar monitoreo: $e');
    }
  }

  /// Detener monitoreo
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Verificar niveles de stock y notificar si es necesario
  Future<void> _checkStockLevels() async {
    try {
      final products = await _productService.getAll();
      
      // Filtrar productos con stock bajo
      final lowStockProducts = products.where((p) {
        final currentStock = p.stockTotal ?? 0;
        final minimumStock = p.minStock ?? 0;
        
        // Stock está bajo SI el stock actual es menor que el mínimo
        return currentStock < minimumStock && minimumStock > 0;
      }).toList();

      // Enviar notificaciones solo para productos que no hemos notificado
      for (var product in lowStockProducts) {
        if (!_notifiedProducts.contains(product.id)) {
          await _notificationService.showLowStockAlert(
            productName: product.name,
            currentStock: (product.stockTotal ?? 0).toInt(),
            minimumStock: (product.minStock ?? 0).toInt(),
          );
          
          // Marcar como notificado
          _notifiedProducts.add(product.id);
          _saveNotifiedProducts();
        }
      }

      // Limpiar productos que ya no tienen stock bajo
      _notifiedProducts.removeWhere((id) {
        try {
          final product = products.firstWhere((p) => p.id == id);
          final currentStock = product.stockTotal ?? 0;
          final minimumStock = product.minStock ?? 0;
          return currentStock >= minimumStock;
        } catch (e) {
          // Si el producto ya no existe, removerlo de notificados
          return true;
        }
      });
      _saveNotifiedProducts();
      
    } catch (e) {
      debugPrint('Error al verificar stock: $e');
    }
  }

  /// Guardar IDs de productos notificados
  Future<void> _saveNotifiedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notified_products',
      _notifiedProducts.toList(),
    );
  }

  /// Cargar IDs de productos notificados
  Future<void> _loadNotifiedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('notified_products') ?? [];
    _notifiedProducts = saved.toSet();
  }

  /// Reiniciar notificaciones (útil para testing)
  Future<void> resetNotifications() async {
    _notifiedProducts.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notified_products');
  }

  /// Verificar stock manualmente (llamar al hacer pull-to-refresh)
  Future<void> checkNow() async {
    await _checkStockLevels();
  }
}
