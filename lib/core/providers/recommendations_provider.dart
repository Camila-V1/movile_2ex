import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_service.dart';
import '../models/recommendation.dart';
import '../services/recommendations_service.dart';

// Provider del servicio de recomendaciones
final recommendationsServiceProvider = Provider<RecommendationsService>((ref) {
  // Instanciar ApiService directamente como en otros lugares del proyecto
  final apiService = ApiService();
  return RecommendationsService(apiService: apiService);
});

// Recomendaciones personalizadas
final personalizedRecommendationsProvider = FutureProvider<List<Recommendation>>((
  ref,
) async {
  print(
    '🎯 [PROVIDER-PERSONAL] Iniciando provider de recomendaciones personalizadas',
  );
  final service = ref.watch(recommendationsServiceProvider);
  try {
    final result = await service.getPersonalizedRecommendations(limit: 10);
    print('🎯 [PROVIDER-PERSONAL] Resultado: ${result.length} recomendaciones');
    return result;
  } catch (e) {
    print('❌ [PROVIDER-PERSONAL] Error: $e');
    // Si no está autenticado, retornar lista vacía
    if (e.toString().contains('401') || e.toString().contains('autenticado')) {
      print(
        '⚠️ [PROVIDER-PERSONAL] Usuario no autenticado, retornando lista vacía',
      );
      return [];
    }
    rethrow;
  }
});

// Productos populares (no requiere autenticación)
final popularProductsProvider = FutureProvider<List<Recommendation>>((
  ref,
) async {
  print('🎯 [PROVIDER-POPULAR] Iniciando provider de productos populares');
  final service = ref.watch(recommendationsServiceProvider);
  final result = await service.getPopularProducts(limit: 10);
  print('🎯 [PROVIDER-POPULAR] Resultado: ${result.length} productos');
  return result;
});

// Productos similares a uno específico
final similarProductsProvider =
    FutureProvider.family<List<Recommendation>, int>((ref, productId) async {
      final service = ref.watch(recommendationsServiceProvider);
      try {
        return await service.getSimilarProducts(productId, limit: 5);
      } catch (e) {
        if (e.toString().contains('401') ||
            e.toString().contains('autenticado')) {
          return [];
        }
        rethrow;
      }
    });

// Recomendaciones basadas en carrito
final cartRecommendationsProvider =
    FutureProvider.family<List<Recommendation>, List<int>>((
      ref,
      cartProductIds,
    ) async {
      final service = ref.watch(recommendationsServiceProvider);
      try {
        if (cartProductIds.isEmpty) return [];
        return await service.getCartBasedRecommendations(
          cartProductIds: cartProductIds,
          limit: 5,
        );
      } catch (e) {
        if (e.toString().contains('401') ||
            e.toString().contains('autenticado')) {
          return [];
        }
        rethrow;
      }
    });
