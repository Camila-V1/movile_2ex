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
  ///
  /// [paymentMethod] puede ser 'stripe' o 'wallet'
  /// Si es 'wallet', el backend validará y deducirá el saldo automáticamente
  Future<Order> createOrder({
    required List<CartItem> items,
    String paymentMethod = 'stripe', // 'stripe' o 'wallet'
  }) async {
    try {
      // Preparar los items para el backend
      final orderItems = items.map((cartItem) {
        return {
          'product_id': cartItem.product.id,
          'quantity': cartItem.quantity,
        };
      }).toList();

      final response = await _apiService.post(
        ApiConstants.createOrder,
        data: {'items': orderItems, 'payment_method': paymentMethod},
      );

      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear la orden: $e');
    }
  }

  /// Crea un Payment Intent de Stripe para una orden (pago nativo móvil)
  /// POST /api/orders/create-payment-intent/
  Future<String> createPaymentIntent({required int orderId}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createPaymentIntent,
        data: {'order_id': orderId, 'currency': 'usd'},
      );

      // El backend devuelve el client_secret de Stripe
      final clientSecret = response.data['client_secret'] as String?;

      if (clientSecret == null) {
        throw Exception('No se recibió el client_secret del backend');
      }

      return clientSecret;
    } catch (e) {
      throw Exception('Error al crear el payment intent: $e');
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
