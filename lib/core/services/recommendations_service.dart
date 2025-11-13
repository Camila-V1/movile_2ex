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
    try {
      final response = await _apiService.get(
        '/api/products/recommendations/',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 404) {
        // Endpoint no implementado aún en el backend
        print('⚠️ Endpoint /api/products/recommendations/ no disponible');
        return [];
      }

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception(
          'No autenticado. Inicia sesión para recomendaciones personalizadas.',
        );
      }
      if (e.toString().contains('404')) {
        print('⚠️ Endpoint /api/products/recommendations/ no disponible');
        return [];
      }
      print('❌ Error en recomendaciones: $e');
      return [];
    }
  }

  /// Obtiene productos similares a uno específico
  /// Requiere autenticación
  Future<List<Recommendation>> getSimilarProducts(
    int productId, {
    int limit = 5,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/products/$productId/similar/',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 404) {
        print('⚠️ Endpoint /api/products/$productId/similar/ no disponible');
        return [];
      }

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception(
          'No autenticado. Inicia sesión para ver productos similares.',
        );
      }
      if (e.toString().contains('404')) {
        print('⚠️ Endpoint /api/products/$productId/similar/ no disponible');
        return [];
      }
      print('❌ Error en productos similares: $e');
      return [];
    }
  }

  /// Obtiene productos populares (no requiere autenticación)
  Future<List<Recommendation>> getPopularProducts({int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '/api/products/popular/',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 404) {
        print('⚠️ Endpoint /api/products/popular/ no disponible');
        return [];
      }

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (e.toString().contains('404')) {
        print('⚠️ Endpoint /api/products/popular/ no disponible');
        return [];
      }
      print('❌ Error en productos populares: $e');
      return [];
    }
  }

  /// Obtiene recomendaciones basadas en los productos del carrito
  /// Requiere autenticación
  Future<List<Recommendation>> getCartBasedRecommendations({
    required List<int> cartProductIds,
    int limit = 5,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/products/cart-recommendations/',
        data: {'cart_product_ids': cartProductIds, 'limit': limit},
      );

      if (response.statusCode == 404) {
        print('⚠️ Endpoint /api/products/cart-recommendations/ no disponible');
        return [];
      }

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception(
          'No autenticado. Inicia sesión para recomendaciones del carrito.',
        );
      }
      if (e.toString().contains('404')) {
        print('⚠️ Endpoint /api/products/cart-recommendations/ no disponible');
        return [];
      }
      print('❌ Error en recomendaciones del carrito: $e');
      return [];
    }
  }
}
