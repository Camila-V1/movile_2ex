import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/products/screens/product_catalog_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/cart/screens/checkout_screen.dart';
import '../../features/cart/screens/payment_success_screen.dart';
import '../../features/cart/screens/payment_cancelled_screen.dart';
import '../../features/orders/screens/my_orders_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/returns/screens/return_request_screen.dart';
import '../../features/returns/screens/my_returns_screen.dart';
import '../../features/wallet/screens/my_wallet_screen.dart';

/// Configuración de rutas con GoRouter
/// Maneja navegación y rutas protegidas
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Redirect logic para rutas protegidas
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');

      print(
        '🟢 ROUTER: redirect() - isLoading=$isLoading, isAuth=$isAuthenticated, location=${state.matchedLocation}',
      );

      // Si está cargando, no redirigir aún
      if (isLoading) {
        print('🟢 ROUTER: Cargando... esperando');
        return null;
      }

      // Si no está autenticado y no va a auth, redirigir a login
      if (!isAuthenticated && !isGoingToAuth) {
        print('🟢 ROUTER: No autenticado, redirigiendo a /auth/login');
        return '/auth/login';
      }

      // Si está autenticado y va a auth, redirigir a home
      if (isAuthenticated && isGoingToAuth) {
        print('🟢 ROUTER: Autenticado en pantalla auth, redirigiendo a /');
        return '/';
      }

      print('🟢 ROUTER: Sin redirección necesaria');
      return null;
    },

    routes: [
      // === Rutas de Autenticación ===
      GoRoute(
        path: '/auth/login',
        name: 'login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),

      GoRoute(
        path: '/auth/register',
        name: 'register',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RegisterScreen()),
      ),

      // === Rutas Protegidas ===

      // Home - Catálogo de Productos
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProductCatalogScreen(),
        ),
      ),

      // Detalle de Producto
      GoRoute(
        path: '/products/:id',
        name: 'product-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MaterialPage(
            key: state.pageKey,
            child: ProductDetailScreen(productId: id),
          );
        },
      ),

      // === Rutas del Carrito ===

      // Carrito de Compras
      GoRoute(
        path: '/cart',
        name: 'cart',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const CartScreen()),
      ),

      // Checkout
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const CheckoutScreen()),
      ),

      // Pago Exitoso
      GoRoute(
        path: '/payment-success',
        name: 'payment-success',
        pageBuilder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          final paidWithWallet =
              state.uri.queryParameters['paidWithWallet'] == 'true';
          return MaterialPage(
            key: state.pageKey,
            child: PaymentSuccessScreen(
              orderId: orderId,
              paidWithWallet: paidWithWallet,
            ),
          );
        },
      ),

      // Pago Cancelado
      GoRoute(
        path: '/payment-cancelled',
        name: 'payment-cancelled',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PaymentCancelledScreen(),
        ),
      ),

      // === Rutas de Pedidos ===

      // Mis Pedidos
      GoRoute(
        path: '/my-orders',
        name: 'my-orders',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MyOrdersScreen()),
        routes: [
          // Detalle de Pedido
          GoRoute(
            path: ':id',
            name: 'order-detail',
            pageBuilder: (context, state) {
              final orderId = int.parse(state.pathParameters['id']!);
              return MaterialPage(
                key: state.pageKey,
                child: OrderDetailScreen(orderId: orderId),
              );
            },
            routes: [
              // Solicitud de Devolución
              GoRoute(
                path: 'request-return/:itemId',
                name: 'request-return',
                pageBuilder: (context, state) {
                  final orderId = int.parse(state.pathParameters['id']!);
                  final itemId = int.parse(state.pathParameters['itemId']!);
                  return MaterialPage(
                    key: state.pageKey,
                    child: ReturnRequestScreen(
                      orderId: orderId,
                      orderItemId: itemId,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Mis Devoluciones (lista)
      GoRoute(
        path: '/my-returns',
        name: 'my-returns',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MyReturnsScreen()),
      ),

      // Mi Billetera
      GoRoute(
        path: '/my-wallet',
        name: 'my-wallet',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MyWalletScreen()),
      ),

      // TODO: Agregar más rutas según avancemos
      // - Wallet
      // - Returns
      // - Profile
      // - Admin
      // - Manager
    ],

    // Página de error
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'Error desconocido'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
