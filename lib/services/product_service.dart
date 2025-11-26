import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'http_service.dart';
import 'stock_monitor_service.dart';

/// Servicio para gestión de productos
class ProductService {
  final HttpService _http = HttpService();

  /// Obtener todos los productos con filtros y paginación
  Future<List<Product>> getAll({
    int page = 1,
    int limit = 50,
    String? categoryId,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null) 'name': search,
      };

      final response = await _http.get('/products', queryParams: queryParams);
      final productsList = response['data'] as List<dynamic>;

      return productsList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  /// Obtener un producto por ID
  Future<Product> getById(String id) async {
    try {
      final response = await _http.get('/products/$id');
      return Product.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  /// Crear un nuevo producto
  Future<Product> create({
    required String sku,
    required String name,
    required String categoryId,
    String? description,
    String? unit,
    double? minStock,
    String? barcode,
  }) async {
    try {
      final response = await _http.post(
        '/products',
        body: {
          'sku': sku,
          'name': name,
          'categoryId': categoryId,
          if (description != null) 'description': description,
          if (unit != null) 'unit': unit,
          if (minStock != null) 'minStock': minStock,
          if (barcode != null) 'barcode': barcode,
        },
      );

      return Product.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  /// Actualizar un producto
  Future<Product> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _http.patch('/products/$id', body: data);
      final product = Product.fromJson(response['data'] as Map<String, dynamic>);
      
      // Verificar stock inmediatamente después de actualizar
      StockMonitorService().checkNow().catchError((e) {
        debugPrint('Error al verificar stock: $e');
      });
      
      return product;
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Eliminar un producto
  Future<void> delete(String id) async {
    try {
      await _http.delete('/products/$id');
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }
}
