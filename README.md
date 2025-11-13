# 🛍️ Smart Sales Mobile - E-commerce Flutter App

Aplicación móvil de ecommerce desarrollada en Flutter, migrada desde React. Conecta con el backend Django REST Framework desplegado en `https://backend-2ex-ecommerce.onrender.com`.

## 📋 Características Principales

### Para Clientes
- 🔐 Autenticación completa (Login/Registro)
- 🛒 Catálogo de productos con búsqueda y filtros
- 🛍️ Carrito de compras
- 💳 Pagos con Stripe integrado
- 💰 Billetera virtual con saldo reutilizable
- 📦 Seguimiento de pedidos
- 🔄 Sistema de devoluciones
- ⭐ Reseñas y valoraciones de productos
- 🤖 Recomendaciones personalizadas con ML
- 🎤 Asistente de voz para el carrito

### Para Administradores
- 📊 Dashboard con estadísticas
- 👥 Gestión de usuarios
- 📦 Gestión de productos y categorías
- 📋 Gestión de pedidos
- 📈 Reportes y análisis
- 🤖 Generador de reportes con IA
- 🔍 Auditoría del sistema

### Para Managers
- 🔄 Gestión de devoluciones
- ✅ Aprobación/rechazo de solicitudes
- 📊 Dashboard de devoluciones

## 🏗️ Arquitectura del Proyecto

El proyecto sigue una **arquitectura feature-driven** limpia y escalable:

```
lib/
├── core/                    # Lógica central
│   ├── api/                 # Configuración de API
│   │   ├── api_constants.dart
│   │   ├── api_service.dart
│   │   └── jwt_interceptor.dart
│   ├── models/              # Modelos de datos
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── cart.dart
│   │   ├── order.dart
│   │   ├── wallet.dart
│   │   └── return_request.dart
│   ├── providers/           # Estado global (Riverpod)
│   ├── services/            # Servicios de negocio
│   └── routing/             # Configuración de rutas
│
├── features/                # Features por módulo
│   ├── auth/
│   ├── products/
│   ├── cart/
│   ├── orders/
│   ├── wallet/
│   ├── returns/
│   ├── admin/
│   └── manager/
│
└── shared/                  # Componentes compartidos
    ├── widgets/
    ├── constants/
    └── utils/
```

## 🚀 Tecnologías Utilizadas

- **Flutter** ^3.9.0 - Framework de UI
- **Riverpod** ^2.6.1 - Gestión de estado
- **Dio** ^5.7.0 - Cliente HTTP
- **Flutter Secure Storage** ^9.2.2 - Almacenamiento seguro de tokens
- **GoRouter** ^14.6.2 - Navegación y rutas
- **Flutter Stripe** ^11.2.0 - Pagos integrados
- **FL Chart** ^0.69.2 - Gráficos para dashboard
- **Speech to Text** ^7.0.0 - Asistente de voz
- **Image Picker** ^1.1.2 - Selección de imágenes

## 🔑 Características Técnicas

### Autenticación JWT
- Interceptor automático que añade tokens a las peticiones
- Refresh automático de tokens expirados
- Almacenamiento seguro encriptado
- Manejo de sesiones

### API Service
- Cliente Dio configurado con timeouts
- Manejo centralizado de errores
- Logging en modo debug
- Métodos helper para GET, POST, PUT, DELETE
- Soporte para upload/download de archivos

### Modelos de Datos
- Serialización/deserialización JSON automática
- Métodos `fromJson` y `toJson`
- Métodos `copyWith` para inmutabilidad
- Getters computados para lógica de presentación

## 📦 Instalación y Configuración

### Prerrequisitos
- Flutter SDK ^3.9.0
- Android Studio / Xcode (según plataforma)
- Dispositivo físico o emulador

### Pasos de Instalación

1. **Instalar dependencias**
```bash
flutter pub get
```

2. **Ejecutar la aplicación**
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## 🔧 Configuración del Backend

El backend está desplegado en:
```
https://backend-2ex-ecommerce.onrender.com
```

Los endpoints están configurados en `lib/core/api/api_constants.dart`.

## 📱 Roadmap de Desarrollo

### ✅ Fase 0: Fundación (COMPLETADO)
- [x] Configuración de dependencias
- [x] Estructura de carpetas
- [x] API Service con Dio
- [x] JWT Interceptor
- [x] Modelos de datos básicos
- [x] Tema de la aplicación

### 🔄 Fase 1: Autenticación y Productos (SIGUIENTE)
- [ ] Pantallas de Login/Registro
- [ ] AuthProvider con Riverpod
- [ ] Catálogo de productos
- [ ] Detalle de producto
- [ ] Sistema de navegación con GoRouter

### 📋 Fase 2: Carrito y Checkout
- [ ] CartProvider
- [ ] Pantalla de carrito
- [ ] Integración de Stripe
- [ ] Checkout y confirmación

### 💰 Fase 3: Billetera y Devoluciones
- [ ] WalletProvider y pantallas
- [ ] Sistema de devoluciones
- [ ] Integración con billetera

### 👨‍💼 Fase 4: Paneles Admin/Manager
- [ ] Dashboard de administración
- [ ] CRUD de productos/usuarios
- [ ] Panel de manager
- [ ] Reportes e IA

## 📄 Licencia

Este proyecto es privado - Segundo Examen SI2

---

**Nota**: Proyecto en desarrollo activo. Funcionalidad implementándose por fases.
