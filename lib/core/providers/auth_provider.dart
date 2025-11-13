import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Estado de autenticación
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  /// Estado inicial (sin autenticar)
  const AuthState.initial()
    : user = null,
      isLoading = false,
      isAuthenticated = false,
      error = null;

  /// Estado de carga
  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() =>
      'AuthState(user: ${user?.email}, isAuth: $isAuthenticated, isLoading: $isLoading)';
}

/// Notifier para gestionar el estado de autenticación
/// Equivalente a AuthContext del proyecto React
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    // Verificar si hay sesión al iniciar
    checkAuth();
  }

  /// Verificar si hay una sesión activa
  Future<void> checkAuth() async {
    print('🔵 AUTH: Iniciando checkAuth()');
    state = state.copyWith(isLoading: true, clearError: true);
    print('🔵 AUTH: isLoading = true');

    try {
      final isAuth = await _authService.isAuthenticated();
      print('🔵 AUTH: isAuthenticated() devolvió = $isAuth');

      if (isAuth) {
        // Hay tokens, intentar obtener el perfil
        await loadUser();
      } else {
        // No hay sesión
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        print(
          '🔵 AUTH: Sin sesión - isLoading = false, isAuthenticated = false',
        );
      }
    } catch (e) {
      print('Error al verificar autenticación: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Error al verificar sesión',
      );
    }
  }

  /// Cargar datos del usuario actual
  Future<void> loadUser() async {
    try {
      final user = await _authService.getProfile();
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      print('Error al cargar usuario: $e');
      // Si falla, limpiar la sesión
      await logout();
    }
  }

  /// Login con email y password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.login(email: email, password: password);

      // Cargar el perfil del usuario
      await loadUser();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Registro de nuevo usuario
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      state = state.copyWith(isLoading: false, clearError: true);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Actualizar perfil del usuario
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState.initial();
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider principal de autenticación
/// Úsalo en tus widgets con: ref.watch(authProvider)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
