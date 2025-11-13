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
    // El backend puede enviar 'product' como un ID (int) o como un objeto completo
    final productData = json['product'];
    final Product product;

    if (productData is int) {
      // Si es un int, creamos un Product parcial con los datos disponibles
      product = Product(
        id: productData,
        name: json['product_name'] as String? ?? 'Producto',
        description: json['product_description'] as String?,
        price: (json['price'] is String)
            ? double.parse(json['price'] as String)
            : (json['price'] as num).toDouble(),
        stock: 0,
        imageUrl: json['product_image'] as String?,
        categoryId: json['product_category'] as int?,
      );
    } else if (productData is Map<String, dynamic>) {
      // Si es un Map, usamos fromJson normal
      product = Product.fromJson(productData);
    } else {
      throw Exception('Formato de producto no reconocido en OrderItem');
    }

    return OrderItem(
      id: json['id'] as int,
      product: product,
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
  final bool paidWithWallet; // Indica si se pagó con billetera
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
    this.paidWithWallet = false,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isProcessing => status.toUpperCase() == 'PROCESSING';
  bool get isShipped => status.toUpperCase() == 'SHIPPED';
  bool get isDelivered => status.toUpperCase() == 'DELIVERED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get canBeReturned => isDelivered;

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pendiente';
      case 'PROCESSING':
        return 'Procesando';
      case 'SHIPPED':
        return 'Enviado';
      case 'DELIVERED':
        return 'Entregado';
      case 'CANCELLED':
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

    // El backend puede enviar 'user' como String (username) o como objeto
    final userData = json['user'];
    User? user;

    if (userData is String) {
      // Si es un String, es solo el username
      user = User(
        id: 0, // No tenemos el ID real
        username: userData,
        email: '',
        firstName: userData,
        lastName: '',
        role: 'CLIENT',
      );
    } else if (userData is Map<String, dynamic>) {
      // Si es un Map, usamos fromJson normal
      user = User.fromJson(userData);
    }

    // El backend puede enviar 'total', 'total_price' o 'total_amount'
    double total = 0.0;
    if (json['total'] != null) {
      total = (json['total'] is String)
          ? double.parse(json['total'] as String)
          : (json['total'] as num).toDouble();
    } else if (json['total_price'] != null) {
      total = (json['total_price'] is String)
          ? double.parse(json['total_price'] as String)
          : (json['total_price'] as num).toDouble();
    } else if (json['total_amount'] != null) {
      total = (json['total_amount'] is String)
          ? double.parse(json['total_amount'] as String)
          : (json['total_amount'] as num).toDouble();
    }

    return Order(
      id: json['id'] as int,
      user: user,
      items: itemsList,
      total: total,
      status: (json['status'] as String? ?? 'PENDING').toUpperCase(),
      paymentMethod: json['payment_method'] as String? ?? 'stripe',
      paymentIntentId: json['payment_intent_id'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      walletAmountUsed: json['wallet_amount_used'] != null
          ? (json['wallet_amount_used'] is String)
                ? double.parse(json['wallet_amount_used'] as String)
                : (json['wallet_amount_used'] as num).toDouble()
          : null,
      paidWithWallet: json['paid_with_wallet'] as bool? ?? false,
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
      'paid_with_wallet': paidWithWallet,
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
    bool? paidWithWallet,
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
      paidWithWallet: paidWithWallet ?? this.paidWithWallet,
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
