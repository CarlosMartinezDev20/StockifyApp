import 'package:flutter/material.dart';

/// SnackBar animado con mejor diseño y feedback visual
class AnimatedSnackBar {
  /// Muestra un SnackBar de éxito con animación
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
    );
  }

  /// Muestra un SnackBar de error con animación
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.error,
      backgroundColor: Colors.red,
    );
  }

  /// Muestra un SnackBar de información con animación
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.info,
      backgroundColor: Colors.blue,
    );
  }

  /// Muestra un SnackBar de advertencia con animación
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.warning,
      backgroundColor: Colors.orange,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
        elevation: 6,
      ),
    );
  }
}

/// Widget de diálogo de confirmación animado
class AnimatedConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final VoidCallback? onConfirm;

  const AnimatedConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
    this.icon,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AlertDialog(
            icon: icon != null
                ? Icon(
                    icon,
                    size: 48,
                    color: confirmColor ?? Theme.of(context).colorScheme.error,
                  )
                : null,
            title: Text(title),
            content: Text(
              message,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: confirmColor ?? Theme.of(context).colorScheme.error,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Muestra el diálogo y retorna el resultado
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    IconData? icon,
    VoidCallback? onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AnimatedConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }
}
