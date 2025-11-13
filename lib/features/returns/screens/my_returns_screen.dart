import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/return_request.dart';
import '../../../../core/services/return_service.dart';

final myReturnsProvider = FutureProvider.autoDispose<List<ReturnRequest>>((
  ref,
) async {
  final service = ReturnService();
  return service.getMyReturns();
});

class MyReturnsScreen extends ConsumerWidget {
  const MyReturnsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReturns = ref.watch(myReturnsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Devoluciones')),
      body: asyncReturns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: ${err.toString()}')),
        data: (returns) {
          if (returns.isEmpty) {
            return const Center(child: Text('No hay devoluciones.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myReturnsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: returns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = returns[index];
                final productName = r.productDetails?.name ?? 'Producto';

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    title: Text(productName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Motivo: ${r.reasonDisplay}'),
                        Text('Estado: ${r.statusDisplay}'),
                        Text(
                          'Fecha: ${r.createdAt.toLocal().toString().split(" ").first}',
                        ),
                        if (r.description != null && r.description!.isNotEmpty)
                          Text('Comentarios: ${r.description}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Mostrar diálogo con detalle resumido
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Detalle de devolución'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Orden: ${r.orderDetails?.orderNumber ?? "#${r.orderId}"}',
                              ),
                              Text('Producto: $productName'),
                              Text('Cantidad: ${r.quantity}'),
                              Text('Motivo: ${r.reasonDisplay}'),
                              if (r.description != null &&
                                  r.description!.isNotEmpty)
                                Text('Comentarios: ${r.description}'),
                              Text('Estado: ${r.statusDisplay}'),
                              Text(
                                'Reembolso: \$${r.refundAmount.toStringAsFixed(2)}',
                              ),
                              Text('Método: ${r.refundMethodDisplay}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
