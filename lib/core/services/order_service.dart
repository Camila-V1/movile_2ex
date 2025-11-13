import 'package:movile_2ex/core/api/api_constants.dart';
import 'package:movile_2ex/core/api/api_service.dart';
import 'package:movile_2ex/core/models/order.dart';
import 'package:movile_2ex/core/models/cart_item.dart';

/// Servicio para gestionar operaciones de órdenes
/// Equivalente a orderService en api.js
class OrderService {
  final ApiService _apiService = ApiService();

  /// Crea una nueva orden a partir de los items del carrito
  /// POST /api/orders/create/
  Future<Order> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    double walletAmountUsed = 0.0,
  }) async {
    try {
      // Preparar los items para el backend
      final orderItems = items.map((cartItem) {
        return {
          'product_id': cartItem.product.id,
          'quantity': cartItem.quantity,
          'price': cartItem.product.price,
        };
      }).toList();

      // Calcular totales
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + item.subtotal,
      );
      final tax = subtotal * 0.10;
      final total = subtotal + tax;

      final response = await _apiService.post(
        ApiConstants.createOrder,
        data: {
          'items': orderItems,
          'shipping_address': shippingAddress,
          'subtotal': subtotal,
          'tax': tax,
          'total': total,
          'wallet_amount_used': walletAmountUsed,
          'payment_method': walletAmountUsed >= total ? 'wallet' : 'stripe',
        },
      );

      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear la orden: $e');
    }
  }

  /// Crea una sesión de checkout de Stripe para una orden
  /// POST /api/orders/{id}/create-checkout-session/
  Future<String> createCheckoutSession({
    required int orderId,
    double walletAmountUsed = 0.0,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.orderDetail(orderId)}create-checkout-session/',
        data: {'wallet_amount_used': walletAmountUsed},
      );

      // El backend devuelve el client_secret de Stripe
      final clientSecret = response.data['client_secret'] as String?;

      if (clientSecret == null) {
        throw Exception('No se recibió el client_secret del backend');
      }

      return clientSecret;
    } catch (e) {
      throw Exception('Error al crear la sesión de pago: $e');
    }
  }

  /// Obtiene el historial de órdenes del usuario
  /// GET /api/orders/my-orders/
  Future<List<Order>> getMyOrders() async {
    try {
      final response = await _apiService.get(ApiConstants.myOrders);
      final List<dynamic> ordersData = response.data;
      return ordersData.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener las órdenes: $e');
    }
  }

  /// Obtiene los detalles de una orden específica
  /// GET /api/orders/{id}/
  Future<Order> getOrderById(int orderId) async {
    try {
      final response = await _apiService.get(ApiConstants.orderDetail(orderId));
      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener la orden: $e');
    }
  }

  /// Confirma el pago de una orden (webhook de Stripe)
  /// POST /api/payments/confirm/
  Future<void> confirmPayment({
    required int orderId,
    required String paymentIntentId,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.confirmPayment,
        data: {'order_id': orderId, 'payment_intent_id': paymentIntentId},
      );
    } catch (e) {
      throw Exception('Error al confirmar el pago: $e');
    }
  }

  /// Obtiene el estado de un pago
  /// GET /api/payments/status/?payment_intent_id={id}
  Future<Map<String, dynamic>> getPaymentStatus(String paymentIntentId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.paymentStatus}?payment_intent_id=$paymentIntentId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener el estado del pago: $e');
    }
  }

  /// Cancela una orden (si está permitido)
  /// DELETE /api/orders/{id}/
  Future<void> cancelOrder(int orderId) async {
    try {
      await _apiService.delete(ApiConstants.orderDetail(orderId));
    } catch (e) {
      throw Exception('Error al cancelar la orden: $e');
    }
  }
}
