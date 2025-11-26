import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'http_service.dart';
import 'stock_monitor_service.dart';

/// Servicio para gestión de inventario
class InventoryService {
  final HttpService _http = HttpService();

  /// Obtener niveles de inventario con filtros
  Future<List<InventoryLevel>> getLevels({
    String? productId,
    String? warehouseId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (productId != null) queryParams['productId'] = productId;
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;

      final response = await _http.get(
        '/inventory/levels',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      final inventoryList = response['data'] as List<dynamic>;
      return inventoryList
          .map((json) => InventoryLevel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener inventario: $e');
    }
  }

  /// Ajustar inventario
  Future<InventoryLevel> adjust({
    required String productId,
    required String warehouseId,
    required double quantity,
    String? reason,
  }) async {
    try {
      final response = await _http.post(
        '/inventory/adjust',
        body: {
          'productId': productId,
          'warehouseId': warehouseId,
          'quantity': quantity,
          if (reason != null) 'reason': reason,
        },
      );

      final level = InventoryLevel.fromJson(response['data'] as Map<String, dynamic>);
      
      // Verificar stock inmediatamente después del ajuste
      StockMonitorService().checkNow().catchError((e) {
        debugPrint('Error al verificar stock: $e');
      });
      
      return level;
    } catch (e) {
      throw Exception('Error al ajustar inventario: $e');
    }
  }

  /// Obtener movimientos de stock
  Future<List<StockMovement>> getMovements({
    String? productId,
    String? warehouseId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (productId != null) 'productId': productId,
        if (warehouseId != null) 'warehouseId': warehouseId,
      };

      final response = await _http.get('/stock-movements', queryParams: queryParams);
      final movementsList = response['data'] as List<dynamic>;

      return movementsList
          .map((json) => StockMovement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos: $e');
    }
  }
}
