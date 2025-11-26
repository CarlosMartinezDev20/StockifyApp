import '../models/models.dart';
import 'http_service.dart';

/// Servicio para gestión de clientes
class CustomerService {
  final HttpService _http = HttpService();

  /// Obtener todos los clientes
  Future<List<Customer>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _http.get('/customers', queryParams: queryParams);
      final customersList = response['data'] as List<dynamic>;

      return customersList
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  /// Obtener un cliente por ID
  Future<Customer> getById(String id) async {
    try {
      final response = await _http.get('/customers/$id');
      return Customer.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener cliente: $e');
    }
  }

  /// Crear un nuevo cliente
  Future<Customer> create({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await _http.post(
        '/customers',
        body: {
          'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
        },
      );

      return Customer.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  /// Actualizar un cliente
  Future<Customer> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _http.patch('/customers/$id', body: data);
      return Customer.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  /// Eliminar un cliente
  Future<void> delete(String id) async {
    try {
      await _http.delete('/customers/$id');
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }
}
