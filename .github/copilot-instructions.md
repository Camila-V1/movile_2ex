# Flutter Mobile - SmartSales365 E-commerce App

## Architecture Overview

**Flutter e-commerce client** consuming Django REST API at `https://backend-2ex-ecommerce.onrender.com`. Feature-driven architecture with Riverpod for state management.

**Tech Stack**:
- Flutter ^3.9.0
- Riverpod ^2.6.1 (state management)
- Dio ^5.7.0 (HTTP client with interceptors)
- GoRouter ^14.6.2 (declarative routing)
- Flutter Stripe ^11.2.0 (payments)
- Speech to Text ^7.0.0 (voice cart commands)

**Project Structure**:
```
lib/
├── core/                    # Shared infrastructure
│   ├── api/                 # API client & JWT interceptor
│   ├── models/              # Data models (User, Product, Order, etc.)
│   ├── providers/           # Global Riverpod providers
│   └── routing/             # GoRouter configuration
├── features/                # Feature modules
│   ├── auth/                # Login, register, profile
│   ├── products/            # Catalog, search, filters
│   ├── cart/                # Shopping cart with NLP
│   ├── orders/              # Order history, tracking
│   ├── wallet/              # Virtual wallet balance
│   ├── returns/             # Return requests
│   └── admin/               # Admin dashboard
└── shared/                  # Reusable widgets
```

## Critical Conventions

### 1. API Service Pattern
Centralized HTTP client in `core/api/api_service.dart` with JWT interceptor:

```dart
// core/api/jwt_interceptor.dart
class JWTInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}
```

**Always use `ApiService` methods, never raw Dio calls**:
```dart
// ✅ Correct
final products = await ApiService.get<List<Product>>('/products/');

// ❌ Wrong
final response = await Dio().get('https://api.com/products/');
```

### 2. Model Serialization
All models in `core/models/` follow consistent JSON serialization:

```dart
// core/models/product.dart
class Product {
  final int id;
  final String name;
  final double price;
  
  Product.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        price = (json['price'] as num).toDouble();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };
  
  // Immutability pattern
  Product copyWith({String? name, double? price}) => Product(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
  );
}
```

### 3. State Management with Riverpod
Use providers for all state. No StatefulWidgets for business logic.

```dart
// features/cart/providers/cart_provider.dart
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this.ref) : super(CartState.initial());
  
  final Ref ref;
  
  Future<void> addItem(Product product, int quantity) async {
    state = state.copyWith(isLoading: true);
    try {
      await ApiService.post('/orders/cart/add/', {
        'product_id': product.id,
        'quantity': quantity,
      });
      state = state.copyWith(items: [...state.items, CartItem(product, quantity)]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
```

**Watch providers in build methods**:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final cart = ref.watch(cartProvider);
  return Text('Items: ${cart.items.length}');
}
```

### 4. Secure Token Storage
**Critical**: Use `flutter_secure_storage` for tokens, NOT SharedPreferences.

```dart
// core/api/api_service.dart
final _storage = FlutterSecureStorage();

// Store tokens
await _storage.write(key: 'access_token', value: token);
await _storage.write(key: 'refresh_token', value: refreshToken);

// ❌ NEVER store tokens in SharedPreferences (plain text)
```

### 5. Navigation with GoRouter
Declarative routing with role-based guards:

```dart
// core/routing/app_router.dart
final appRouter = GoRouter(
  redirect: (context, state) {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;
    
    if (state.location.startsWith('/admin') && !isAdmin) {
      return '/home';  // Redirect non-admins
    }
    
    if (!isAuthenticated && state.location != '/login') {
      return '/login';
    }
    
    return null;  // Allow navigation
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/admin', builder: (_, __) => AdminDashboard()),
  ],
);
```

### 6. Stripe Integration
Flutter Stripe requires initialization in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Stripe.publishableKey = 'pk_test_xxx';  // From env
  await Stripe.instance.applySettings();
  
  runApp(MyApp());
}
```

Payment flow mirrors web:
```dart
// features/checkout/checkout_service.dart
final session = await ApiService.post('/orders/$orderId/create-checkout-session/');
await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    merchantDisplayName: 'SmartSales365',
    paymentIntentClientSecret: session['clientSecret'],
  ),
);
await Stripe.instance.presentPaymentSheet();
```

## Developer Workflows

### Setup
```bash
# Install dependencies
flutter pub get

# Generate code (if using build_runner)
flutter pub run build_runner build

# Run on emulator/device
flutter run
```

### Hot Reload vs Hot Restart
- **Hot Reload (r)**: UI changes, stateless updates
- **Hot Restart (R)**: State changes, provider modifications
- **Full Restart**: Native code changes, dependency updates

### Testing
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter drive --target=test_driver/app.dart
```

### Build Release
```bash
# Android APK
flutter build apk --release

# iOS IPA (requires Mac)
flutter build ios --release
```

## Key Patterns

### Error Handling
Consistent error display across features:

```dart
// shared/widgets/error_widget.dart
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
```

### Loading States
Use shimmer placeholders, not spinners:

```dart
// shared/widgets/product_card_shimmer.dart
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Container(
    height: 200,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
```

### Image Loading
Always use `CachedNetworkImage` for remote images:

```dart
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fit: BoxFit.cover,
);
```

## Backend Integration

### API Endpoints
Same as backend (`backend_2ex/API_SCHEMA.md`):
- `POST /api/token/` - Login
- `GET /api/products/` - Product catalog
- `POST /api/orders/` - Create order
- `GET /api/wallet/balance/` - Wallet balance
- `POST /api/orders/cart/add-natural-language/` - NLP cart commands

### Role-Based UI
Conditionally render features based on user role:

```dart
final user = ref.watch(authProvider).user;

if (user?.role == 'ADMIN' || user?.role == 'MANAGER') {
  return AdminDashboardTab();
} else if (user?.role == 'CAJERO') {
  return POSScreen();
} else {
  return CustomerHomeScreen();
}
```

### Voice Cart Commands
Integrate Speech-to-Text for NLP cart:

```dart
// features/cart/voice_cart_service.dart
final speech = SpeechToText();
await speech.initialize();

speech.listen(
  onResult: (result) async {
    final command = result.recognizedWords;  // "Agrega 2 iPhones"
    await ApiService.post('/orders/cart/add-natural-language/', {
      'command': command,
    });
  },
);
```

## Common Pitfalls

1. **Don't use StatefulWidget for business logic** - Use Riverpod providers
2. **Always handle token refresh** - Interceptor handles 401 automatically
3. **Test on physical device for Stripe** - Emulators can have payment issues
4. **Request permissions for voice** - `permission_handler` for microphone access
5. **Cache network images** - Backend doesn't serve optimized images
6. **Handle null safety** - All models use null-safe types
7. **Dispose controllers** - TextEditingControllers, AnimationControllers, etc.
8. **Use const constructors** - Performance optimization for immutable widgets

## Platform-Specific Notes

### Android
- Min SDK: 21 (Lollipop)
- Requires internet permission in `AndroidManifest.xml`
- Stripe requires `compileSdkVersion 33+`

### iOS
- Deployment target: 13.0
- Requires camera/microphone permissions in `Info.plist`
- Stripe requires `platform :ios, '13.0'` in Podfile

### Web (experimental)
- CORS configured on backend for `localhost:5173`
- Stripe web requires `flutter_stripe_web` package
- No voice commands (Speech-to-Text not supported)

## Quick Reference

**API Base URL**: `https://backend-2ex-ecommerce.onrender.com/api`  
**Test Users**: See `backend_2ex/CREDENCIALES_SISTEMA.md`  
**Stripe Test Key**: Check backend `.env.example`  
**Project Guides**: See documentation files in project root (e.g., `README.md`, `PROJECT_STATUS.md`)
