# 🤖 Guía: Recomendaciones con IA para Clientes (Flutter)

## 📋 Índice
1. [Introducción al Sistema](#introducción-al-sistema)
2. [Endpoints del Backend](#endpoints-del-backend)
3. [Modelos de Datos](#modelos-de-datos)
4. [Servicio de Recomendaciones](#servicio-de-recomendaciones)
5. [Provider con Riverpod](#provider-con-riverpod)
6. [Pantallas y Widgets](#pantallas-y-widgets)
7. [Integración Completa](#integración-completa)
8. [Testing](#testing)

---

## 🎯 Introducción al Sistema

El backend ya tiene implementado un sistema de recomendaciones con Machine Learning que analiza:
- ✅ Historial de compras del usuario
- ✅ Productos en el carrito actual
- ✅ Reseñas y valoraciones
- ✅ Patrones de compra similares
- ✅ Popularidad de productos

**Algoritmo:** Sistema híbrido (Collaborative Filtering + Content-Based)

---

## 📡 Endpoints del Backend

### 1. **Recomendaciones Personalizadas**
```
GET /api/products/recommendations/
```
**Autenticación:** Bearer Token requerido  
**Respuesta:** Lista de productos recomendados basados en el usuario

### 2. **Productos Similares**
```
GET /api/products/{id}/similar/
```
**Autenticación:** Bearer Token requerido  
**Respuesta:** Productos similares al producto especificado

### 3. **Productos Populares**
```
GET /api/products/popular/
```
**Autenticación:** No requerida  
**Respuesta:** Productos más vendidos y mejor valorados

---

## 📦 Modelos de Datos

### Crear `lib/core/models/recommendation.dart`

```dart
class Recommendation {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final double averageRating;
  final int reviewCount;
  final int stock;
  final String categoryName;
  final double? recommendationScore; // Score de ML (0-1)
  final String? recommendationReason; // Por qué se recomienda

  Recommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.averageRating,
    required this.reviewCount,
    required this.stock,
    required this.categoryName,
    this.recommendationScore,
    this.recommendationReason,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'],
      averageRating: json['average_rating'] != null 
          ? double.parse(json['average_rating'].toString()) 
          : 0.0,
      reviewCount: json['review_count'] ?? 0,
      stock: json['stock'] ?? 0,
      categoryName: json['category_name'] ?? '',
      recommendationScore: json['recommendation_score'] != null
          ? double.parse(json['recommendation_score'].toString())
          : null,
      recommendationReason: json['recommendation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'stock': stock,
      'category_name': categoryName,
      'recommendation_score': recommendationScore,
      'recommendation_reason': recommendationReason,
    };
  }

  // Getters útiles
  bool get isInStock => stock > 0;
  bool get isHighlyRated => averageRating >= 4.0;
  String get priceFormatted => '\$${price.toStringAsFixed(2)}';
  
  String get recommendationReasonDisplay {
    if (recommendationReason != null) return recommendationReason!;
    if (recommendationScore != null && recommendationScore! >= 0.8) {
      return 'Altamente recomendado para ti';
    }
    if (isHighlyRated) return 'Producto mejor valorado';
    return 'Recomendado';
  }
}
```

---

## 🔌 Servicio de Recomendaciones

### Crear `lib/core/services/recommendations_service.dart`

```dart
import 'package:dio/dio.dart';
import '../api/api_service.dart';
import '../models/recommendation.dart';

class RecommendationsService {
  final ApiService _apiService;

  RecommendationsService({required ApiService apiService})
      : _apiService = apiService;

  /// Obtener recomendaciones personalizadas para el usuario
  Future<List<Recommendation>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/products/recommendations/',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Recommendation.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('No autenticado. Inicia sesión para ver recomendaciones');
      }
      print('❌ Error obteniendo recomendaciones: ${e.message}');
      return [];
    } catch (e) {
      print('❌ Error inesperado: $e');
      return [];
    }
  }

  /// Obtener productos similares a uno específico
  Future<List<Recommendation>> getSimilarProducts(
    int productId, {
    int limit = 5,
  }) async {
    try {
      final response = await _apiService.get(
        '/products/$productId/similar/',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Recommendation.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo productos similares: ${e.message}');
      return [];
    } catch (e) {
      print('❌ Error inesperado: $e');
      return [];
    }
  }

  /// Obtener productos populares (no requiere autenticación)
  Future<List<Recommendation>> getPopularProducts({
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/products/popular/',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Recommendation.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo productos populares: ${e.message}');
      return [];
    } catch (e) {
      print('❌ Error inesperado: $e');
      return [];
    }
  }

  /// Obtener recomendaciones basadas en el carrito actual
  Future<List<Recommendation>> getCartBasedRecommendations({
    required List<int> cartProductIds,
    int limit = 5,
  }) async {
    try {
      // El backend puede tener este endpoint específico
      final response = await _apiService.post(
        '/products/cart-recommendations/',
        data: {
          'product_ids': cartProductIds,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Recommendation.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo recomendaciones de carrito: ${e.message}');
      // Fallback: obtener productos populares
      return getPopularProducts(limit: limit);
    } catch (e) {
      print('❌ Error inesperado: $e');
      return [];
    }
  }
}
```

---

## 🎯 Provider con Riverpod

### Crear `lib/core/providers/recommendations_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recommendations_service.dart';
import '../models/recommendation.dart';
import 'api_provider.dart';

// Provider del servicio
final recommendationsServiceProvider = Provider<RecommendationsService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RecommendationsService(apiService: apiService);
});

// Provider de recomendaciones personalizadas
final personalizedRecommendationsProvider = FutureProvider<List<Recommendation>>((ref) async {
  final service = ref.watch(recommendationsServiceProvider);
  return service.getPersonalizedRecommendations(limit: 10);
});

// Provider de productos populares
final popularProductsProvider = FutureProvider<List<Recommendation>>((ref) async {
  final service = ref.watch(recommendationsServiceProvider);
  return service.getPopularProducts(limit: 10);
});

// Provider de productos similares (con parámetro)
final similarProductsProvider = FutureProvider.family<List<Recommendation>, int>(
  (ref, productId) async {
    final service = ref.watch(recommendationsServiceProvider);
    return service.getSimilarProducts(productId, limit: 5);
  },
);

// Provider de recomendaciones del carrito (con parámetro)
final cartRecommendationsProvider = FutureProvider.family<List<Recommendation>, List<int>>(
  (ref, cartProductIds) async {
    final service = ref.watch(recommendationsServiceProvider);
    return service.getCartBasedRecommendations(
      cartProductIds: cartProductIds,
      limit: 5,
    );
  },
);
```

---

## 🎨 Pantallas y Widgets

### 1. **Widget de Recomendaciones** - `lib/shared/widgets/recommendations_section.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/recommendations_provider.dart';
import '../../core/models/recommendation.dart';
import 'package:go_router/go_router.dart';

class RecommendationsSection extends ConsumerWidget {
  final String title;
  final RecommendationType type;
  final int? productId;
  final List<int>? cartProductIds;

  const RecommendationsSection({
    Key? key,
    required this.title,
    required this.type,
    this.productId,
    this.cartProductIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seleccionar el provider según el tipo
    final recommendationsAsync = _getProvider(ref);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          recommendationsAsync.when(
            data: (recommendations) {
              if (recommendations.isEmpty) {
                return _buildEmptyState();
              }
              return _buildRecommendationsList(context, recommendations);
            },
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error),
          ),
        ],
      ),
    );
  }

  AsyncValue<List<Recommendation>> _getProvider(WidgetRef ref) {
    switch (type) {
      case RecommendationType.personalized:
        return ref.watch(personalizedRecommendationsProvider);
      case RecommendationType.popular:
        return ref.watch(popularProductsProvider);
      case RecommendationType.similar:
        if (productId == null) throw Exception('productId required for similar');
        return ref.watch(similarProductsProvider(productId!));
      case RecommendationType.cart:
        if (cartProductIds == null) throw Exception('cartProductIds required');
        return ref.watch(cartRecommendationsProvider(cartProductIds!));
    }
  }

  Widget _buildRecommendationsList(BuildContext context, List<Recommendation> recommendations) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          return _RecommendationCard(recommendation: recommendation);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 280,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'No hay recomendaciones disponibles',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Error al cargar recomendaciones',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}

enum RecommendationType {
  personalized,
  popular,
  similar,
  cart,
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/products/${recommendation.id}');
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: recommendation.imageUrl != null
                      ? Image.network(
                          recommendation.imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                
                // Badge de recomendación
                if (recommendation.recommendationScore != null &&
                    recommendation.recommendationScore! >= 0.8)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Top',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Información del producto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      recommendation.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          recommendation.averageRating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          ' (${recommendation.reviewCount})',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    
                    Spacer(),
                    
                    // Precio
                    Text(
                      recommendation.priceFormatted,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    
                    // Razón de recomendación
                    if (recommendation.recommendationReason != null)
                      Text(
                        recommendation.recommendationReasonDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
    );
  }
}
```

### 2. **Pantalla de Inicio con Recomendaciones** - `lib/features/products/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/recommendations_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navegar al carrito
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner promocional
            _buildPromoBanner(context),
            
            // Recomendaciones personalizadas
            RecommendationsSection(
              title: 'Recomendado para ti',
              type: RecommendationType.personalized,
            ),
            
            Divider(),
            
            // Productos populares
            RecommendationsSection(
              title: 'Lo más vendido',
              type: RecommendationType.popular,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🤖 Recomendaciones con IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Productos seleccionados especialmente para ti',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. **Productos Similares en Detalle** - Agregar a `product_detail_screen.dart`

```dart
// En la pantalla de detalle del producto, agregar:

@override
Widget build(BuildContext context, WidgetRef ref) {
  return Scaffold(
    appBar: AppBar(title: Text('Detalle del Producto')),
    body: SingleChildScrollView(
      child: Column(
        children: [
          // ... información del producto ...
          
          Divider(height: 32),
          
          // Productos similares
          RecommendationsSection(
            title: 'Productos similares',
            type: RecommendationType.similar,
            productId: widget.productId,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
```

### 4. **Recomendaciones en Carrito** - Agregar a `cart_screen.dart`

```dart
// En la pantalla de carrito, agregar:

@override
Widget build(BuildContext context, WidgetRef ref) {
  final cart = ref.watch(cartProvider);
  final cartProductIds = cart.items.map((item) => item.productId).toList();
  
  return Scaffold(
    appBar: AppBar(title: Text('Carrito')),
    body: Column(
      children: [
        // ... lista de productos en el carrito ...
        
        if (cart.items.isNotEmpty) ...[
          Divider(),
          
          // Recomendaciones basadas en el carrito
          RecommendationsSection(
            title: 'Puede que también te guste',
            type: RecommendationType.cart,
            cartProductIds: cartProductIds,
          ),
        ],
        
        // ... botón de checkout ...
      ],
    ),
  );
}
```

---

## 🔄 Integración Completa

### Flujo de Recomendaciones

```
1. Usuario inicia sesión
   ↓
2. Backend analiza:
   - Historial de compras
   - Productos en carrito
   - Reseñas dadas
   - Patrones de usuarios similares
   ↓
3. Algoritmo ML genera scores
   ↓
4. Flutter solicita recomendaciones
   ↓
5. Backend retorna productos ordenados por score
   ↓
6. UI muestra recomendaciones en:
   - Pantalla de inicio
   - Detalle de producto
   - Carrito
```

---

## 🧪 Testing

### Test del Servicio

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('RecommendationsService', () {
    late RecommendationsService service;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      service = RecommendationsService(apiService: mockApiService);
    });

    test('debe obtener recomendaciones personalizadas', () async {
      // Arrange
      final mockResponse = Response(
        data: [
          {'id': 1, 'name': 'Producto 1', 'price': 100.0, ...},
          {'id': 2, 'name': 'Producto 2', 'price': 200.0, ...},
        ],
        statusCode: 200,
      );
      
      when(mockApiService.get('/products/recommendations/'))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await service.getPersonalizedRecommendations();

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[0].name, 'Producto 1');
    });

    test('debe manejar error de autenticación', () async {
      // Arrange
      when(mockApiService.get('/products/recommendations/'))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(statusCode: 401),
          ));

      // Act & Assert
      expect(
        () => service.getPersonalizedRecommendations(),
        throwsException,
      );
    });
  });
}
```

### Probar con cURL

```bash
# 1. Login
curl -X POST https://backend-2ex-ecommerce.onrender.com/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"email":"juan@email.com","password":"juan123"}'

TOKEN="<access_token>"

# 2. Obtener recomendaciones personalizadas
curl -X GET https://backend-2ex-ecommerce.onrender.com/api/products/recommendations/ \
  -H "Authorization: Bearer $TOKEN"

# 3. Obtener productos similares
curl -X GET https://backend-2ex-ecommerce.onrender.com/api/products/1/similar/ \
  -H "Authorization: Bearer $TOKEN"

# 4. Obtener productos populares (sin auth)
curl -X GET https://backend-2ex-ecommerce.onrender.com/api/products/popular/
```

---

## 🎯 Características Implementadas

✅ Recomendaciones personalizadas con ML  
✅ Productos similares por producto  
✅ Productos más populares  
✅ Recomendaciones basadas en carrito  
✅ Scores de recomendación (0-1)  
✅ Razones de por qué se recomienda  
✅ UI con cards horizontales  
✅ Badge "Top" para altamente recomendados  
✅ Integración con Riverpod  
✅ Manejo de errores robusto  
✅ Loading states  
✅ Empty states  

---

## 📱 Ejemplo Completo de Uso

```dart
// En cualquier pantalla

// 1. Recomendaciones personalizadas
RecommendationsSection(
  title: 'Recomendado para ti',
  type: RecommendationType.personalized,
)

// 2. Productos similares
RecommendationsSection(
  title: 'Productos similares',
  type: RecommendationType.similar,
  productId: 123,
)

// 3. Productos populares
RecommendationsSection(
  title: 'Lo más vendido',
  type: RecommendationType.popular,
)

// 4. Basado en carrito
final cartIds = [1, 2, 3];
RecommendationsSection(
  title: 'Puede que también te guste',
  type: RecommendationType.cart,
  cartProductIds: cartIds,
)
```

---

## 🚀 Próximos Pasos

- [ ] Agregar filtros por categoría en recomendaciones
- [ ] Implementar refresh manual de recomendaciones
- [ ] Agregar animaciones a las cards
- [ ] Implementar "me gusta/no me gusta" para mejorar ML
- [ ] Agregar analytics para tracking de recomendaciones clickeadas
- [ ] Implementar cache local de recomendaciones
- [ ] Agregar notificaciones push de nuevas recomendaciones

---

## 🐛 Solución de Problemas

### 1. No muestra recomendaciones

**Problema:** Lista vacía.

**Soluciones:**
- Verificar que el usuario tenga historial de compras
- Verificar que el token sea válido
- Verificar que el backend tenga datos suficientes para ML
- Probar con productos populares (no requiere auth)

### 2. Error 401

**Problema:** No autenticado.

**Solución:**
- Verificar que el token esté en el header
- Verificar que el token no haya expirado
- Hacer logout/login de nuevo

### 3. Recomendaciones no relevantes

**Problema:** Productos no relacionados con el usuario.

**Soluciones:**
- El usuario necesita más historial de compras
- Verificar que las reseñas estén registradas correctamente
- El algoritmo ML necesita más datos de entrenamiento

---

¡Listo! Ahora tienes recomendaciones con IA completamente integradas en tu app Flutter. 🤖✨
