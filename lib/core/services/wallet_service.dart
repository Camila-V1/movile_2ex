import 'package:movile_2ex/core/api/api_constants.dart';
import 'package:movile_2ex/core/api/api_service.dart';
import 'package:movile_2ex/core/models/wallet.dart';

/// Servicio para gestionar operaciones de billetera
class WalletService {
  final ApiService _apiService = ApiService();

  /// Obtiene la billetera del usuario
  /// GET /api/wallet/
  Future<Wallet> getWallet() async {
    try {
      final response = await _apiService.get(ApiConstants.wallet);
      return Wallet.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener la billetera: $e');
    }
  }

  /// Obtiene el saldo de la billetera
  /// GET /api/wallet/balance/
  Future<double> getBalance() async {
    try {
      final response = await _apiService.get(ApiConstants.walletBalance);
      return (response.data['balance'] as num).toDouble();
    } catch (e) {
      throw Exception('Error al obtener el saldo: $e');
    }
  }

  /// Obtiene las transacciones de la billetera
  /// GET /api/wallet/transactions/
  Future<List<WalletTransaction>> getTransactions() async {
    try {
      final response = await _apiService.get(ApiConstants.walletTransactions);
      final List<dynamic> transactionsData = response.data;
      return transactionsData
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las transacciones: $e');
    }
  }

  /// Añade fondos a la billetera
  /// POST /api/wallet/add-funds/
  Future<Wallet> addFunds(double amount) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.wallet}add-funds/',
        data: {'amount': amount},
      );
      return Wallet.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al añadir fondos: $e');
    }
  }
}
