import '../models/models.dart';
import 'http_service.dart';

/// Servicio para gestión de proveedores
class SupplierService {
  final HttpService _http = HttpService();

  /// Obtener todos los proveedores
  Future<List<Supplier>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _http.get('/suppliers', queryParams: queryParams);
      final suppliersList = response['data'] as List<dynamic>;

      return suppliersList
          .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener proveedores: $e');
    }
  }

  /// Obtener un proveedor por ID
  Future<Supplier> getById(String id) async {
    try {
      final response = await _http.get('/suppliers/$id');
      return Supplier.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener proveedor: $e');
    }
  }

  /// Crear un nuevo proveedor
  Future<Supplier> create({
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await _http.post(
        '/suppliers',
        body: {
          'name': name,
          if (contactName != null) 'contactName': contactName,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
        },
      );

      return Supplier.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear proveedor: $e');
    }
  }

  /// Actualizar un proveedor
  Future<Supplier> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _http.patch('/suppliers/$id', body: data);
      return Supplier.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al actualizar proveedor: $e');
    }
  }

  /// Eliminar un proveedor
  Future<void> delete(String id) async {
    try {
      await _http.delete('/suppliers/$id');
    } catch (e) {
      throw Exception('Error al eliminar proveedor: $e');
    }
  }
}
