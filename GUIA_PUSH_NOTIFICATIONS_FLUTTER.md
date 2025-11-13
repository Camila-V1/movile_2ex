# 📱 Guía Completa: Notificaciones Push con Firebase (Flutter + Django Backend)

## 🎯 Objetivo

Configurar notificaciones push para que los usuarios reciban alertas cuando:
1. ✅ **Su orden es entregada** (`ORDER_DELIVERED`)
2. 💰 **Su reembolso es aprobado** (`RETURN_APPROVED`)
3. ❌ **Su reembolso es rechazado** (`RETURN_REJECTED`)

---

## 📋 Requisitos Previos

- [ ] Cuenta de Google (para Firebase Console)
- [ ] Proyecto Flutter funcionando
- [ ] Backend Django funcionando
- [ ] 15 minutos de tiempo

---

## PARTE 1: Configurar Firebase Console (5 minutos)

### Paso 1.1: Crear Proyecto en Firebase

1. Ve a **Firebase Console**: https://console.firebase.google.com/
2. Click en **"Agregar proyecto"** o **"Add project"**
3. Nombre del proyecto: `smartsales365-ecommerce` (o el que prefieras)
4. **Deshabilita Google Analytics** (no lo necesitamos para push notifications)
5. Click en **"Crear proyecto"**
6. Espera 30 segundos → Click en **"Continuar"**

### Paso 1.2: Agregar App Android a Firebase

1. En el panel principal, click en el ícono **Android** 
2. Completa los datos:
   - **Nombre del paquete Android**: `com.example.movile_2ex` 
     *(Verifica este nombre en `android/app/build.gradle` → busca `applicationId`)*
   - **Apodo de la app**: `SmartSales365 Mobile`
   - **SHA-1**: Dejar en blanco por ahora (opcional)
3. Click en **"Registrar app"**
4. **Descarga** el archivo `google-services.json`
5. **IMPORTANTE**: Guarda este archivo, lo usarás en el Paso 2.3

### Paso 1.3: (Opcional) Agregar App iOS

Si vas a compilar para iOS:
1. Click en el ícono **iOS** 
2. **Bundle ID**: `com.example.movile2ex` (verifica en `ios/Runner.xcodeproj`)
3. Descarga `GoogleService-Info.plist`
4. Sigue los pasos de Firebase para iOS

### Paso 1.4: Obtener Credenciales del Backend (Service Account)

1. En Firebase Console, click en **⚙️ (Settings)** arriba a la izquierda
2. Click en **"Project settings"** → **"Service accounts"**
3. Click en **"Generate new private key"**
4. Click en **"Generate key"** (se descarga un archivo JSON)
5. **RENOMBRA** el archivo descargado a `firebase_credentials.json`
6. **IMPORTANTE**: Este archivo es CONFIDENCIAL, nunca lo subas a Git

---

## PARTE 2: Configurar Flutter App (10 minutos)

### Paso 2.1: Agregar Dependencias

Abre `pubspec.yaml` y agrega:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # ... tus dependencias actuales ...
  
  # 📱 Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

Luego ejecuta:
```bash
flutter pub get
```

### Paso 2.2: Configurar Android

#### 2.2.1: Copiar `google-services.json`

Copia el archivo `google-services.json` (descargado en Paso 1.2) a:
```
android/app/google-services.json
```

#### 2.2.2: Actualizar `android/build.gradle`

Abre `android/build.gradle` y agrega el plugin de Google Services:

```gradle
buildscript {
    dependencies {
        // ... otras dependencias ...
        classpath 'com.google.gms:google-services:4.4.0'  // ⬅️ AGREGAR ESTA LÍNEA
    }
}
```

#### 2.2.3: Actualizar `android/app/build.gradle`

Abre `android/app/build.gradle` y **AL FINAL DEL ARCHIVO** agrega:

```gradle
apply plugin: 'com.google.gms.google-services'  // ⬅️ AGREGAR AL FINAL
```

Verifica también que `minSdkVersion` sea al menos **21**:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // ⬅️ Debe ser 21 o superior
        targetSdkVersion flutter.targetSdkVersion
        // ...
    }
}
```

#### 2.2.4: Actualizar `AndroidManifest.xml`

Abre `android/app/src/main/AndroidManifest.xml` y agrega dentro de `<application>`:

```xml
<application>
    <!-- ... código existente ... -->
    
    <!-- 📱 Configuración de Firebase Messaging -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="high_importance_channel" />
    
    <!-- Icono para notificaciones (usa el icono de tu app) -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@mipmap/ic_launcher" />
</application>
```

### Paso 2.3: Crear Servicio de Notificaciones en Flutter

Crea el archivo `lib/core/services/push_notification_service.dart`:

```dart
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
  print('📩 Background message: ${message.messageId}');
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
      print('⚠️ PushNotificationService ya está inicializado');
      return;
    }
    
    try {
      // 1. Inicializar Firebase
      await Firebase.initializeApp();
      print('✅ Firebase inicializado');
      
      // 2. Solicitar permisos
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificaciones concedidos');
      } else {
        print('⚠️ Permisos de notificaciones denegados');
        return;
      }
      
      // 3. Configurar handler para mensajes en background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // 4. Configurar notificaciones locales
      await _initializeLocalNotifications();
      
      // 5. Obtener token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');
        
        // 6. Enviar token al backend
        await _registerTokenWithBackend(apiService, _fcmToken!);
      }
      
      // 7. Configurar listeners de notificaciones
      _setupNotificationListeners();
      
      // 8. Listener para refresh del token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token actualizado: $newToken');
        _registerTokenWithBackend(apiService, newToken);
      });
      
      _initialized = true;
      print('✅ PushNotificationService inicializado correctamente');
      
    } catch (e) {
      print('❌ Error inicializando PushNotificationService: $e');
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
  }
  
  /// Registra el token FCM en el backend
  static Future<void> _registerTokenWithBackend(ApiService apiService, String token) async {
    try {
      final response = await apiService.post(
        '/api/users/register-device-token/',
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
        print('✅ Token registrado en backend exitosamente');
      } else {
        print('⚠️ Error registrando token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error enviando token al backend: $e');
    }
  }
  
  /// Configura los listeners para las notificaciones
  static void _setupNotificationListeners() {
    // Foreground: App abierta y visible
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Notificación recibida en foreground');
      print('Título: ${message.notification?.title}');
      print('Cuerpo: ${message.notification?.body}');
      print('Data: ${message.data}');
      
      // Mostrar notificación local
      _showLocalNotification(message);
    });
    
    // Background: App en segundo plano pero no cerrada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Notificación tocada (app en background)');
      _handleNotificationTap(message.data);
    });
    
    // Terminated: App completamente cerrada
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📩 Notificación abrió la app (desde terminated)');
        _handleNotificationTap(message.data);
      }
    });
  }
  
  /// Muestra una notificación local cuando la app está en foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones Importantes',
      channelDescription: 'Notificaciones de órdenes, reembolsos y entregas',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
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
  }
  
  /// Maneja el tap en una notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notificación local tocada: ${response.payload}');
    // TODO: Navegar a la pantalla correspondiente según el tipo
  }
  
  /// Maneja el tap en una notificación de Firebase
  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('👆 Notificación de Firebase tocada');
    print('Data: $data');
    
    final type = data['type'];
    final screen = data['screen'];
    
    // TODO: Implementar navegación según el tipo
    switch (type) {
      case 'ORDER_DELIVERED':
        // Navegar a pantalla de detalle de orden
        final orderId = data['order_id'];
        print('📦 Navegar a orden $orderId');
        // context.push('/orders/$orderId');
        break;
        
      case 'RETURN_APPROVED':
        // Navegar a pantalla de devoluciones
        print('💰 Navegar a devoluciones');
        // context.push('/returns');
        break;
        
      case 'RETURN_REJECTED':
        // Navegar a pantalla de devoluciones
        print('❌ Navegar a devoluciones');
        // context.push('/returns');
        break;
        
      default:
        print('ℹ️ Tipo de notificación desconocido: $type');
    }
  }
  
  /// Desregistra el token (útil al hacer logout)
  static Future<void> unregisterToken(ApiService apiService) async {
    try {
      await apiService.post('/api/users/unregister-all-tokens/');
      print('✅ Tokens desregistrados del backend');
    } catch (e) {
      print('❌ Error desregistrando tokens: $e');
    }
  }
  
  /// Obtiene el token FCM actual
  static String? get fcmToken => _fcmToken;
}
```

### Paso 2.4: Inicializar en `main.dart`

Abre `lib/main.dart` y modifica:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';
import 'core/api/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializePushNotifications();
  }
  
  Future<void> _initializePushNotifications() async {
    // Esperar a que el usuario haga login y tengas el ApiService disponible
    // Por ahora, lo inicializamos sin token (se actualizará después del login)
    final apiService = ApiService(); // Tu instancia de ApiService
    await PushNotificationService.initialize(apiService);
  }
  
  @override
  Widget build(BuildContext context) {
    // ... tu código existente ...
  }
}
```

### Paso 2.5: Registrar Token Después del Login

En tu pantalla de login (después de login exitoso), agrega:

```dart
// Después de login exitoso
final apiService = ref.read(apiServiceProvider); // O como obtengas tu ApiService
await PushNotificationService.initialize(apiService);
```

---

## PARTE 3: Configurar Backend Django (Ya está hecho por mí ✅)

El backend YA ESTÁ CONFIGURADO con:

✅ Modelos `DeviceToken` y `NotificationLog` creados  
✅ Endpoint `POST /api/users/register-device-token/` funcional  
✅ Servicio `PushNotificationService` creado  
✅ Notificaciones integradas en:
  - `deliveries/views.py` → `approve()` y `reject()` para reembolsos
  - `deliveries/views.py` → `update_status()` cuando orden es `DELIVERED`

**Lo único que falta:** Pegar credenciales de Firebase en `firebase_credentials.json`

---

## PARTE 4: Conectar Backend con Firebase

### Paso 4.1: Copiar Credenciales de Firebase

1. Recuerda el archivo JSON que descargaste en **Paso 1.4**
2. Abre `backend_2ex/firebase_credentials.json`
3. **REEMPLAZA TODO EL CONTENIDO** con el JSON descargado de Firebase
4. Guarda el archivo

### Paso 4.2: Instalar Dependencias del Backend

Ejecuta en tu terminal (en la carpeta `backend_2ex`):

```bash
pip install -r requirements.txt
```

Esto instalará:
- `fcm-django==2.0.0`
- `firebase-admin>=6.5.0`

### Paso 4.3: Aplicar Migraciones

```bash
python manage.py makemigrations
python manage.py migrate
```

Esto creará las tablas:
- `users_devicetoken` - Para almacenar tokens FCM
- `users_notificationlog` - Para logs de notificaciones enviadas

### Paso 4.4: Verificar Inicialización de Firebase

Reinicia el servidor Django:

```bash
python manage.py runserver
```

Deberías ver en los logs:
```
✅ Firebase Admin SDK inicializado correctamente
📱 Notificaciones push ACTIVAS para proyecto: smartsales365-ecommerce
```

Si ves esto, **¡FUNCIONA!** 🎉

---

## PARTE 5: Probar las Notificaciones

### Prueba 1: Registrar Token FCM

1. Abre la app Flutter en tu dispositivo/emulador
2. Haz login con un usuario
3. Verifica en los logs de Flutter:
   ```
   📱 FCM Token: ey...
   ✅ Token registrado en backend exitosamente
   ```
4. Verifica en el backend Django Admin:
   - Ve a http://localhost:8000/admin/
   - Busca **"Tokens de Dispositivos"**
   - Deberías ver tu dispositivo registrado

### Prueba 2: Notificación de Orden Entregada

1. Crea una orden desde Flutter
2. En Django Admin o Postman, cambia el estado de la orden a `DELIVERED`
3. **Deberías recibir la notificación en tu móvil:**
   - 🎉 "¡Tu pedido ha llegado!"
   - "Tu orden #123 ha sido entregada exitosamente"

### Prueba 3: Notificación de Reembolso Aprobado

1. Solicita una devolución desde Flutter
2. En Django Admin, aprueba la devolución
3. **Deberías recibir:**
   - ✅ "Reembolso Aprobado"
   - "Tu solicitud de devolución ha sido aprobada"

### Prueba 4: Enviar Notificación Manualmente (Testing)

Usa Postman o Django Shell para probar:

```python
# En Django Shell (python manage.py shell)
from users.models import CustomUser
from users.push_notification_service import PushNotificationService

user = CustomUser.objects.get(username='tu_usuario')

result = PushNotificationService.send_notification(
    user=user,
    title='🎉 Notificación de Prueba',
    body='Si ves esto, ¡las notificaciones funcionan!',
    notification_type='TEST',
    data={'message': 'Hello from Django'}
)

print(result)
# {'success': True, 'sent_count': 1, 'failed_count': 0, 'errors': []}
```

---

## 🐛 Troubleshooting

### Problema 1: "Firebase no está inicializado"

**Síntoma**: En logs de Django ves: `⚠️ Firebase no está inicializado`

**Solución**:
1. Verifica que `firebase_credentials.json` existe
2. Verifica que NO contiene valores placeholder (`TU-PROJECT-ID-AQUI`)
3. Reinicia el servidor Django

### Problema 2: "Token inválido" o "UnregisteredError"

**Síntoma**: Notificaciones no llegan, en logs del backend ves error de token inválido

**Solución**:
1. Desinstala y reinstala la app Flutter
2. El token cambia al reinstalar
3. Haz login de nuevo para registrar el nuevo token

### Problema 3: Notificaciones no aparecen en Foreground

**Síntoma**: Notificaciones solo aparecen cuando la app está cerrada

**Solución**:
1. Verifica que `_showLocalNotification()` se está llamando
2. Verifica permisos de notificaciones en Android Settings
3. Agrega logs en `FirebaseMessaging.onMessage` para debug

### Problema 4: Error en `google-services.json`

**Síntoma**: Error al compilar: `google-services.json not found`

**Solución**:
1. Verifica que copiaste `google-services.json` a `android/app/`
2. Verifica que el `package_name` en el JSON coincide con tu `applicationId` en `build.gradle`
3. Limpia y reconstruye: `flutter clean && flutter pub get`

---

## 📊 Verificación Final

### Checklist Backend ✅

- [ ] `requirements.txt` contiene `fcm-django` y `firebase-admin`
- [ ] `firebase_credentials.json` tiene credenciales reales (no placeholder)
- [ ] Migraciones aplicadas (`DeviceToken` y `NotificationLog` creados)
- [ ] Servidor Django muestra "✅ Firebase inicializado" en logs
- [ ] Endpoint `/api/users/register-device-token/` responde 200

### Checklist Flutter ✅

- [ ] `pubspec.yaml` contiene `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- [ ] `google-services.json` copiado a `android/app/`
- [ ] `android/build.gradle` tiene plugin `google-services`
- [ ] `android/app/build.gradle` aplica plugin `com.google.gms.google-services`
- [ ] `main.dart` inicializa Firebase
- [ ] `PushNotificationService.initialize()` se llama después del login
- [ ] Logs muestran "📱 FCM Token:" y "✅ Token registrado"

### Checklist Funcionalidad ✅

- [ ] Usuario puede hacer login y recibir token FCM
- [ ] Token se registra en backend correctamente
- [ ] Notificación de orden entregada llega al móvil
- [ ] Notificación de reembolso aprobado llega al móvil
- [ ] Notificaciones aparecen tanto en foreground como background
- [ ] Tap en notificación abre la app (navegación pendiente)

---

## 🚀 Despliegue a Producción

### Backend (Render)

1. Sube `firebase_credentials.json` al servidor:
   ```bash
   # Opción 1: Usar Environment Variable (recomendado)
   cat firebase_credentials.json | base64
   # Copia el output y agrégalo como variable FIREBASE_CREDENTIALS_BASE64 en Render
   ```

2. Modifica `users/apps.py` para leer de variable de entorno:
   ```python
   import base64
   cred_json = os.getenv('FIREBASE_CREDENTIALS_BASE64')
   if cred_json:
       cred_data = json.loads(base64.b64decode(cred_json))
       cred = credentials.Certificate(cred_data)
   ```

3. Redeploy en Render

### Flutter (Play Store / App Store)

1. **Android**:
   - Asegúrate de firmar la APK con tu keystore
   - El `google-services.json` va incluido en el APK

2. **iOS**:
   - Agrega `GoogleService-Info.plist` a Xcode
   - Configura capabilities: Push Notifications, Background Modes

---

## 📚 Recursos Adicionales

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [django-fcm Documentation](https://github.com/FCM-django/fcm-django)

---

## ✅ Conclusión

Ahora tienes un sistema completo de notificaciones push que:
- ✅ Registra tokens FCM automáticamente al hacer login
- ✅ Envía notificaciones cuando una orden es entregada
- ✅ Envía notificaciones cuando un reembolso es aprobado/rechazado
- ✅ Funciona tanto en foreground como background
- ✅ Logs completos para debugging
- ✅ Maneja errores y tokens inválidos automáticamente

**¡Felicidades! 🎉 Las notificaciones push están funcionando.**
