import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

/// Servicio HTTP base que maneja autenticación y peticiones
class HttpService {
  static const String baseUrl = 'https://inventory-backend-v2.onrender.com';
  String? _token;
  String? _cachedRole; // Caché del rol de usuario

  // Singleton pattern
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  /// Obtener token almacenado
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  /// Guardar token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  /// Eliminar token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _cachedRole = null; // Limpiar caché del rol
  }

  /// Obtener el token actual
  Future<String?> getToken() async {
    await loadToken();
    return _token;
  }

  /// Verificar si hay sesión activa
  Future<bool> hasValidToken() async {
    await loadToken();
    
    // Si no hay token, no está autenticado
    if (_token == null || _token!.isEmpty) {
      return false;
    }

    // Verificar que el token tenga el formato JWT válido
    // Un JWT tiene 3 partes separadas por puntos
    final parts = _token!.split('.');
    if (parts.length != 3) {
      await clearToken();
      return false;
    }

    // Verificar con el backend que el token sea válido
    // Usamos un endpoint simple que requiere autenticación
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products?page=1&limit=1'),
        headers: _getHeaders(),
      );
      
      // Si la respuesta es 200, el token es válido
      if (response.statusCode == 200) {
        return true;
      } else {
        // Token inválido, limpiar
        await clearToken();
        return false;
      }
    } catch (e) {
      // Si hay error de red o el token no es válido, limpiar
      await clearToken();
      return false;
    }
  }

  /// Headers con autenticación
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    await loadToken();

    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error en la petición GET');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    if (includeAuth) {
      await loadToken();
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(includeAuth: includeAuth),
      body: body != null && body.isNotEmpty ? jsonEncode(body) : jsonEncode({}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error en la petición POST');
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    await loadToken();

    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error en la petición PATCH');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    await loadToken();

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error en la petición DELETE');
    }
  }

  /// Obtener el rol del usuario desde el JWT (con caché)
  Future<String?> getUserRole() async {
    // Si ya tenemos el rol en caché, devolverlo inmediatamente
    if (_cachedRole != null) {
      return _cachedRole;
    }
    
    await loadToken();
    
    if (_token == null || _token!.isEmpty) {
      return null;
    }

    try {
      // Decodificar el JWT
      final payload = Jwt.parseJwt(_token!);
      
      // El backend guarda el rol en el campo 'role'
      _cachedRole = payload['role'] as String?;
      return _cachedRole;
    } catch (e) {
      return null;
    }
  }

  /// Verificar si el usuario actual es ADMIN
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role?.toUpperCase() == 'ADMIN';
  }
}
