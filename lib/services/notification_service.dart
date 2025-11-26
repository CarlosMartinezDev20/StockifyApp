import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar notificaciones locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuración para Windows
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solicitar permisos en Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Manejar cuando el usuario toca una notificación
  void _onNotificationTap(NotificationResponse response) {
    // Aquí puedes navegar a una pantalla específica según el payload
    if (kDebugMode) {
      print('Notificación tocada: ${response.payload}');
    }
  }

  /// Mostrar notificación simple
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'inventory_channel',
      'Inventory Notifications',
      channelDescription: 'Notificaciones del sistema de inventario',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Notificación de stock bajo
  Future<void> showLowStockAlert({
    required String productName,
    required int currentStock,
    required int minimumStock,
  }) async {
    await showNotification(
      id: currentStock.hashCode,
      title: '⚠️ Stock Bajo',
      body: '$productName tiene solo $currentStock unidades (mínimo: $minimumStock)',
      payload: 'low_stock:$productName',
    );
  }

  /// Notificación de orden pendiente
  Future<void> showPendingOrderAlert({
    required String orderId,
    required String orderType,
  }) async {
    await showNotification(
      id: orderId.hashCode,
      title: '📦 Orden Pendiente',
      body: 'Tienes una $orderType pendiente de procesar',
      payload: 'pending_order:$orderId',
    );
  }

  /// Notificación de nueva orden
  Future<void> showNewOrderAlert({
    required String orderId,
    required String orderType,
    required String customer,
  }) async {
    await showNotification(
      id: orderId.hashCode,
      title: '🆕 Nueva Orden',
      body: 'Nueva $orderType de $customer',
      payload: 'new_order:$orderId',
    );
  }

  /// Cancelar notificación específica
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
