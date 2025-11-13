import '../api/api_service.dart';
import '../api/api_constants.dart';
import '../models/product.dart';
import '../models/category.dart';

/// Servicio de Productos
/// Maneja todas las operaciones relacionadas con productos y categorías
class ProductService {
  final ApiService _apiService = ApiService();

  /// Obtener lista de productos
  /// Permite filtros por categoría, búsqueda, ordenamiento
  Future<List<Product>> getProducts({
    int? categoryId,
    String? search,
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (categoryId != null) queryParams['category'] = categoryId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiService.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // El backend puede devolver un objeto con 'results' o un array directo
        final List<dynamic> productsJson;
        if (data is Map && data.containsKey('results')) {
          productsJson = data['results'] as List<dynamic>;
        } else if (data is List) {
          productsJson = data;
        } else {
          throw ApiException('Formato de respuesta inesperado');
        }

        return productsJson
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al obtener productos: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener detalle de un producto por ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await _apiService.get(ApiConstants.productDetail(id));

      if (response.statusCode == 200) {
        return Product.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiException(
          'Error al obtener producto: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener productos recomendados (ML)
  Future<List<Product>> getRecommendedProducts() async {
    try {
      final response = await _apiService.get(ApiConstants.recommendedProducts);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data as List<dynamic>;
        return productsJson
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al obtener recomendaciones: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener recomendaciones basadas en un producto específico
  Future<List<Product>> getProductRecommendations(int productId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.productRecommendations(productId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data as List<dynamic>;
        return productsJson
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al obtener recomendaciones: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener lista de categorías
  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConstants.categories);

      if (response.statusCode == 200) {
        final List<dynamic> categoriesJson = response.data as List<dynamic>;
        return categoriesJson
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al obtener categorías: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener productos de una categoría específica
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.categoryProducts(categoryId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data as List<dynamic>;
        return productsJson
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al obtener productos de la categoría: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener reviews de un producto
  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.productReviews(productId),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data as List);
      } else {
        throw ApiException(
          'Error al obtener reviews: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
