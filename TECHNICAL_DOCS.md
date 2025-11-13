# 📚 Documentación Técnica - Smart Sales Mobile

## Fase 0 Completada ✅

### Resumen de lo Implementado

#### 1. Configuración del Proyecto
- ✅ Instalación de dependencias principales
- ✅ Configuración de `pubspec.yaml` con todas las librerías necesarias
- ✅ Estructura de carpetas feature-driven completa

#### 2. Core - API Layer

##### `api_constants.dart`
Contiene todas las URLs de los endpoints del backend:
- Endpoints de autenticación
- Endpoints de productos y categorías
- Endpoints de carrito y órdenes
- Endpoints de pagos (Stripe)
- Endpoints de billetera
- Endpoints de devoluciones
- Endpoints de administración
- Endpoints de manager

##### `api_service.dart`
Servicio centralizado para peticiones HTTP con Dio:
- Métodos: GET, POST, PUT, PATCH, DELETE
- Upload y download de archivos
- Manejo de errores personalizado
- Logging automático en modo debug
- Timeouts configurables
- Singleton pattern

##### `jwt_interceptor.dart`
Interceptor de Dio para manejo automático de JWT:
- Añade automáticamente el token a las peticiones
- Detecta tokens expirados (401)
- Refresca el access token usando el refresh token
- Reintenta la petición original con el nuevo token
- Almacenamiento seguro con `flutter_secure_storage`
- Métodos estáticos para gestión de tokens

#### 3. Core - Models

Todos los modelos incluyen:
- Serialización/deserialización JSON (`fromJson`, `toJson`)
- Método `copyWith` para inmutabilidad
- Getters computados para lógica de presentación
- Override de `toString`, `==` y `hashCode`

##### Modelos Creados:
1. **User** - Usuario del sistema
   - Roles: client, admin, manager
   - Getters: `isAdmin`, `isManager`, `isClient`, `fullName`

2. **Category** - Categorías de productos
   - Incluye contador de productos

3. **Product** - Producto del catálogo
   - Incluye rating, reviews, stock
   - Getters: `isAvailable`, `isLowStock`, `isOutOfStock`, `priceFormatted`

4. **Cart & CartItem** - Carrito de compras
   - Cálculo automático de subtotales
   - Cart vacío con factory

5. **Order & OrderItem** - Órdenes de compra
   - Estados: pending, processing, shipped, delivered, cancelled
   - Métodos de pago: stripe, wallet
   - Getters para estados

6. **Wallet & WalletTransaction** - Billetera virtual
   - Tipos de transacción: credit, debit
   - Historial de transacciones

7. **ReturnRequest** - Solicitudes de devolución
   - Estados: pending, approved, rejected, refunded
   - Vinculada con órdenes

#### 4. Shared - UI Components

##### `app_theme.dart`
Sistema de diseño completo:
- Colores primarios, secundarios y de acento
- Colores de estado (success, warning, error, info)
- Tema Material 3 configurado
- Espaciados estandarizados (XS, SM, MD, LG, XL)
- Bordes redondeados consistentes
- Sombras predefinidas
- Tamaños de texto
- Estilos de texto personalizados
- Helper para colores de estado dinámicos

##### `app_utils.dart`
Utilidades generales:
- Formateo de precios, fechas, números
- Validaciones (email, password, phone, URL)
- Manipulación de strings (capitalize, truncate)
- Generación de iniciales y colores
- Mensajes de error amigables

##### `loading_indicator.dart`
Widgets de estado:
- `LoadingIndicator` - Spinner con mensaje opcional
- `LoadingOverlay` - Overlay de carga pantalla completa
- `EmptyState` - Estado vacío personalizable
- `ErrorDisplay` - Pantalla de error con retry

#### 5. Estructura de Carpetas Creada

```
lib/
├── core/
│   ├── api/
│   │   ├── api_constants.dart ✅
│   │   ├── api_service.dart ✅
│   │   └── jwt_interceptor.dart ✅
│   ├── models/
│   │   ├── models.dart ✅ (barrel file)
│   │   ├── user.dart ✅
│   │   ├── category.dart ✅
│   │   ├── product.dart ✅
│   │   ├── cart.dart ✅
│   │   ├── order.dart ✅
│   │   ├── wallet.dart ✅
│   │   └── return_request.dart ✅
│   ├── providers/ ⏳
│   ├── services/ ⏳
│   └── routing/ ⏳
├── features/
│   ├── auth/ ⏳
│   ├── products/ ⏳
│   ├── cart/ ⏳
│   ├── orders/ ⏳
│   ├── wallet/ ⏳
│   ├── returns/ ⏳
│   ├── admin/ ⏳
│   └── manager/ ⏳
└── shared/
    ├── widgets/
    │   └── loading_indicator.dart ✅
    ├── constants/
    │   └── app_theme.dart ✅
    └── utils/
        └── app_utils.dart ✅
```

## 🎯 Próximos Pasos - Fase 1

### 1. Servicios de Backend
Crear servicios que usen `ApiService` para comunicarse con el backend:

- `auth_service.dart`
  - login(email, password)
  - register(userData)
  - logout()
  - getProfile()
  - updateProfile()

- `product_service.dart`
  - getProducts(filters)
  - getProductById(id)
  - getRecommendations()
  - getCategories()

- `cart_service.dart`
  - getCart()
  - addToCart(productId, quantity)
  - updateCartItem(itemId, quantity)
  - removeFromCart(itemId)

### 2. Providers con Riverpod
Crear providers para gestión de estado global:

- `auth_provider.dart`
  - Estado: user, isAuthenticated, isLoading
  - Métodos: login, register, logout, checkAuth

- `cart_provider.dart`
  - Estado: cart, itemCount, total
  - Métodos: addItem, removeItem, updateQuantity, clear

### 3. Routing con GoRouter
- Configurar rutas públicas y protegidas
- Implementar guards de autenticación
- Configurar deep linking

### 4. Pantallas de Autenticación
- `login_screen.dart`
- `register_screen.dart`
- Formularios con validación
- Manejo de errores

### 5. Pantallas de Productos
- `product_catalog_screen.dart` - Lista con búsqueda/filtros
- `product_detail_screen.dart` - Detalle con reviews
- Widgets reutilizables: ProductCard, ReviewsList

## 🔒 Seguridad Implementada

1. **Tokens JWT**
   - Almacenamiento encriptado con `flutter_secure_storage`
   - Refresh automático transparente
   - Limpieza al logout

2. **Validaciones**
   - Email con regex
   - Contraseñas mínimo 8 caracteres
   - URLs validadas

3. **Manejo de Errores**
   - Try-catch en todas las peticiones
   - Mensajes amigables al usuario
   - Logging para debugging

## 📱 Compatibilidad

El proyecto está configurado para:
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ Linux
- ✅ macOS

## 🧪 Testing

Estructura preparada para:
- Unit tests (modelos, utilidades)
- Widget tests (componentes UI)
- Integration tests (flujos completos)

## 📦 Paquetes Clave

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| dio | ^5.7.0 | Cliente HTTP |
| flutter_riverpod | ^2.6.1 | Estado global |
| flutter_secure_storage | ^9.2.2 | Tokens seguros |
| go_router | ^14.6.2 | Navegación |
| flutter_stripe | ^11.2.0 | Pagos |
| fl_chart | ^0.69.2 | Gráficos |
| speech_to_text | ^7.0.0 | Voz |
| image_picker | ^1.1.2 | Imágenes |

## 🎨 Design System

El tema usa Material Design 3 con:
- Color primario: Indigo (#6366F1)
- Color secundario: Violet (#8B5CF6)
- Color acento: Pink (#EC4899)
- Tipografía escalable
- Espaciados consistentes
- Componentes estilizados

---

**Estado del Proyecto**: Fase 0 completada ✅  
**Siguiente Hito**: Implementar autenticación y navegación (Fase 1)  
**Fecha**: Noviembre 2025
