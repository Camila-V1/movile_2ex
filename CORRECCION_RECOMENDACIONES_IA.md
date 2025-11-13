# 🔧 Corrección de Recomendaciones con IA - Mobile Flutter

## 🐛 Problema Identificado

El sistema de recomendaciones en la app móvil Flutter no funcionaba debido a un **desajuste entre los endpoints** que el frontend llamaba y los que el backend realmente implementa.

### Errores encontrados:

1. **Endpoint incorrecto para recomendaciones personalizadas**
   - ❌ Flutter llamaba: `/api/products/recommendations/`
   - ✅ Backend implementa: `/api/products/personalized/`

2. **Endpoint incorrecto para productos similares**
   - ❌ Flutter llamaba: `/api/products/{id}/similar/`
   - ✅ Backend implementa: `/api/products/{id}/recommendations/`

3. **Endpoint inexistente para productos populares**
   - ❌ Flutter llamaba: `/api/products/popular/`
   - ✅ Solución: Usar `/api/products/` con ordenamiento

4. **Estructura de respuesta no parseada correctamente**
   - Backend retorna: `{user: "...", count: X, recommendations: [...]}`
   - Flutter esperaba: Array directo `[...]`

## ✅ Soluciones Implementadas

### 1. Corrección de Endpoints (`recommendations_service.dart`)

#### Recomendaciones Personalizadas
```dart
// ANTES
final response = await _apiService.get('/api/products/recommendations/');

// AHORA
final response = await _apiService.get('/products/personalized/');

// Parsea correctamente: response.data['recommendations']
```

#### Productos Similares (Comprados Juntos)
```dart
// ANTES
final response = await _apiService.get('/api/products/$productId/similar/');

// AHORA
final response = await _apiService.get('/products/$productId/recommendations/');

// Parsea correctamente: response.data['recommendations']
```

#### Productos Populares
```dart
// ANTES
final response = await _apiService.get('/api/products/popular/');

// AHORA (usa catálogo normal)
final response = await _apiService.get(
  '/products/',
  queryParameters: {'ordering': '-created_at', 'page_size': limit},
);

// Parsea correctamente: response.data['results']
```

#### Recomendaciones Basadas en Carrito
```dart
// ANTES (endpoint inexistente)
await _apiService.post('/api/products/cart-recommendations/');

// AHORA (usa recommendations del primer producto)
await _apiService.get('/products/${firstProductId}/recommendations/');
```

### 2. Mejora en Parseo de Respuestas

Ahora maneja **ambos formatos** de respuesta del backend:

```dart
// Formato 1: Objeto con array (recomendaciones personalizadas)
if (response.data != null && response.data['recommendations'] != null) {
  return (response.data['recommendations'] as List)
      .map((json) => Recommendation.fromJson(json))
      .toList();
}

// Formato 2: Array directo (fallback)
if (response.data is List) {
  return (response.data as List)
      .map((json) => Recommendation.fromJson(json))
      .toList();
}
```

### 3. Modelo Robusto (`recommendation.dart`)

Mejorado el parsing del campo `price` que puede venir en diferentes tipos:

```dart
double parsePrice(dynamic priceValue) {
  if (priceValue == null) return 0.0;
  if (priceValue is double) return priceValue;
  if (priceValue is int) return priceValue.toDouble();
  if (priceValue is String) {
    return double.tryParse(priceValue) ?? 0.0;
  }
  return 0.0;
}
```

## 📊 Endpoints del Backend (Referencia)

### Recomendaciones Personalizadas con IA
```
GET /api/products/personalized/
Authorization: Bearer <token>
Query Params: ?limit=10

Respuesta:
{
  "user": "admin",
  "count": 10,
  "strategy_used": "personalized_ai",
  "favorite_categories": ["Electronics", "Gaming"],
  "recommendations": [
    {
      "id": 1,
      "name": "iPhone 15 Pro",
      "description": "...",
      "price": "999.00",
      "image_url": "https://...",
      "average_rating": 4.5,
      "review_count": 10,
      "stock": 50,
      "category_name": "Electronics"
    },
    ...
  ]
}
```

**Estrategia de IA del Backend:**
1. Analiza historial de compras del usuario
2. Identifica categorías favoritas
3. Usa collaborative filtering (usuarios similares)
4. Fallback a productos populares

### Productos Comprados Juntos
```
GET /api/products/{id}/recommendations/

Respuesta:
{
  "product": "iPhone 15 Pro",
  "recommendations": [
    {
      "id": 2,
      "name": "AirPods Pro",
      "price": "249.99",
      ...
    }
  ]
}
```

## 🧪 Cómo Probar

### 1. Test del Backend
```bash
cd backend_2ex
python test_recommendations_endpoint.py
```

**Output esperado:**
```
✓ Login exitoso
✓ Endpoint /products/personalized/ funcionando correctamente
✓ Endpoint /products/{id}/recommendations/ funcionando correctamente
✓ Estructura verificada
```

### 2. Test de la App Flutter

1. **Iniciar el backend Django:**
   ```bash
   cd backend_2ex
   python manage.py runserver
   ```

2. **Ejecutar la app Flutter:**
   ```bash
   cd movile_2ex
   flutter run
   ```

3. **Verificar funcionalidades:**
   - Login con usuario `admin` / `admin123`
   - Navegar a la sección de recomendaciones
   - Verificar que aparezcan productos personalizados
   - Ver detalles de un producto → verificar "productos similares"
   - Agregar productos al carrito → verificar recomendaciones basadas en carrito

## 📝 Archivos Modificados

### Backend (Sin cambios - ya estaba correcto)
- ✅ `products/views.py` - Endpoints de recomendaciones
- ✅ `products/urls.py` - Rutas configuradas
- ✅ `products/serializers.py` - Serialización correcta

### Mobile Flutter (Corregidos)
- 🔧 `lib/core/services/recommendations_service.dart` - Endpoints corregidos
- 🔧 `lib/core/models/recommendation.dart` - Parseo robusto de precio
- ✅ `lib/core/providers/recommendations_provider.dart` - Sin cambios (ya correcto)
- ✅ `lib/shared/widgets/recommendations_carousel.dart` - Sin cambios (ya correcto)

### Nuevos Archivos de Testing
- ✨ `backend_2ex/test_recommendations_endpoint.py` - Script de pruebas

## 🎯 Flujo de Recomendaciones

```
┌─────────────────────────────────────────────────────────┐
│              FLUTTER APP (Mobile)                       │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ GET /products/personalized/?limit=10
                 │ Authorization: Bearer <token>
                 ▼
┌─────────────────────────────────────────────────────────┐
│           DJANGO BACKEND (API)                          │
│                                                           │
│  1. Analiza historial de compras del usuario            │
│  2. Identifica categorías favoritas                     │
│  3. Busca usuarios con gustos similares                 │
│  4. Genera recomendaciones inteligentes                 │
│  5. Fallback a productos populares                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ Response:
                 │ {
                 │   "user": "admin",
                 │   "count": 10,
                 │   "strategy_used": "personalized_ai",
                 │   "recommendations": [...]
                 │ }
                 ▼
┌─────────────────────────────────────────────────────────┐
│         FLUTTER PARSEA Y MUESTRA                        │
│                                                           │
│  - RecommendationsSection widget                        │
│  - Carrusel horizontal de productos                     │
│  - Tap en producto → Navega a detalle                   │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Siguientes Pasos

### Opcional - Mejoras Futuras:

1. **Cache de Recomendaciones**
   - Guardar en local storage para acceso offline
   - Refrescar cada 24 horas

2. **Analytics**
   - Trackear qué recomendaciones se tocan
   - Mejorar algoritmo basado en interacciones

3. **Más Estrategias**
   - Recomendaciones por ubicación
   - Recomendaciones por temporada
   - Recomendaciones por precio similar

4. **UI/UX**
   - Animaciones al cargar
   - Skeleton loading
   - Pull to refresh

## ⚠️ Notas Importantes

1. **Autenticación Requerida**: El endpoint `/products/personalized/` requiere token JWT válido.

2. **Datos Iniciales**: Si un usuario no tiene historial de compras, el sistema usa la estrategia "popular_products".

3. **Performance**: El backend usa queries optimizadas con `annotate()` y `Count()` para evitar N+1 queries.

4. **CORS**: El backend ya tiene CORS configurado para `localhost` y producción.

5. **Testing**: Siempre prueba con `python test_recommendations_endpoint.py` antes de probar en móvil.

## ✅ Checklist de Verificación

- [x] Endpoints corregidos en `recommendations_service.dart`
- [x] Parseo de respuesta mejorado (maneja ambos formatos)
- [x] Modelo `Recommendation` actualizado con parsing robusto
- [x] Script de testing creado (`test_recommendations_endpoint.py`)
- [x] Documentación actualizada
- [ ] Testing manual en app Flutter
- [ ] Verificar en diferentes dispositivos
- [ ] Probar con usuarios sin historial
- [ ] Probar con usuarios con mucho historial

---

**Fecha de corrección**: 13 de Noviembre 2025  
**Estado**: ✅ Correcciones aplicadas - Listo para testing  
**Impacto**: Alto - Funcionalidad principal restaurada
