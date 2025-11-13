import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movile_2ex/shared/constants/app_theme.dart';

/// Pantalla de pago exitoso
/// Equivalente a PaymentSuccess.jsx
class PaymentSuccessScreen extends StatelessWidget {
  final String? orderId;
  final bool paidWithWallet;

  const PaymentSuccessScreen({
    super.key,
    this.orderId,
    this.paidWithWallet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono de éxito
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    paidWithWallet
                        ? Icons.account_balance_wallet
                        : Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  '¡Pago Exitoso!',
                  style: AppTheme.heading1.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mensaje
                Text(
                  paidWithWallet
                      ? 'Tu pedido ha sido pagado con tu billetera virtual.'
                      : 'Tu pedido ha sido procesado correctamente.',
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                if (orderId != null) ...[
                  Text(
                    'Número de orden: $orderId',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: paidWithWallet
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: paidWithWallet ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          paidWithWallet
                              ? 'El saldo se ha deducido de tu billetera. Puedes revisar el historial en "Mi Billetera".'
                              : 'Recibirás un correo de confirmación con los detalles de tu pedido.',
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Botón ir a mis órdenes
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/orders'),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ver Mis Pedidos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón volver al inicio
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home),
                    label: const Text('Volver al Inicio'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
