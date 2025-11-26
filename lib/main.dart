import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicio de notificaciones
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Error al inicializar notificaciones: $e');
  }
  
  // Verificar si las notificaciones están habilitadas antes de iniciar monitoreo
  try {
    final prefsService = PreferencesService();
    final notificationsEnabled = await prefsService.getNotificationsEnabled();
    
    if (notificationsEnabled) {
      StockMonitorService().startMonitoring().catchError((e) {
        debugPrint('Error al iniciar monitoreo: $e');
      });
    }
  } catch (e) {
    debugPrint('Error al verificar preferencias: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Paleta de tonalidades verdes como fallback
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Usar colores dinámicos del sistema
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback a verde esmeralda
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Inventory App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
          ),
          themeMode: ThemeMode.system,
          home: const AuthCheck(),
        );
      },
    );
  }
}

// Verificar si el usuario está autenticado
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final HttpService _httpService = HttpService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await _httpService.hasValidToken();
    setState(() {
      _isAuthenticated = hasToken;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated ? const DashboardScreen() : const LoginScreen();
  }
}
