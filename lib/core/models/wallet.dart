/// Modelo de Transacción de Billetera
class WalletTransaction {
  final int id;
  final String transactionType; // 'REFUND', 'PAYMENT', 'ADJUSTMENT'
  final String transactionTypeDisplay;
  final double amount;
  final double balanceAfter;
  final String status; // 'COMPLETED', 'PENDING', 'FAILED'
  final String statusDisplay;
  final String? description;
  final String? referenceId;
  final bool isCredit;
  final bool isDebit;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletTransaction({
    required this.id,
    required this.transactionType,
    required this.transactionTypeDisplay,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    required this.statusDisplay,
    this.description,
    this.referenceId,
    required this.isCredit,
    required this.isDebit,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeLabel => transactionTypeDisplay;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as int,
      transactionType: json['transaction_type'] as String,
      transactionTypeDisplay: json['transaction_type_display'] as String,
      amount: (json['amount'] is String)
          ? double.parse(json['amount'] as String)
          : (json['amount'] as num).toDouble(),
      balanceAfter: (json['balance_after'] is String)
          ? double.parse(json['balance_after'] as String)
          : (json['balance_after'] as num).toDouble(),
      status: json['status'] as String,
      statusDisplay: json['status_display'] as String,
      description: json['description'] as String?,
      referenceId: json['reference_id'] as String?,
      isCredit: json['is_credit'] as bool,
      isDebit: json['is_debit'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_type': transactionType,
      'amount': amount,
      'balance_after': balanceAfter,
      'status': status,
      'description': description,
      'reference_id': referenceId,
      'is_credit': isCredit,
      'is_debit': isDebit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'WalletTransaction(id: $id, type: $transactionType, amount: \$${amount.toStringAsFixed(2)})';
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
