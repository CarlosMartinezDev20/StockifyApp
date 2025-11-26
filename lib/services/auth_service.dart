import '../models/models.dart';
import 'http_service.dart';

/// Servicio de autenticación
class AuthService {
  final HttpService _http = HttpService();

  /// Login con email y contraseña
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _http.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        includeAuth: false,
      );

      // El backend devuelve directamente { accessToken, user } sin envolver en data
      if (response['accessToken'] != null && response['user'] != null) {
        final accessToken = response['accessToken'] as String;
        final userData = response['user'] as Map<String, dynamic>;

        await _http.saveToken(accessToken);

        return {
          'success': true,
          'user': User.fromJson(userData),
        };
      }

      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      throw Exception('Error de autenticación: $e');
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _http.clearToken();
  }

  /// Verificar si hay sesión activa
  Future<bool> isAuthenticated() async {
    return await _http.hasValidToken();
  }
}
