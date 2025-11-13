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

  double _walletAmountToUse = 0.0;
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

              // Dirección de envío
              Text('Dirección de Envío', style: AppTheme.heading3),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección completa',
                  hintText: 'Calle, número, ciudad, código postal',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu dirección de envío';
                  }
                  if (value.trim().length < 10) {
                    return 'La dirección es muy corta';
                  }
                  return null;
                },
              ),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleCheckout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
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
                            const Icon(Icons.payment),
                            const SizedBox(width: 8),
                            Text(
                              'Realizar Pago',
                              style: AppTheme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
            if (_walletAmountToUse > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Billetera:',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.green),
                  ),
                  Text(
                    '-${AppUtils.formatPrice(_walletAmountToUse)}',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.green),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: AppTheme.heading3),
                Text(
                  AppUtils.formatPrice(
                    (cartState.totalWithTax - _walletAmountToUse).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green),
                const SizedBox(width: 8),
                Text('Usar Billetera', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Saldo disponible: ${AppUtils.formatPrice(walletBalance)}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
            if (walletBalance > 0) ...[
              const SizedBox(height: 16),
              Slider(
                value: _walletAmountToUse,
                min: 0,
                max: walletBalance.clamp(0, cartState.totalWithTax),
                divisions: 20,
                label: AppUtils.formatPrice(_walletAmountToUse),
                onChanged: (value) {
                  setState(() {
                    _walletAmountToUse = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Usar: ${AppUtils.formatPrice(_walletAmountToUse)}',
                    style: AppTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _walletAmountToUse = walletBalance.clamp(
                          0,
                          cartState.totalWithTax,
                        );
                      });
                    },
                    child: const Text('Usar todo'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sección de método de pago
  Widget _buildPaymentMethodSection() {
    final cartState = ref.read(cartProvider);
    final remainingAmount = cartState.totalWithTax - _walletAmountToUse;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método de Pago', style: AppTheme.heading3),
            const SizedBox(height: 12),
            if (remainingAmount > 0) ...[
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Tarjeta de crédito/débito'),
                subtitle: const Text('Pago seguro con Stripe'),
                contentPadding: EdgeInsets.zero,
              ),
            ] else ...[
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.green,
                ),
                title: const Text('Pago con Billetera'),
                subtitle: const Text(
                  'El pago se cubrirá completamente con tu billetera',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
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
      final shippingAddress = _addressController.text.trim();

      // 1. Crear la orden en el backend
      final order = await _orderService.createOrder(
        items: cartState.items,
        shippingAddress: shippingAddress,
        walletAmountUsed: _walletAmountToUse,
      );

      final remainingAmount = cartState.totalWithTax - _walletAmountToUse;

      // 2. Si el monto restante es > 0, procesar pago con Stripe
      if (remainingAmount > 0) {
        // Obtener el client_secret de Stripe
        final clientSecret = await _orderService.createCheckoutSession(
          orderId: order.id,
          walletAmountUsed: _walletAmountToUse,
        );

        // Inicializar Stripe Payment Sheet
        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            merchantDisplayName: 'SmartSales',
            paymentIntentClientSecret: clientSecret,
            style: ThemeMode.light,
            billingDetails: stripe.BillingDetails(
              address: stripe.Address(
                line1: shippingAddress,
                line2: '',
                city: '',
                state: '',
                postalCode: '',
                country: 'BO',
              ),
            ),
          ),
        );

        // Presentar el Payment Sheet
        await stripe.Stripe.instance.presentPaymentSheet();

        // Si llegamos aquí, el pago fue exitoso
        // Limpiar el carrito
        await ref.read(cartProvider.notifier).clearCart();

        // Navegar a pantalla de éxito
        if (mounted) {
          context.go('/payment-success?orderId=${order.id}');
        }
      } else {
        // Pago completo con billetera
        await ref.read(cartProvider.notifier).clearCart();

        if (mounted) {
          context.go('/payment-success?orderId=${order.id}');
        }
      }
    } on stripe.StripeException catch (e) {
      // Error de Stripe
      if (e.error.code == stripe.FailureCode.Canceled) {
        // Usuario canceló el pago
        if (mounted) {
          context.go('/payment-cancelled');
        }
      } else {
        // Otro error de Stripe
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en el pago: ${e.error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error general
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pedido: $e'),
            backgroundColor: Colors.red,
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
