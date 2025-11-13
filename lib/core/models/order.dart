import 'product.dart';
import 'user.dart';

/// Modelo de Item de Orden
class OrderItem {
  final int id;
  final Product product;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      price: (json['price'] is String)
          ? double.parse(json['price'] as String)
          : (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
    };
  }
}

/// Modelo de Orden
class Order {
  final int id;
  final User? user;
  final List<OrderItem> items;
  final double total;
  final String
  status; // 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  final String paymentMethod; // 'stripe', 'wallet'
  final String? paymentIntentId;
  final String? trackingNumber;
  final double? walletAmountUsed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    this.user,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.paymentIntentId,
    this.trackingNumber,
    this.walletAmountUsed,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get canBeReturned => isDelivered;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'processing':
        return 'Procesando';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList =
        (json['items'] as List?)
            ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return Order(
      id: json['id'] as int,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      items: itemsList,
      total: (json['total'] is String)
          ? double.parse(json['total'] as String)
          : (json['total'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String? ?? 'stripe',
      paymentIntentId: json['payment_intent_id'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      walletAmountUsed: json['wallet_amount_used'] != null
          ? (json['wallet_amount_used'] is String)
                ? double.parse(json['wallet_amount_used'] as String)
                : (json['wallet_amount_used'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'payment_method': paymentMethod,
      'payment_intent_id': paymentIntentId,
      'tracking_number': trackingNumber,
      'wallet_amount_used': walletAmountUsed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    int? id,
    User? user,
    List<OrderItem>? items,
    double? total,
    String? status,
    String? paymentMethod,
    String? paymentIntentId,
    String? trackingNumber,
    double? walletAmountUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      user: user ?? this.user,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      walletAmountUsed: walletAmountUsed ?? this.walletAmountUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, status: $status, total: \$${total.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
