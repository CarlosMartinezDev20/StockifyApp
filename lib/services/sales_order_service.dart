import '../models/models.dart';
import 'http_service.dart';

/// Servicio para gestión de órdenes de venta
class SalesOrderService {
  final HttpService _http = HttpService();

  /// Obtener todas las órdenes de venta
  Future<List<SalesOrder>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _http.get('/sales-orders', queryParams: queryParams);
      final ordersList = response['data'] as List<dynamic>;

      return ordersList
          .map((json) => SalesOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener órdenes de venta: $e');
    }
  }

  /// Obtener una orden de venta por ID
  Future<SalesOrder> getById(String id) async {
    try {
      final response = await _http.get('/sales-orders/$id');
      return SalesOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener orden de venta: $e');
    }
  }

  /// Crear una nueva orden de venta
  Future<SalesOrder> create({
    required String customerId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _http.post(
        '/sales-orders',
        body: {
          'customerId': customerId,
          'items': items,
        },
      );

      return SalesOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear orden de venta: $e');
    }
  }

  /// Confirmar una orden de venta
  Future<SalesOrder> confirm(String id) async {
    try {
      final response = await _http.post('/sales-orders/$id/confirm');
      return SalesOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al confirmar orden: $e');
    }
  }

  /// Cumplir una orden de venta (fulfill)
  Future<SalesOrder> fulfill(String id, String warehouseId) async {
    try {
      final response = await _http.post(
        '/sales-orders/$id/fulfill',
        body: {'warehouseId': warehouseId},
      );

      return SalesOrder.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al cumplir orden: $e');
    }
  }
}
