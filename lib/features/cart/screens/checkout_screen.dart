import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:go_router/go_router.dart';
import 'package:movile_2ex/core/providers/cart_provider.dart';
import 'package:movile_2ex/core/services/order_service.dart';
import 'package:movile_2ex/core/services/wallet_service.dart';
import 'package:movile_2ex/shared/constants/app_theme.dart';
import 'package:movile_2ex/shared/utils/app_utils.dart';

/// Provider para el saldo de la billetera
final walletBalanceProvider = FutureProvider<double>((ref) async {
  try {
    final walletService = WalletService();
    return await walletService.getBalance();
  } catch (e) {
    return 0.0;
  }
});

/// Pantalla de Checkout
/// Equivalente a Checkout.jsx
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _orderService = OrderService();

  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final walletBalanceAsync = ref.watch(walletBalanceProvider);

    // Si el carrito está vacío, redirigir
    if (cartState.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/cart');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen del pedido
              _buildOrderSummary(cartState),
              const SizedBox(height: 24),

              // Opciones de pago con billetera
              walletBalanceAsync.when(
                data: (walletBalance) =>
                    _buildWalletSection(walletBalance, cartState),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Método de pago
              _buildPaymentMethodSection(),
              const SizedBox(height: 32),

              // Botón de pago
              walletBalanceAsync.when(
                data: (walletBalance) {
                  final canPayWithWallet =
                      walletBalance >= cartState.totalWithTax;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleCheckout,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: canPayWithWallet
                            ? Colors.green
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  canPayWithWallet
                                      ? Icons.account_balance_wallet
                                      : Icons.credit_card,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  canPayWithWallet
                                      ? 'Pagar con Billetera'
                                      : 'Pagar con Tarjeta',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
                loading: () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleCheckout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card),
                        const SizedBox(width: 8),
                        Text(
                          'Pagar con Tarjeta',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resumen del pedido
  Widget _buildOrderSummary(CartState cartState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen del Pedido', style: AppTheme.heading3),
            const SizedBox(height: 16),
            ...cartState.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.name} x${item.quantity}',
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      AppUtils.formatPrice(item.subtotal),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: AppTheme.bodyMedium),
                Text(
                  AppUtils.formatPrice(cartState.total),
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Impuestos (10%):', style: AppTheme.bodyMedium),
                Text(
                  AppUtils.formatPrice(cartState.tax),
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: AppTheme.heading3),
                Text(
                  AppUtils.formatPrice(cartState.totalWithTax),
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de billetera
  Widget _buildWalletSection(double walletBalance, CartState cartState) {
    final bool canPayWithWallet = walletBalance >= cartState.totalWithTax;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: canPayWithWallet ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text('Billetera Virtual', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo disponible:',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  AppUtils.formatPrice(walletBalance),
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: canPayWithWallet ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a pagar:',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  AppUtils.formatPrice(cartState.totalWithTax),
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (canPayWithWallet) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Puedes pagar con tu billetera!',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.green[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saldo insuficiente. Necesitas ${AppUtils.formatPrice(cartState.totalWithTax - walletBalance)} más.',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sección de método de pago
  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método de Pago', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Text(
              'Al confirmar el pago, se utilizará automáticamente el método apropiado según tu saldo de billetera.',
              style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.green,
              ),
              title: const Text('Billetera Virtual'),
              subtitle: const Text('Pago instantáneo con tu saldo'),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Tarjeta de crédito/débito'),
              subtitle: const Text('Pago seguro con Stripe'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  /// Maneja el proceso de checkout
  Future<void> _handleCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cartState = ref.read(cartProvider);
      final walletService = WalletService();

      // Determinar método de pago basado en saldo de billetera
      final walletBalance = await walletService.getBalance();
      final totalAmount = cartState.totalWithTax;
      final bool payWithWallet = walletBalance >= totalAmount;

      // Validar saldo si se intenta pagar con billetera
      if (payWithWallet) {
        final hasEnough = await walletService.hasEnoughBalance(totalAmount);
        if (!hasEnough) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Saldo insuficiente. Necesitas ${AppUtils.formatPrice(totalAmount)}, tienes ${AppUtils.formatPrice(walletBalance)}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Crear la orden con el método de pago apropiado
      final order = await _orderService.createOrder(
        items: cartState.items,
        paymentMethod: payWithWallet ? 'wallet' : 'stripe',
      );

      // Si se pagó con billetera, el backend ya procesó todo
      if (order.paidWithWallet || order.status.toUpperCase() == 'PAID') {
        // Limpiar carrito
        await ref.read(cartProvider.notifier).clearCart();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Pago exitoso con billetera!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go(
            '/payment-success?orderId=${order.id}&paidWithWallet=true',
          );
        }
        return;
      }

      // Si NO se pagó con billetera, procesar con Stripe
      final clientSecret = await _orderService.createPaymentIntent(
        orderId: order.id,
      );

      // Inicializar la hoja de pago de Stripe
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Smart Sales',
          style: ThemeMode.light,
        ),
      );

      // Mostrar la hoja de pago nativa
      await stripe.Stripe.instance.presentPaymentSheet();

      // Si llegamos aquí, el pago con Stripe fue exitoso
      await ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pago exitoso!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/payment-success?orderId=${order.id}');
      }
    } on stripe.StripeException catch (e) {
      // Error de Stripe
      if (e.error.code == stripe.FailureCode.Canceled) {
        // Usuario canceló el pago
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Pago cancelado')));
        }
      } else {
        // Otro error de Stripe
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error de pago: ${e.error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error general (incluye errores de backend como "Saldo insuficiente")
      if (mounted) {
        final errorMessage = e.toString();
        // Extraer mensaje del backend si está presente
        String displayMessage = 'Error al procesar el pedido';
        if (errorMessage.contains('Saldo insuficiente')) {
          displayMessage = errorMessage.replaceAll(
            'Exception: Error al crear la orden: ',
            '',
          );
        } else if (errorMessage.contains('Stock insuficiente')) {
          displayMessage = errorMessage.replaceAll(
            'Exception: Error al crear la orden: ',
            '',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
