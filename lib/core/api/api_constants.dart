/// API Constants and Endpoints
/// Equivalente a constants/api.js del proyecto React
class ApiConstants {
  // Base URL del backend Django REST Framework
  static const String baseUrl = 'https://backend-2ex-ecommerce.onrender.com';
  static const String apiVersion = '/api';

  // Auth Endpoints (igual que web_2ex)
  static const String login = '$apiVersion/token/';
  static const String register = '$apiVersion/users/';
  static const String refreshToken = '$apiVersion/token/refresh/';
  static const String logout = '$apiVersion/auth/logout/';
  static const String userProfile = '$apiVersion/users/profile/';

  // Products Endpoints (igual que web_2ex)
  static const String products = '$apiVersion/products/';
  static String productDetail(int id) => '$apiVersion/products/$id/';
  static const String categories = '$apiVersion/products/categories/';
  static String categoryProducts(int id) =>
      '$apiVersion/products/categories/$id/';

  // ML Recommendations
  static const String recommendedProducts = '$apiVersion/products/recommended/';
  static String productRecommendations(int id) =>
      '$apiVersion/products/$id/recommendations/';

  // Cart Endpoints
  static const String cart = '$apiVersion/cart/';
  static const String cartItems = '$apiVersion/cart/items/';
  static String cartItemDetail(int id) => '$apiVersion/cart/items/$id/';

  // Orders Endpoints
  static const String orders = '$apiVersion/orders/';
  static const String createOrder = '$apiVersion/orders/create/';
  static String orderDetail(int id) => '$apiVersion/orders/$id/';
  static const String myOrders =
      '$apiVersion/orders/'; // Igual que 'orders' - el backend filtra por usuario autenticado

  // Stripe Payment Endpoints
  static const String createPaymentIntent =
      '$apiVersion/orders/create-payment-intent/';
  static const String confirmPayment = '$apiVersion/payments/confirm/';
  static const String paymentStatus = '$apiVersion/payments/status/';

  // Wallet Endpoints
  static const String wallet = '$apiVersion/wallet/';
  static const String walletTransactions =
      '$apiVersion/users/wallet-transactions/my_transactions/';
  static const String walletBalance = '$apiVersion/users/wallets/my_balance/';

  // Returns Endpoints - Sistema Simplificado de Devoluciones
  static const String returns = '$apiVersion/deliveries/returns/';
  static String returnDetail(int id) => '$apiVersion/deliveries/returns/$id/';
  static const String myReturns = '$apiVersion/deliveries/returns/my-returns/';
  static String sendToEvaluation(int id) =>
      '$apiVersion/deliveries/returns/$id/send-to-evaluation/';
  static String approveReturn(int id) =>
      '$apiVersion/deliveries/returns/$id/approve/';
  static String rejectReturn(int id) =>
      '$apiVersion/deliveries/returns/$id/reject/';

  // Reviews Endpoints
  static const String reviews = '$apiVersion/reviews/';
  static String productReviews(int productId) =>
      '$apiVersion/products/$productId/reviews/';

  // Admin Endpoints
  static const String adminUsers = '$apiVersion/admin/users/';
  static String adminUserDetail(int id) => '$apiVersion/admin/users/$id/';
  static const String adminProducts = '$apiVersion/admin/products/';
  static String adminProductDetail(int id) => '$apiVersion/admin/products/$id/';
  static const String adminOrders = '$apiVersion/admin/orders/';
  static const String adminCategories = '$apiVersion/admin/categories/';
  static const String adminDashboard = '$apiVersion/admin/dashboard/';
  static const String adminReports = '$apiVersion/admin/reports/';
  static const String adminAudit = '$apiVersion/admin/audit/';

  // AI Reports
  static const String generateAIReport =
      '$apiVersion/admin/ai-report/generate/';

  // Manager Endpoints
  static const String managerReturns = '$apiVersion/manager/returns/';
  static const String managerDashboard = '$apiVersion/manager/dashboard/';

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
