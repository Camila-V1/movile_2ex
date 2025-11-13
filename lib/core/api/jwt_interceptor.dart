import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_constants.dart';

/// JWT Interceptor para manejo automático de tokens
/// Equivalente a la lógica de api.js del proyecto React
class JwtInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys para storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  JwtInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Obtener el access token del secure storage
    final accessToken = await _storage.read(key: _accessTokenKey);

    // Añadir token al header si existe
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si el error es 401 (Unauthorized), intentar refrescar el token
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Intentar refrescar el token
          final newTokens = await _refreshAccessToken(refreshToken);

          if (newTokens != null) {
            // Guardar el nuevo access token
            await _storage.write(
              key: _accessTokenKey,
              value: newTokens['access'],
            );

            // Si viene un nuevo refresh token, también guardarlo
            if (newTokens.containsKey('refresh')) {
              await _storage.write(
                key: _refreshTokenKey,
                value: newTokens['refresh'],
              );
            }

            // Reintentar la petición original con el nuevo token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer ${newTokens['access']}';

            final response = await _dio.fetch(options);
            return handler.resolve(response);
          } else {
            // Si no se pudo refrescar, limpiar tokens y retornar error
            await clearTokens();
            return handler.reject(err);
          }
        } catch (e) {
          // Si falla el refresh, limpiar tokens y retornar error
          await clearTokens();
          return handler.reject(err);
        }
      } else {
        // No hay refresh token, limpiar todo
        await clearTokens();
        return handler.reject(err);
      }
    }

    return handler.next(err);
  }

  /// Refrescar el access token usando el refresh token
  Future<Map<String, dynamic>?> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {
            'Authorization': null, // No enviar el token viejo
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Guardar tokens en secure storage
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _accessTokenKey, value: accessToken);
    await storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Obtener el access token actual
  static Future<String?> getAccessToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: _accessTokenKey);
  }

  /// Obtener el refresh token actual
  static Future<String?> getRefreshToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: _refreshTokenKey);
  }

  /// Limpiar todos los tokens (logout)
  static Future<void> clearTokens() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
  }

  /// Verificar si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: _accessTokenKey);
    return accessToken != null && accessToken.isNotEmpty;
  }
}
