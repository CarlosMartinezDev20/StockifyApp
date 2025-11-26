import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar las preferencias de la aplicación
class PreferencesService {
  static const String _themeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';

  /// Obtener el modo de tema guardado
  /// Retorna: 'light', 'dark', o 'system' (por defecto)
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  /// Guardar el modo de tema
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }

  /// Obtener si las notificaciones están habilitadas
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  /// Establecer si las notificaciones están habilitadas
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}
