import 'package:flutter/material.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final PreferencesService _prefsService = PreferencesService();
  String _selectedTheme = 'system';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final theme = await _prefsService.getThemeMode();
    setState(() {
      _selectedTheme = theme;
      _isLoading = false;
    });
  }

  Future<void> _saveThemePreference(String theme) async {
    setState(() => _selectedTheme = theme);
    await _prefsService.setThemeMode(theme);
    
    if (mounted) {
      AnimatedSnackBar.showSuccess(
        context,
        'Tema actualizado. Reinicia la app para aplicar cambios.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator.fullScreen(message: 'Cargando...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Selecciona el tema de la aplicacion',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'system',
                  groupValue: _selectedTheme,
                  onChanged: (value) => _saveThemePreference(value!),
                  title: const Text('Sistema'),
                  subtitle: const Text('Usar configuracion del sistema'),
                  secondary: const Icon(Icons.settings_suggest),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'light',
                  groupValue: _selectedTheme,
                  onChanged: (value) => _saveThemePreference(value!),
                  title: const Text('Claro'),
                  subtitle: const Text('Tema claro'),
                  secondary: const Icon(Icons.light_mode),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'dark',
                  groupValue: _selectedTheme,
                  onChanged: (value) => _saveThemePreference(value!),
                  title: const Text('Oscuro'),
                  subtitle: const Text('Tema oscuro'),
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Es necesario reiniciar la aplicacion para que los cambios tomen efecto.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
