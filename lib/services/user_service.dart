import '../models/models.dart';
import 'http_service.dart';

/// Servicio para gestión de usuarios
class UserService {
  final HttpService _http = HttpService();

  /// Obtener todos los usuarios (requiere autenticación)
  Future<List<User>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _http.get('/users', queryParams: queryParams);
      final usersList = response['data'] as List<dynamic>;

      return usersList
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Obtener un usuario por ID
  Future<User> getById(String id) async {
    try {
      final response = await _http.get('/users/$id');
      return User.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Obtener el perfil del usuario actual desde el JWT
  Future<User?> getCurrentUser() async {
    try {
      final response = await _http.get('/users/profile');
      return User.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  /// Verificar si el usuario actual es ADMIN
  Future<bool> isCurrentUserAdmin() async {
    return await _http.isAdmin();
  }

  /// Crear un nuevo usuario (solo ADMIN)
  Future<User> create({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await _http.post(
        '/users',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
        },
      );

      return User.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// Actualizar un usuario (solo ADMIN)
  Future<User> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _http.patch('/users/$id', body: data);
      return User.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// Eliminar un usuario (soft delete, solo ADMIN)
  Future<void> delete(String id) async {
    try {
      await _http.delete('/users/$id');
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  /// Cambiar contraseña del usuario actual
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _http.patch(
        '/users/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  /// Actualizar perfil del usuario actual
  Future<User> updateProfile({
    required String fullName,
    required String email,
  }) async {
    try {
      final response = await _http.patch(
        '/users/profile',
        body: {
          'fullName': fullName,
          'email': email,
        },
      );
      return User.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Obtener el perfil completo del usuario actual
  Future<User> getProfile() async {
    try {
      final response = await _http.get('/users/profile');
      return User.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }
}
