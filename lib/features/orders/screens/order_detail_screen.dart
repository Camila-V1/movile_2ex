// lib/features/orders/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movile_2ex/core/models/order.dart';
import 'package:movile_2ex/core/services/order_service.dart';
import 'package:movile_2ex/shared/utils/app_utils.dart';

// 1. Usamos .family para poder pasar un ID a nuestro provider
final orderDetailsProvider = FutureProvider.family.autoDispose<Order, int>((
  ref,
  orderId,
) async {
  // Llama al método getOrderById de tu servicio
  final orderService = OrderService();
  final order = await orderService.getOrderById(orderId);

  // Mantener el caché mientras la pantalla esté activa
  ref.keepAlive();

  return order;
});

class OrderDetailScreen extends ConsumerWidget {
  final int orderId; // Recibimos el ID del pedido desde el router
  const OrderDetailScreen({super.key, required this.orderId});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'PAID':
        return Colors.green;
      case 'SHIPPED':
        return Colors.teal;
      case 'DELIVERED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pendiente';
      case 'PROCESSING':
        return 'Procesando';
      case 'PAID':
        return 'Pagado';
      case 'SHIPPED':
        return 'Enviado';
      case 'DELIVERED':
        return 'Entregado';
      case 'CANCELLED':
        return 'Cancelado';
      case 'REFUNDED':
        return 'Reembolsado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Observamos el provider pasándole el ID
    final orderAsyncValue = ref.watch(orderDetailsProvider(orderId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #$orderId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(orderDetailsProvider(orderId));
            },
            tooltip: 'Refrescar',
          ),
        ],
      ),
      // 3. Manejamos los estados de carga, error y éxito
      body: orderAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar el pedido',
                  style: textTheme.titleLarge?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(orderDetailsProvider(orderId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (order) {
          // 4. Una vez que tenemos los datos, construimos la vista
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(context, order),
                const SizedBox(height: 24),
                Text('Artículos del Pedido', style: textTheme.titleLarge),
                const Divider(height: 20),
                _buildOrderItemsList(order),
                const SizedBox(height: 24),
                _buildPriceSummary(context, order),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget para la información general del pedido
  Widget _buildOrderSummary(BuildContext context, Order order) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              textTheme,
              Icons.confirmation_number_outlined,
              'Pedido:',
              '#${order.id}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              textTheme,
              Icons.calendar_today,
              'Fecha:',
              AppUtils.formatDate(order.createdAt),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text('Estado: ', style: textTheme.bodyLarge),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (order.paymentMethod.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                textTheme,
                Icons.payment,
                'Método de pago:',
                order.paymentMethod.toUpperCase() == 'STRIPE'
                    ? 'Tarjeta'
                    : 'Monedero',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget para la lista de artículos
  Widget _buildOrderItemsList(Order order) {
    return ListView.separated(
      shrinkWrap: true, // Para que funcione dentro de SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Desactiva scroll anidado
      itemCount: order.items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = order.items[index];

        // Comprobamos si el pedido está en un estado que permite devoluciones
        // Solo se pueden devolver pedidos DELIVERED (entregados)
        final bool canReturn = order.status.toUpperCase() == 'DELIVERED';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.product.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 30),
                      ),
              ),
              const SizedBox(width: 12),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cantidad: ${item.quantity}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    Text(
                      'Precio unitario: ${AppUtils.formatPrice(item.price)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Precio y botón de devolución
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppUtils.formatPrice(item.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  // Solo mostramos el botón si se puede devolver
                  if (canReturn) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        // Navegaremos a la pantalla de solicitud de devolución
                        // Pasaremos el ID de la orden y el ID del *item* (item.id)
                        context.push(
                          '/my-orders/${order.id}/request-return/${item.id}',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        side: const BorderSide(color: Colors.orange),
                        textStyle: const TextStyle(fontSize: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Devolver'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget para el resumen de precios
  Widget _buildPriceSummary(BuildContext context, Order order) {
    final textTheme = Theme.of(context).textTheme;
    // Calcular subtotal e impuestos (asumiendo 10% de impuesto)
    final subtotal = order.total / 1.10;
    final tax = order.total - subtotal;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPriceRow(
              textTheme,
              'Subtotal:',
              AppUtils.formatPrice(subtotal),
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              textTheme,
              'Impuestos (10%):',
              AppUtils.formatPrice(tax),
            ),
            const SizedBox(height: 8),
            _buildPriceRow(textTheme, 'Envío:', 'Gratis'),
            if (order.walletAmountUsed != null &&
                order.walletAmountUsed! > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow(
                textTheme,
                'Monedero usado:',
                '-${AppUtils.formatPrice(order.walletAmountUsed!)}',
                valueColor: Colors.green,
              ),
            ],
            const Divider(height: 24),
            _buildPriceRow(
              textTheme,
              'Total Pagado:',
              AppUtils.formatPrice(order.total),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets de ayuda ---
  Widget _buildInfoRow(
    TextTheme textTheme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Text('$label ', style: textTheme.bodyLarge),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    TextTheme textTheme,
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    final style = isTotal
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style?.copyWith(color: valueColor)),
      ],
    );
  }
}
