import '../models/models.dart';
import 'http_service.dart';

/// Servicio para gestión de almacenes
class WarehouseService {
  final HttpService _http = HttpService();

  /// Obtener todos los almacenes
  Future<List<Warehouse>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _http.get('/warehouses', queryParams: queryParams);
      final warehousesList = response['data'] as List<dynamic>;

      return warehousesList
          .map((json) => Warehouse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener almacenes: $e');
    }
  }

  /// Obtener un almacén por ID
  Future<Warehouse> getById(String id) async {
    try {
      final response = await _http.get('/warehouses/$id');
      return Warehouse.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener almacén: $e');
    }
  }

  /// Crear un nuevo almacén
  Future<Warehouse> create({
    required String name,
    String? location,
  }) async {
    try {
      final response = await _http.post(
        '/warehouses',
        body: {
          'name': name,
          if (location != null) 'location': location,
        },
      );

      return Warehouse.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear almacén: $e');
    }
  }

  /// Actualizar un almacén
  Future<Warehouse> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _http.patch('/warehouses/$id', body: data);
      return Warehouse.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al actualizar almacén: $e');
    }
  }

  /// Eliminar un almacén
  Future<void> delete(String id) async {
    try {
      await _http.delete('/warehouses/$id');
    } catch (e) {
      throw Exception('Error al eliminar almacén: $e');
    }
  }
}
