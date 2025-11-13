# Smart Sales - Aplicación Móvil E-Commerce 📱

## 🎯 Descripción del Proyecto

Aplicación móvil de comercio electrónico desarrollada en **Flutter** que se conecta al backend Django REST del proyecto web `web_2ex`. Implementa un sistema completo de compras con autenticación, catálogo de productos, carrito de compras y pagos con Stripe.

**Repositorio:** `git@github.com:Camila-V1/movile_2ex.git`

## 🏗️ Arquitectura

### **Stack Tecnológico**
- **Framework:** Flutter ^3.9.0
- **State Management:** Riverpod ^2.6.1
- **HTTP Client:** Dio ^5.7.0 con interceptor JWT
- **Navegación:** GoRouter ^14.6.2
- **Pagos:** Stripe Flutter SDK ^11.2.0
- **Almacenamiento:** flutter_secure_storage + shared_preferences
- **Imágenes:** cached_network_image

### **Backend**
- **URL:** https://backend-2ex-ecommerce.onrender.com
- **API:** Django REST Framework
- **Autenticación:** JWT (SimpleJWT)

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── api/                    # Servicios HTTP y constantes
│   │   ├── api_service.dart    # Cliente Dio con interceptores
│   │   ├── api_constants.dart  # Endpoints del backend
│   │   └── jwt_interceptor.dart # Manejo de tokens JWT
│   ├── models/                 # Modelos de datos
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── category.dart
│   │   ├── cart_item.dart
│   │   ├── order.dart
│   │   └── wallet.dart
│   ├── providers/              # Estado global (Riverpod)
│   │   ├── auth_provider.dart
│   │   └── cart_provider.dart
│   ├── routing/                # Configuración de rutas
│   │   └── app_router.dart     # GoRouter con protección de rutas
│   └── services/               # Lógica de negocio
│       ├── auth_service.dart
│       ├── product_service.dart
│       ├── order_service.dart
│       └── wallet_service.dart
├── features/
│   ├── auth/screens/           # Login y registro
│   ├── products/screens/       # Catálogo y detalle
│   └── cart/screens/           # Carrito, checkout, pagos
├── shared/
│   ├── constants/              # Tema y constantes UI
│   ├── widgets/                # Componentes reutilizables
│   └── utils/                  # Funciones auxiliares
└── main.dart                   # Entry point
```

## ✨ Funcionalidades Implementadas

### ✅ **Fase 1: Autenticación y Productos**
- [x] Login con usuario/contraseña
- [x] Registro de nuevos usuarios
- [x] Almacenamiento seguro de tokens JWT
- [x] Refresh automático de tokens
- [x] Catálogo de productos con grid responsive
- [x] Búsqueda de productos
- [x] Filtrado por categorías (12 categorías)
- [x] Detalle de producto con imágenes
- [x] Indicadores de stock (disponible/bajo/agotado)

### ✅ **Fase 2: Carrito y Pagos**
- [x] Añadir productos al carrito
- [x] Modificar cantidades (+/-)
- [x] Eliminar productos del carrito
- [x] Badge con contador de items
- [x] Persistencia local del carrito
- [x] Cálculo automático de subtotal/impuestos/total
- [x] Formulario de dirección de envío
- [x] Integración con Stripe
- [x] Consulta de saldo de billetera
- [x] Pantallas de éxito/cancelación de pago

### ⏳ **Pendiente (Fases 3-4)**
- [ ] Historial de pedidos
- [ ] Sistema de devoluciones
- [ ] Recarga de billetera virtual
- [ ] Panel de administración
- [ ] Panel de manager/cajero
- [ ] Reportes con IA

## 🔧 Configuración del Proyecto

### **Requisitos Previos**
- Flutter SDK >= 3.9.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode (para emuladores)
- Cuenta de Stripe (para testing)

### **Instalación**

1. **Clonar el repositorio:**
```bash
git clone git@github.com:Camila-V1/movile_2ex.git
cd movile_2ex
```

2. **Instalar dependencias:**
```bash
flutter pub get
```

3. **Configurar variables de entorno:**
El proyecto ya incluye:
- Backend URL: `https://backend-2ex-ecommerce.onrender.com`
- Stripe Key (test): Configurada en el código

4. **Ejecutar la aplicación:**
```bash
# Para Android
flutter run

# Para iOS
flutter run -d ios

# Para web
flutter run -d chrome
```

### **Configuración de Android (Stripe)**
El proyecto ya incluye las configuraciones necesarias:
- `minSdkVersion: 21`
- `MainActivity` extendiendo `FlutterFragmentActivity`
- Tema `Theme.AppCompat.Light.NoActionBar`

## 🧪 Testing

### **Credenciales de Prueba**
```
Usuario: juan_cliente
Password: juan123
Rol: Cliente
```

### **Tarjeta de Prueba Stripe**
```
Número: 4242 4242 4242 4242
Fecha: Cualquier fecha futura
CVC: Cualquier 3 dígitos
ZIP: Cualquier código postal
```

### **Flujo de Prueba Completo**
1. Abrir la app → Login automático o usar credenciales
2. Navegar por el catálogo
3. Filtrar por categoría (ej: "Electrónica")
4. Buscar un producto (ej: "Humidificador")
5. Tap en un producto → Ver detalle
6. Añadir al carrito
7. Ver carrito (ícono arriba)
8. Modificar cantidades
9. Proceder al checkout
10. Ingresar dirección de envío
11. Pagar con Stripe (usar tarjeta de prueba)
12. Ver pantalla de confirmación

## 🐛 Solución de Problemas Comunes

### **Error: "Method POST not allowed"**
✅ **Solucionado** - El proyecto usa los endpoints correctos:
- Crear orden: `POST /api/orders/create/`
- No usar: `POST /api/orders/`

### **Error: "Wallet balance 404"**
✅ **Solucionado** - Endpoint correcto:
- Balance: `GET /api/users/wallets/my_balance/`

### **Error: "RenderFlex overflow"**
✅ **Solucionado** - UI optimizada con `Expanded` y `Flexible`

### **Hot Reload no aplica cambios**
⚠️ Para cambios en servicios/constantes/providers:
```bash
# Detener la app (q) y ejecutar:
flutter run

# O hacer Hot Restart (R mayúscula)
```

## 📊 Endpoints del Backend

### **Autenticación**
- `POST /api/token/` - Login
- `POST /api/token/refresh/` - Refresh token
- `POST /api/users/` - Registro
- `GET /api/users/profile/` - Perfil del usuario

### **Productos**
- `GET /api/products/` - Lista de productos
- `GET /api/products/{id}/` - Detalle de producto
- `GET /api/products/categories/` - Lista de categorías

### **Órdenes**
- `POST /api/orders/create/` - Crear orden
- `GET /api/orders/my-orders/` - Mis órdenes
- `POST /api/orders/{id}/create-checkout-session/` - Stripe session

### **Billetera**
- `GET /api/users/wallets/my_balance/` - Consultar saldo

## 🎨 Diseño y UI

### **Sistema de Diseño**
- **Colores:** Material Design 3
- **Primary:** Azul (#2196F3)
- **Secondary:** Naranja (#FF9800)
- **Tipografía:** Roboto
- **Componentes:** Material Design components

### **Responsive**
- Grid de 2 columnas en móviles
- Ajusta automáticamente en tablets
- Soporte para modo oscuro (futuro)

## 📝 Notas de Desarrollo

### **Decisiones de Arquitectura**
1. **Riverpod sobre Provider:** Mejor type-safety y testing
2. **GoRouter sobre Navigator 2.0:** Declarativo y más simple
3. **Dio sobre http:** Interceptores y mejor manejo de errores
4. **StateNotifier sobre setState:** Estado predecible y escalable

### **Optimizaciones Aplicadas**
- Cache de imágenes con `cached_network_image`
- `FutureProvider.autoDispose` con `keepAlive()` para evitar requests infinitos
- Persistencia del carrito con `shared_preferences`
- Tokens JWT en `flutter_secure_storage` (encriptado)

### **Compatibilidad**
- ✅ Android 5.0+ (API 21+)
- ✅ iOS 11.0+
- ✅ Web (con limitaciones de Stripe)

## 📚 Recursos Adicionales

- **Backend Web:** https://github.com/Camila-V1/web_2ex.git
- **Backend Django:** https://backend-2ex-ecommerce.onrender.com
- **Documentación Flutter:** https://flutter.dev/docs
- **Documentación Stripe:** https://stripe.com/docs/payments/accept-a-payment

## 👥 Equipo

**Desarrollador:** Camila V.
**Materia:** Sistemas de Información 2
**Institución:** [Tu Universidad]
**Fecha:** Noviembre 2025

## 📄 Licencia

Este proyecto es parte de un examen académico.

---

**Estado del Proyecto:** ✅ Fases 1-2 Completadas | ⏳ Fases 3-4 Pendientes

**Última actualización:** 12 de Noviembre, 2025
