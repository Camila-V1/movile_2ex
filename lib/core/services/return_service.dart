// lib/core/services/return_service.dart
import 'package:movile_2ex/core/api/api_constants.dart';
import 'package:movile_2ex/core/api/api_service.dart';
import 'package:movile_2ex/core/models/return_request.dart';

/// Servicio para gestionar solicitudes de devolución
class ReturnService {
  final ApiService _apiService = ApiService();

  /// Crea una nueva solicitud de devolución
  /// POST /api/deliveries/returns/
  Future<ReturnRequest> createReturnRequest({
    required int orderId,
    required int productId,
    required int quantity,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.returns,
        data: {
          'order_id': orderId,
          'product_id': productId,
          'quantity': quantity,
          'reason': reason,
          'description': description ?? '',
        },
      );

      // El backend devuelve la solicitud de devolución creada
      return ReturnRequest.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear la solicitud de devolución: $e');
    }
  }

  /// Obtiene todas las solicitudes de devolución del usuario
  /// GET /api/returns/
  Future<List<ReturnRequest>> getMyReturns() async {
    try {
      final response = await _apiService.get(ApiConstants.returns);

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ReturnRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las devoluciones: $e');
    }
  }

  /// Obtiene el detalle de una solicitud de devolución específica
  /// GET /api/returns/{id}/
  Future<ReturnRequest> getReturnDetail(int returnId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.returnDetail(returnId),
      );

      return ReturnRequest.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener el detalle de la devolución: $e');
    }
  }

  /// Cancela una solicitud de devolución (solo si está pendiente)
  /// DELETE /api/returns/{id}/
  Future<void> cancelReturn(int returnId) async {
    try {
      await _apiService.delete(ApiConstants.returnDetail(returnId));
    } catch (e) {
      throw Exception('Error al cancelar la devolución: $e');
    }
  }
}
