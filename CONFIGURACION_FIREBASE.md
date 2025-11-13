# 🔔 Configuración de Firebase para Push Notifications

## ✅ Lo que ya está implementado

El sistema de notificaciones push está **completamente integrado** en el código:

- ✅ Dependencias instaladas (firebase_core, firebase_messaging, flutter_local_notifications)
- ✅ Android configurado (build.gradle, AndroidManifest.xml)
- ✅ Servicio PushNotificationService creado con logs detallados
- ✅ Inicialización en main.dart
- ✅ Integración en login para registrar token FCM
- ✅ Backend ya configurado para enviar notificaciones

## ✅ Firebase YA ESTÁ CONFIGURADO

El proyecto **YA TIENE** el archivo `google-services.json` configurado correctamente:

- ✅ Proyecto Firebase: `smartsales365-ecommerc`
- ✅ Package name: `com.example.movile_2ex`
- ✅ Archivo ubicado en: `android/app/google-services.json`

**¡No necesitas hacer nada más en Firebase Console!**

### Paso 1: Verificar que todo funcione

Ejecuta la aplicación:

```bash
flutter clean
flutter pub get
flutter run
```

Deberías ver en los logs:

```
✅ Firebase inicializado en main.dart
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔔 [PUSH] INICIALIZANDO PUSH NOTIFICATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [PUSH] Firebase inicializado
✅ [PUSH] Permisos de notificaciones concedidos
📱 [PUSH] FCM Token obtenido: ey...
✅ [PUSH] Token registrado en backend exitosamente
✅ [PUSH] PushNotificationService inicializado correctamente
```

### Paso 2: Probar notificaciones

1. **Haz login** en la app
2. Verifica que el token se registre correctamente
3. Desde Django Admin o Postman:
   - Cambia una orden a estado `DELIVERED`
   - Aprueba/rechaza una devolución
4. Deberías recibir la notificación en tu dispositivo

## 🔍 Logs para debugging

El sistema tiene logs exhaustivos con prefijos:

- `[PUSH]` - Inicialización general
- `[PUSH-FG]` - Notificación en foreground
- `[PUSH-BG]` - Notificación en background
- `[PUSH-TERM]` - Notificación abrió app cerrada
- `[PUSH-LOCAL]` - Notificación local tocada
- `[LOGIN]` - Inicialización después del login

## 📋 Checklist de verificación

- [x] Proyecto creado en Firebase Console (`smartsales365-ecommerc`)
- [x] App Android registrada en Firebase
- [x] Archivo `google-services.json` en `android/app/`
- [x] Dependencias instaladas con `flutter pub get`
- [ ] App ejecutada con `flutter run`
- [ ] Login realizado exitosamente
- [ ] Logs muestran "✅ Firebase inicializado"
- [ ] Logs muestran "📱 FCM Token obtenido"
- [ ] Logs muestran "✅ Token registrado en backend"

## 🐛 Troubleshooting

### Error: "google-services.json not found"

**Solución**: Verifica que el archivo está en `android/app/google-services.json`

### Error: "package_name doesn't match"

**Solución**: Verifica que el package_name en Firebase sea `com.example.movile_2ex`

### Notificaciones no llegan

**Solución**: 
1. Verifica que el backend tenga las credenciales de Firebase
2. Verifica los logs para ver si el token se registró
3. Prueba con una notificación manual desde Firebase Console

## 📚 Guía completa

Para instrucciones detalladas paso a paso, consulta:
- `GUIA_PUSH_NOTIFICATIONS_FLUTTER.md` - Guía completa del sistema

## ✨ Próximos pasos

Una vez configurado Firebase:

1. **Backend**: Asegúrate de que el backend tenga `firebase_credentials.json`
2. **Testing**: Prueba las 3 notificaciones (ORDER_DELIVERED, RETURN_APPROVED, RETURN_REJECTED)
3. **Navegación**: Implementa navegación al hacer tap en notificaciones (TODO en PushNotificationService)
4. **iOS** (opcional): Agrega soporte para iOS si lo necesitas

---

**Tiempo estimado**: 5-10 minutos para configurar Firebase Console
