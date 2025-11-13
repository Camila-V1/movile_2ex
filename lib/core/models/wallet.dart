/// Modelo de Transacción de Billetera
class WalletTransaction {
  final int id;
  final String type; // 'credit', 'debit'
  final double amount;
  final String? description;
  final int? orderId;
  final int? returnId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    this.orderId,
    this.returnId,
    required this.createdAt,
  });

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';

  String get typeLabel => isCredit ? 'Crédito' : 'Débito';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as int,
      type: json['type'] as String,
      amount: (json['amount'] is String)
          ? double.parse(json['amount'] as String)
          : (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      orderId: json['order_id'] as int?,
      returnId: json['return_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'order_id': orderId,
      'return_id': returnId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'WalletTransaction(id: $id, type: $type, amount: \$${amount.toStringAsFixed(2)})';
  }
}

/// Modelo de Billetera Virtual
class Wallet {
  final int id;
  final int userId;
  final double balance;
  final DateTime? lastUpdated;
  final List<WalletTransaction>? transactions;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.lastUpdated,
    this.transactions,
  });

  String get balanceFormatted => '\$${balance.toStringAsFixed(2)}';

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final transactionsList = (json['transactions'] as List?)
        ?.map((t) => WalletTransaction.fromJson(t as Map<String, dynamic>))
        .toList();

    return Wallet(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['user'] as int,
      balance: (json['balance'] is String)
          ? double.parse(json['balance'] as String)
          : (json['balance'] as num).toDouble(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      transactions: transactionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'last_updated': lastUpdated?.toIso8601String(),
      'transactions': transactions?.map((t) => t.toJson()).toList(),
    };
  }

  Wallet copyWith({
    int? id,
    int? userId,
    double? balance,
    DateTime? lastUpdated,
    List<WalletTransaction>? transactions,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  String toString() {
    return 'Wallet(id: $id, balance: \$${balance.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
