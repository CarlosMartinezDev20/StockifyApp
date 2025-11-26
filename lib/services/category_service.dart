import '../models/models.dart';
import 'http_service.dart';

/// Servicio para gestión de categorías
class CategoryService {
  final HttpService _http = HttpService();

  /// Obtener todas las categorías
  Future<List<Category>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _http.get('/categories', queryParams: queryParams);
      final categoriesList = response['data'] as List<dynamic>;

      return categoriesList
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  /// Obtener una categoría por ID
  Future<Category> getById(String id) async {
    try {
      final response = await _http.get('/categories/$id');
      return Category.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener categoría: $e');
    }
  }

  /// Crear una nueva categoría
  Future<Category> create({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _http.post(
        '/categories',
        body: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      return Category.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  /// Actualizar una categoría
  Future<Category> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _http.patch('/categories/$id', body: data);
      return Category.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  /// Eliminar una categoría
  Future<void> delete(String id) async {
    try {
      await _http.delete('/categories/$id');
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }
}
