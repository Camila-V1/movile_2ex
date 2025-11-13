import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/wallet.dart';
import '../../../core/services/wallet_service.dart';

/// Provider para obtener el saldo de la billetera
final walletBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final service = WalletService();
  return service.getBalance();
});

/// Provider para obtener las transacciones
final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>((ref) async {
      final service = WalletService();
      return service.getTransactions();
    });

class MyWalletScreen extends ConsumerWidget {
  const MyWalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Billetera'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(walletBalanceProvider);
              ref.invalidate(walletTransactionsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tarjeta de saldo
          balanceAsync.when(
            loading: () => const _BalanceCardLoading(),
            error: (err, st) => _BalanceCardError(error: err.toString()),
            data: (balance) => _BalanceCard(balance: balance),
          ),

          const SizedBox(height: 16),

          // Título de historial
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historial de Transacciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Lista de transacciones
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: ${err.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(walletTransactionsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No hay transacciones aún'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(walletTransactionsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _TransactionTile(transaction: transaction);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de la tarjeta de saldo
class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Saldo Disponible',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de carga para la tarjeta de saldo
class _BalanceCardLoading extends StatelessWidget {
  const _BalanceCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Cargando...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          CircularProgressIndicator(color: Colors.white),
        ],
      ),
    );
  }
}

/// Widget de error para la tarjeta de saldo
class _BalanceCardError extends StatelessWidget {
  final String error;

  const _BalanceCardError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Error al cargar saldo',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }
}

/// Widget para cada transacción
class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  IconData _getIcon() {
    if (transaction.isCredit) {
      return Icons.add_circle_outline;
    } else {
      return Icons.remove_circle_outline;
    }
  }

  Color _getColor() {
    if (transaction.isCredit) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  String _getFormattedAmount() {
    final sign = transaction.isCredit ? '+' : '-';
    return '$sign\$${transaction.amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _getColor().withOpacity(0.1),
        child: Icon(_getIcon(), color: _getColor()),
      ),
      title: Text(
        transaction.description ?? transaction.typeLabel,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        transaction.createdAt.toLocal().toString().split('.').first,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        _getFormattedAmount(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _getColor(),
        ),
      ),
    );
  }
}
