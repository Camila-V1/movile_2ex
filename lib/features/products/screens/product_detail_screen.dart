import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Provider para detalle de producto
final productDetailProvider = FutureProvider.family<Product, int>((
  ref,
  productId,
) async {
  final productService = ProductService();
  return await productService.getProductById(productId);
});

/// Pantalla de Detalle de Producto
/// Equivalente a ProductDetail.jsx del proyecto React
class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Producto')),
      body: productAsync.when(
        data: (product) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              AspectRatio(
                aspectRatio: 1,
                child: product.image != null
                    ? CachedNetworkImage(
                        imageUrl: product.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 80,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.shopping_bag, size: 80),
                      ),
              ),

              // Información del producto
              Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría
                    if (product.category != null)
                      Chip(
                        label: Text(product.category!.name),
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    const SizedBox(height: AppTheme.paddingSM),

                    // Nombre
                    Text(product.name, style: AppTheme.heading2),
                    const SizedBox(height: AppTheme.paddingMD),

                    // Rating y reviews
                    if (product.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            product.rating!.toStringAsFixed(1),
                            style: AppTheme.heading3,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${product.reviewCount ?? 0} reseñas)',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppTheme.paddingLG),

                    // Precio
                    Text(
                      product.priceFormatted,
                      style: AppTheme.heading1.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingMD),

                    // Stock
                    Row(
                      children: [
                        Icon(
                          product.isOutOfStock
                              ? Icons.block
                              : product.isLowStock
                              ? Icons.warning_amber
                              : Icons.check_circle,
                          color: product.isOutOfStock
                              ? AppTheme.errorColor
                              : product.isLowStock
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.isOutOfStock
                              ? 'Agotado'
                              : product.isLowStock
                              ? '¡Pocas unidades! (${product.stock} disponibles)'
                              : '${product.stock} disponibles',
                          style: AppTheme.bodyMedium.copyWith(
                            color: product.isOutOfStock
                                ? AppTheme.errorColor
                                : product.isLowStock
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingLG),

                    // Descripción
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const Text('Descripción', style: AppTheme.heading3),
                      const SizedBox(height: AppTheme.paddingSM),
                      Text(product.description!, style: AppTheme.bodyMedium),
                      const SizedBox(height: AppTheme.paddingLG),
                    ],

                    // Información adicional
                    Container(
                      padding: const EdgeInsets.all(AppTheme.paddingMD),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'SKU',
                            value: '#${product.id.toString().padLeft(6, '0')}',
                          ),
                          if (product.createdAt != null) ...[
                            const Divider(height: AppTheme.paddingMD),
                            _InfoRow(
                              label: 'Disponible desde',
                              value: _formatDate(product.createdAt!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(message: 'Cargando producto...'),
        error: (error, stack) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.refresh(productDetailProvider(productId)),
        ),
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMD),
            child: ElevatedButton(
              onPressed: product.isAvailable
                  ? () {
                      // Añadir producto al carrito
                      ref.read(cartProvider.notifier).addItem(product);

                      // Mostrar snackbar de confirmación
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} añadido al carrito'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'Ver Carrito',
                            onPressed: () => context.push('/cart'),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                product.isAvailable ? 'Añadir al Carrito' : 'No Disponible',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }
}

/// Widget para mostrar una fila de información
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
