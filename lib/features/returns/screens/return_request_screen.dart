// lib/features/returns/screens/return_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movile_2ex/core/models/order.dart';
import 'package:movile_2ex/core/services/return_service.dart';
import 'package:movile_2ex/features/orders/screens/order_detail_screen.dart';
import 'package:movile_2ex/shared/utils/app_utils.dart';

// Mapa de motivos de devolución (texto visible -> valor para backend)
const Map<String, String> kReturnReasons = {
  'Producto defectuoso': 'DEFECTIVE',
  'Producto incorrecto': 'WRONG_ITEM',
  'No es como se describe': 'NOT_AS_DESCRIBED',
  'Cambié de opinión': 'CHANGED_MIND',
  'Otro': 'OTHER',
};

class ReturnRequestScreen extends ConsumerStatefulWidget {
  final int orderId;
  final int orderItemId; // Recibimos el ID del item específico

  const ReturnRequestScreen({
    super.key,
    required this.orderId,
    required this.orderItemId,
  });

  @override
  ConsumerState<ReturnRequestScreen> createState() =>
      _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  String? _selectedReason;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  // Método para enviar el formulario
  Future<void> _submitRequest() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 2. Obtener datos del pedido actual para enviar al backend
      final orderAsyncValue = ref.read(orderDetailsProvider(widget.orderId));
      final order = orderAsyncValue.value;

      if (order == null) {
        throw Exception('No se pudo cargar la información del pedido');
      }

      // Buscar el item específico
      final item = order.items.firstWhere(
        (item) => item.id == widget.orderItemId,
      );

      // 3. Llamar al ReturnService con los parámetros correctos
      final returnService = ReturnService();
      await returnService.createReturnRequest(
        orderId: widget.orderId,
        productId: item.product.id,
        quantity: item.quantity,
        reason: _selectedReason!,
        description: _commentsController.text.isNotEmpty
            ? _commentsController.text
            : null,
      );

      if (!mounted) return;

      // 3. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de devolución enviada con éxito.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // 4. Regresar a la pantalla anterior
      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los detalles del pedido para saber qué producto estamos devolviendo
    final orderAsyncValue = ref.watch(orderDetailsProvider(widget.orderId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Devolución')),
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
              ],
            ),
          ),
        ),
        data: (order) {
          // Buscamos el item específico que el usuario seleccionó
          final item = order.items.firstWhere(
            (item) => item.id == widget.orderItemId,
            orElse: () => order.items.first, // Fallback
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vas a devolver este producto:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProductInfo(item), // Mostramos la info del producto
                  const Divider(height: 32),

                  // --- Formulario de Devolución ---
                  Text(
                    'Motivo de la devolución',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Selecciona un motivo *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: kReturnReasons.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry
                                .value, // Valor para backend (DEFECTIVE, etc.)
                            child: Text(entry.key), // Texto visible al usuario
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedReason = value);
                    },
                    validator: (value) =>
                        value == null ? 'Por favor selecciona un motivo' : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Comentarios (Opcional)',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentsController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Describe el problema con más detalle...',
                      prefixIcon: Icon(Icons.comment),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 32),

                  // --- Botón de Enviar ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isLoading ? 'Enviando...' : 'Enviar Solicitud',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Una vez enviada, podrás ver el estado de tu solicitud en "Mis Devoluciones"',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget para mostrar el producto que se está devolviendo
  Widget _buildProductInfo(OrderItem item) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cantidad: ${item.quantity}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precio: ${AppUtils.formatPrice(item.price)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${AppUtils.formatPrice(item.subtotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
