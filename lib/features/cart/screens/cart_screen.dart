import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movile_2ex/core/providers/cart_provider.dart';
import 'package:movile_2ex/core/models/cart_item.dart';
import 'package:movile_2ex/shared/constants/app_theme.dart';
import 'package:movile_2ex/shared/utils/app_utils.dart';

/// Pantalla del carrito de compras
/// Equivalente a Cart.jsx
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showClearCartDialog(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Vaciar'),
            ),
        ],
      ),
      body: cartState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartState.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartContent(context, ref, cartState),
    );
  }

  /// Vista cuando el carrito está vacío
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Tu carrito está vacío',
            style: AppTheme.heading2.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Ir a Comprar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido principal del carrito
  Widget _buildCartContent(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    return Column(
      children: [
        // Lista de items
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cartState.items.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = cartState.items[index];
              return _CartItemCard(item: item);
            },
          ),
        ),

        // Resumen y botón de checkout
        _buildCartSummary(context, ref, cartState),
      ],
    );
  }

  /// Resumen del carrito con totales
  Widget _buildCartSummary(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: AppTheme.bodyLarge),
                Text(
                  AppUtils.formatPrice(cartState.total),
                  style: AppTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Impuestos
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

            // Total
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
            const SizedBox(height: 16),

            // Botón de checkout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment),
                    const SizedBox(width: 8),
                    Text(
                      'Proceder al Pago',
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
    );
  }

  /// Diálogo de confirmación para vaciar el carrito
  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar Carrito'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los productos del carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}

/// Widget de tarjeta de item del carrito
class _CartItemCard extends ConsumerWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen del producto
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.product.image != null
              ? CachedNetworkImage(
                  imageUrl: item.product.image!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                )
              : Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40),
                ),
        ),
        const SizedBox(width: 16),

        // Detalles del producto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre y precio
              Text(
                item.product.name,
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                AppUtils.formatPrice(item.product.price),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Controles de cantidad en una fila compacta
              Row(
                children: [
                  // Botón decrementar
                  InkWell(
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .decrementQuantity(item.product.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.remove_circle_outline,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),

                  // Cantidad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Botón incrementar
                  InkWell(
                    onTap: () {
                      if (item.quantity < item.product.stock) {
                        ref
                            .read(cartProvider.notifier)
                            .incrementQuantity(item.product.id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No hay más stock disponible'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Botón eliminar
                  InkWell(
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .removeItem(item.product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.product.name} eliminado'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'Deshacer',
                            onPressed: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .addItem(
                                    item.product,
                                    quantity: item.quantity,
                                  );
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Subtotal
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppUtils.formatPrice(item.subtotal),
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
