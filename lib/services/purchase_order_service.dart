import '../models/models.dart';
import 'http_service.dart';

/// Servicio para gestión de órdenes de compra
class PurchaseOrderService {
  final HttpService _http = HttpService();

  /// Obtener todas las órdenes de compra
  Future<List<PurchaseOrder>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _http.get('/purchase-orders', queryParams: queryParams);
      final ordersList = response['data'] as List<dynamic>;

      return ordersList
          .map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener órdenes de compra: $e');
    }
  }

  /// Obtener una orden de compra por ID
  Future<PurchaseOrder> getById(String id) async {
    try {
      final response = await _http.get('/purchase-orders/$id');
      return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener orden de compra: $e');
    }
  }

  /// Crear una nueva orden de compra
  Future<PurchaseOrder> create({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    DateTime? expectedAt,
  }) async {
    try {
      final response = await _http.post(
        '/purchase-orders',
        body: {
          'supplierId': supplierId,
          'items': items,
          if (expectedAt != null) 'expectedAt': expectedAt.toIso8601String(),
        },
      );

      return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear orden de compra: $e');
    }
  }

  /// Confirmar una orden de compra (cambiar de DRAFT a ORDERED)
  Future<PurchaseOrder> confirm(String id) async {
    try {
      final response = await _http.post('/purchase-orders/$id/order');
      return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al confirmar orden de compra: $e');
    }
  }

  /// Recibir una orden de compra
  Future<PurchaseOrder> receive(String id, {
    required String warehouseId,
    required Map<String, double> receivedQuantities,
  }) async {
    try {
      final response = await _http.post(
        '/purchase-orders/$id/receive',
        body: {
          'warehouseId': warehouseId,
          'receivedQuantities': receivedQuantities,
        },
      );
      return PurchaseOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al recibir orden de compra: $e');
    }
  }
}
