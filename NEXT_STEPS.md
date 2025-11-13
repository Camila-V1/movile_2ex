# 🎯 Próximos Pasos - Fase 1: Autenticación y Productos

## Resumen de Fase 0 Completada ✅

Has completado exitosamente la fundación del proyecto. Ahora tienes:

- ✅ Estructura de carpetas escalable
- ✅ API Service con Dio configurado
- ✅ JWT Interceptor funcionando
- ✅ 7 modelos de datos completos
- ✅ Sistema de diseño (tema)
- ✅ Utilidades y widgets comunes
- ✅ Tests básicos pasando
- ✅ 0 errores de análisis estático

## 📋 Fase 1: Plan de Implementación

### Paso 1: Crear AuthService (30-45 min)

Crear `lib/core/services/auth_service.dart`:

```dart
class AuthService {
  final ApiService _apiService = ApiService();
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    
    // Guardar tokens
    await JwtInterceptor.saveTokens(
      accessToken: response.data['access'],
      refreshToken: response.data['refresh'],
    );
    
    return response.data;
  }
  
  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _apiService.post(
      ApiConstants.register,
      data: userData,
    );
    return response.data;
  }
  
  // Get Profile
  Future<User> getProfile() async {
    final response = await _apiService.get(ApiConstants.userProfile);
    return User.fromJson(response.data);
  }
  
  // Logout
  Future<void> logout() async {
    await _apiService.post(ApiConstants.logout);
    await JwtInterceptor.clearTokens();
  }
  
  // Check if authenticated
  Future<bool> isAuthenticated() async {
    return await JwtInterceptor.isAuthenticated();
  }
}
```

### Paso 2: Crear AuthProvider con Riverpod (45-60 min)

Crear `lib/core/providers/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado de autenticación
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  AuthState({this.user, this.isLoading = false, this.error});
  
  bool get isAuthenticated => user != null;
  
  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Provider del servicio
final authServiceProvider = Provider((ref) => AuthService());

// Provider de estado
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(AuthState()) {
    checkAuth();
  }
  
  Future<void> checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      await loadUser();
    }
  }
  
  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.getProfile();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.login(email, password);
      await loadUser();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<bool> register(Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.register(userData);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
```

### Paso 3: Configurar GoRouter (45-60 min)

Crear `lib/core/routing/app_router.dart`:

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');
      
      // Si está en splash, dejarlo continuar
      if (state.matchedLocation == '/splash') {
        return null;
      }
      
      // Si no está autenticado y no va a auth, redirigir a login
      if (!isAuthenticated && !isGoingToAuth) {
        return '/auth/login';
      }
      
      // Si está autenticado y va a auth, redirigir a home
      if (isAuthenticated && isGoingToAuth) {
        return '/';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      // Más rutas...
    ],
  );
});
```

### Paso 4: Crear Pantallas de Auth (2-3 horas)

#### LoginScreen

Crear `lib/features/auth/screens/login_screen.dart`:

```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(Icons.shopping_bag, size: 100, color: AppTheme.primaryColor),
                SizedBox(height: AppTheme.paddingLG),
                Text('Smart Sales', style: AppTheme.heading1),
                SizedBox(height: AppTheme.paddingXL),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !AppUtils.isValidEmail(value)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.paddingMD),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Mínimo 8 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.paddingLG),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? CircularProgressIndicator()
                        : Text('Iniciar Sesión'),
                  ),
                ),
                
                // Register link
                TextButton(
                  onPressed: () => context.go('/auth/register'),
                  child: Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        context.go('/');
      } else {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(authProvider).error ?? 'Error')),
        );
      }
    }
  }
}
```

### Paso 5: Actualizar app.dart (15 min)

```dart
class SmartSalesApp extends ConsumerWidget {
  const SmartSalesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Smart Sales',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
```

## 🔄 Orden de Implementación Sugerido

1. **Día 1 Mañana**: AuthService + AuthProvider
2. **Día 1 Tarde**: GoRouter configurado
3. **Día 2 Mañana**: LoginScreen + RegisterScreen
4. **Día 2 Tarde**: Testing y ajustes
5. **Día 3**: ProductService + ProductProvider + Pantallas

## 📚 Recursos Útiles

- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Form Validation](https://docs.flutter.dev/cookbook/forms/validation)

## 🎓 Tips Importantes

1. **Usa ref.read() para acciones**, ref.watch() para UI reactiva
2. **Maneja errores en cada pantalla** con try-catch
3. **Valida formularios** antes de enviar al backend
4. **Muestra feedback** al usuario (SnackBars, Dialogs)
5. **Testea cada feature** antes de seguir a la siguiente

## 🐛 Debugging

Si algo no funciona:

1. Verifica que el backend esté en línea
2. Revisa los logs de Dio (están activados)
3. Usa breakpoints en el interceptor
4. Verifica que los modelos coincidan con el backend
5. Comprueba que los tokens se guarden correctamente

---

¡Éxito en la Fase 1! 🚀
