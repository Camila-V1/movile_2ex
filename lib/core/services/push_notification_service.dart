import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';

// Handler para notificaciones en background (debe estar fuera de la clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 [PUSH-BG] Background message: ${message.messageId}');
  print('   Título: ${message.notification?.title}');
  print('   Cuerpo: ${message.notification?.body}');
  print('   Data: ${message.data}');
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static String? _fcmToken;
  
  /// Inicializa el servicio de notificaciones push
  static Future<void> initialize(ApiService apiService) async {
    if (_initialized) {
      print('⚠️ [PUSH] PushNotificationService ya está inicializado');
      return;
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 [PUSH] INICIALIZANDO PUSH NOTIFICATIONS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      // 1. Inicializar Firebase
      await Firebase.initializeApp();
      print('✅ [PUSH] Firebase inicializado');
      
      // 2. Solicitar permisos
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [PUSH] Permisos de notificaciones concedidos');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ [PUSH] Permisos provisionales concedidos');
      } else {
        print('❌ [PUSH] Permisos de notificaciones denegados');
        return;
      }
      
      // 3. Configurar handler para mensajes en background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print('✅ [PUSH] Background handler configurado');
      
      // 4. Configurar notificaciones locales
      await _initializeLocalNotifications();
      print('✅ [PUSH] Notificaciones locales configuradas');
      
      // 5. Obtener token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📱 [PUSH] FCM Token obtenido:');
        print('   ${_fcmToken!.substring(0, 50)}...');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // 6. Enviar token al backend
        await _registerTokenWithBackend(apiService, _fcmToken!);
      } else {
        print('⚠️ [PUSH] No se pudo obtener el FCM token');
      }
      
      // 7. Configurar listeners de notificaciones
      _setupNotificationListeners();
      print('✅ [PUSH] Listeners configurados');
      
      // 8. Listener para refresh del token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔄 [PUSH] FCM Token actualizado');
        print('   Nuevo token: ${newToken.substring(0, 50)}...');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _fcmToken = newToken;
        _registerTokenWithBackend(apiService, newToken);
      });
      
      _initialized = true;
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ [PUSH] PushNotificationService inicializado correctamente');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ [PUSH] Error inicializando PushNotificationService');
      print('   Error: $e');
      if (kDebugMode) {
        print('   Stack trace: $stackTrace');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
  
  /// Configura las notificaciones locales (para mostrar en foreground)
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Crear canal de notificaciones de alta prioridad (Android)
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Notificaciones de órdenes, reembolsos y entregas',
      importance: Importance.high,
      playSound: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    print('✅ [PUSH] Canal de notificaciones Android creado');
  }
  
  /// Registra el token FCM en el backend
  static Future<void> _registerTokenWithBackend(ApiService apiService, String token) async {
    print('📤 [PUSH] Enviando token al backend...');
    
    try {
      final response = await apiService.post(
        '/users/register-device-token/',
        data: {
          'token': token,
          'device_type': Platform.isAndroid ? 'ANDROID' : 'IOS',
          'device_id': token.substring(0, 20), // ID único basado en token
          'device_name': Platform.isAndroid 
              ? 'Android ${Platform.operatingSystemVersion}' 
              : 'iOS ${Platform.operatingSystemVersion}',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [PUSH] Token registrado en backend exitosamente');
        print('   Response: ${response.data}');
      } else {
        print('⚠️ [PUSH] Error registrando token: ${response.statusCode}');
        print('   Response: ${response.data}');
      }
    } catch (e) {
      print('❌ [PUSH] Error enviando token al backend: $e');
    }
  }
  
  /// Configura los listeners para las notificaciones
  static void _setupNotificationListeners() {
    // Foreground: App abierta y visible
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📩 [PUSH-FG] Notificación recibida en foreground');
      print('   Message ID: ${message.messageId}');
      print('   Título: ${message.notification?.title}');
      print('   Cuerpo: ${message.notification?.body}');
      print('   Data: ${message.data}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Mostrar notificación local
      _showLocalNotification(message);
    });
    
    // Background: App en segundo plano pero no cerrada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('👆 [PUSH-BG] Notificación tocada (app en background)');
      print('   Message ID: ${message.messageId}');
      print('   Data: ${message.data}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _handleNotificationTap(message.data);
    });
    
    // Terminated: App completamente cerrada
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🚀 [PUSH-TERM] Notificación abrió la app (desde terminated)');
        print('   Message ID: ${message.messageId}');
        print('   Data: ${message.data}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _handleNotificationTap(message.data);
      }
    });
  }
  
  /// Muestra una notificación local cuando la app está en foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    print('🔔 [PUSH] Mostrando notificación local...');
    
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones Importantes',
      channelDescription: 'Notificaciones de órdenes, reembolsos y entregas',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
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
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'SmartSales365',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data['type'], // Tipo de notificación
    );
    
    print('✅ [PUSH] Notificación local mostrada');
  }
  
  /// Maneja el tap en una notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('👆 [PUSH-LOCAL] Notificación local tocada');
    print('   Payload: ${response.payload}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    // TODO: Navegar a la pantalla correspondiente según el tipo
  }
  
  /// Maneja el tap en una notificación de Firebase
  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('👆 [PUSH] Manejando tap en notificación');
    print('   Data: $data');
    
    final type = data['type'];
    // final screen = data['screen']; // TODO: Usar cuando se implemente navegación
    
    // TODO: Implementar navegación según el tipo
    switch (type) {
      case 'ORDER_DELIVERED':
        // Navegar a pantalla de detalle de orden
        final orderId = data['order_id'];
        print('📦 [PUSH] Debería navegar a orden $orderId');
        // Nota: La navegación real requiere acceso al contexto de navegación
        // Se implementará cuando se integre con GoRouter
        break;
        
      case 'RETURN_APPROVED':
        // Navegar a pantalla de devoluciones
        print('💰 [PUSH] Debería navegar a devoluciones');
        break;
        
      case 'RETURN_REJECTED':
        // Navegar a pantalla de devoluciones
        print('❌ [PUSH] Debería navegar a devoluciones');
        break;
        
      default:
        print('ℹ️ [PUSH] Tipo de notificación desconocido: $type');
    }
  }
  
  /// Desregistra el token (útil al hacer logout)
  static Future<void> unregisterToken(ApiService apiService) async {
    print('🔄 [PUSH] Desregistrando tokens...');
    
    try {
      await apiService.post('/users/unregister-all-tokens/');
      print('✅ [PUSH] Tokens desregistrados del backend');
    } catch (e) {
      print('❌ [PUSH] Error desregistrando tokens: $e');
    }
  }
  
  /// Obtiene el token FCM actual
  static String? get fcmToken => _fcmToken;
  
  /// Verifica si el servicio está inicializado
  static bool get isInitialized => _initialized;
}
