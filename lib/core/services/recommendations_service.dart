import '../models/recommendation.dart';
import '../api/api_service.dart';

class RecommendationsService {
  final ApiService _apiService;

  RecommendationsService({required ApiService apiService})
    : _apiService = apiService;

  /// Obtiene recomendaciones personalizadas basadas en el historial del usuario
  /// Requiere autenticación
  Future<List<Recommendation>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    print(
      '🔍 [RECOM-PERSONAL] Iniciando llamada a /api/products/personalized/',
    );
    try {
      final response = await _apiService.get(
        '/api/products/personalized/',
        queryParameters: {'limit': limit},
      );

      print('🔍 [RECOM-PERSONAL] Status: ${response.statusCode}');
      print('🔍 [RECOM-PERSONAL] Data type: ${response.data.runtimeType}');

      if (response.statusCode == 404) {
        // Endpoint no implementado aún en el backend
        print(
          '! [RECOM-PERSONAL] Endpoint /api/products/personalized/ no disponible (404)',
        );
        return [];
      }

      // El backend retorna un objeto con 'recommendations' array
      if (response.data != null && response.data['recommendations'] != null) {
        print(
          '✅ [RECOM-PERSONAL] Encontró data[recommendations], cantidad: ${(response.data['recommendations'] as List).length}',
        );
        return (response.data['recommendations'] as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }

      // Fallback: si es un array directo
      if (response.data is List) {
        print(
          '✅ [RECOM-PERSONAL] Encontró array directo, cantidad: ${(response.data as List).length}',
        );
        return (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }

      print(
        '⚠️ [RECOM-PERSONAL] No se pudo parsear la respuesta, retornando lista vacía',
      );
      return [];
    } catch (e) {
      print('❌ [RECOM-PERSONAL] Exception: $e');
      if (e.toString().contains('401')) {
        print('❌ [RECOM-PERSONAL] Error 401: No autenticado');
        throw Exception(
          'No autenticado. Inicia sesión para recomendaciones personalizadas.',
        );
      }
      if (e.toString().contains('404')) {
        print('⚠️ [RECOM-PERSONAL] Error 404: Endpoint no disponible');
        return [];
      }
      print('❌ [RECOM-PERSONAL] Error inesperado: $e');
      return [];
    }
  }

  /// Obtiene productos similares a uno específico (productos comprados juntos)
  /// Usa el endpoint de recommendations del backend
  Future<List<Recommendation>> getSimilarProducts(
    int productId, {
    int limit = 5,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/products/$productId/recommendations/',
      );

      if (response.statusCode == 404) {
        print(
          '⚠️ Endpoint /api/products/$productId/recommendations/ no disponible',
        );
        return [];
      }

      // El backend retorna un objeto con 'recommendations' array
      if (response.data != null && response.data['recommendations'] != null) {
        return (response.data['recommendations'] as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }

      // Fallback: si es un array directo
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      if (e.toString().contains('404')) {
        print(
          '⚠️ Endpoint /api/products/$productId/recommendations/ no disponible',
        );
        return [];
      }
      print('❌ Error en productos similares: $e');
      return [];
    }
  }

  /// Obtiene productos populares (usa productos recientes del catálogo)
  /// No requiere autenticación - usa el endpoint de productos normal
  Future<List<Recommendation>> getPopularProducts({int limit = 10}) async {
    print('🔍 [RECOM-POPULAR] Iniciando llamada a /api/products/');
    try {
      // Usar el endpoint de productos normal, ordenado por ventas/creación
      final response = await _apiService.get(
        '/api/products/',
        queryParameters: {'ordering': '-created_at', 'page_size': limit},
      );

      print('🔍 [RECOM-POPULAR] Status: ${response.statusCode}');
      print('🔍 [RECOM-POPULAR] Data type: ${response.data.runtimeType}');

      if (response.statusCode == 404) {
        print('! [RECOM-POPULAR] Endpoint /api/products/ no disponible (404)');
        return [];
      }

      // El backend retorna paginado: {count, results, next, previous}
      if (response.data != null && response.data['results'] != null) {
        print(
          '✅ [RECOM-POPULAR] Encontró data[results], cantidad: ${(response.data['results'] as List).length}',
        );
        return (response.data['results'] as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }

      // Fallback: si es un array directo
      if (response.data is List) {
        print(
          '✅ [RECOM-POPULAR] Encontró array directo, cantidad: ${(response.data as List).length}',
        );
        return (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }

      print(
        '⚠️ [RECOM-POPULAR] No se pudo parsear la respuesta, retornando lista vacía',
      );
      print('🔍 [RECOM-POPULAR] Estructura de data: ${response.data}');
      return [];
    } catch (e) {
      print('❌ [RECOM-POPULAR] Exception: $e');
      if (e.toString().contains('404')) {
        print('⚠️ [RECOM-POPULAR] Error 404: Endpoint no disponible');
        return [];
      }
      print('❌ [RECOM-POPULAR] Error inesperado: $e');
      return [];
    }
  }

  /// Obtiene recomendaciones basadas en los productos del carrito
  /// Usa el endpoint de recommendations para el primer producto del carrito
  Future<List<Recommendation>> getCartBasedRecommendations({
    required List<int> cartProductIds,
    int limit = 5,
  }) async {
    try {
      if (cartProductIds.isEmpty) return [];

      // Usar el primer producto del carrito para obtener recomendaciones
      final firstProductId = cartProductIds.first;
      final response = await _apiService.get(
        '/api/products/$firstProductId/recommendations/',
      );

      if (response.statusCode == 404) {
        print(
          '⚠️ Endpoint /api/products/$firstProductId/recommendations/ no disponible',
        );
        return [];
      }

      // El backend retorna un objeto con 'recommendations' array
      if (response.data != null && response.data['recommendations'] != null) {
        final recommendations = (response.data['recommendations'] as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();

        // Limitar a la cantidad solicitada
        return recommendations.take(limit).toList();
      }

      // Fallback: si es un array directo
      if (response.data is List) {
        final recommendations = (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
        return recommendations.take(limit).toList();
      }

      return [];
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️ Endpoint de recommendations no disponible');
        return [];
      }
      print('❌ Error en recomendaciones del carrito: $e');
      return [];
    }
  }
}
