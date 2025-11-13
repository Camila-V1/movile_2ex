import '../api/api_service.dart';
import '../api/api_constants.dart';
import '../api/jwt_interceptor.dart';
import '../models/user.dart';

/// Servicio de Autenticación
/// Equivalente a authService de api.js del proyecto React
class AuthService {
  final ApiService _apiService = ApiService();

  /// Login con username y password (igual que web_2ex)
  /// Retorna los datos del usuario y guarda los tokens
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 AUTH_SERVICE: Enviando login a ${ApiConstants.login}');
      print('🔵 AUTH_SERVICE: username=$email, password=***');

      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'username': email,
          'password': password,
        }, // Backend usa 'username'
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Guardar tokens en secure storage
        if (data['access'] != null && data['refresh'] != null) {
          await JwtInterceptor.saveTokens(
            accessToken: data['access'] as String,
            refreshToken: data['refresh'] as String,
          );
        }

        return data;
      } else {
        throw ApiException(
          'Error al iniciar sesión: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Registro de nuevo usuario
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Error al registrarse: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener perfil del usuario autenticado
  Future<User> getProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.userProfile);

      if (response.statusCode == 200) {
        return User.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiException(
          'Error al obtener perfil: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar perfil del usuario
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (email != null) data['email'] = email;

      final response = await _apiService.patch(
        ApiConstants.userProfile,
        data: data,
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiException(
          'Error al actualizar perfil: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout - Limpiar tokens y notificar al backend
  Future<void> logout() async {
    try {
      // Intentar notificar al backend (opcional, puede fallar si el token ya expiró)
      await _apiService.post(ApiConstants.logout);
    } catch (e) {
      // Ignorar errores del logout en el backend
      print('Error al hacer logout en backend: $e');
    } finally {
      // Siempre limpiar los tokens locales
      await JwtInterceptor.clearTokens();
    }
  }

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    return await JwtInterceptor.isAuthenticated();
  }

  /// Obtener el token de acceso actual
  Future<String?> getAccessToken() async {
    return await JwtInterceptor.getAccessToken();
  }
}
