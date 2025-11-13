import 'product.dart';

/// Modelo de Item del Carrito
class CartItem {
  final int id;
  final Product product;
  final int quantity;
  final double price; // Precio al momento de añadir al carrito
  final DateTime? addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    this.addedAt,
  });

  double get subtotal => price * quantity;

  /// Factory constructor para crear CartItem desde JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      price: (json['price'] is String)
          ? double.parse(json['price'] as String)
          : (json['price'] as num).toDouble(),
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : null,
    );
  }

  /// Convertir CartItem a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'added_at': addedAt?.toIso8601String(),
    };
  }

  /// Crear una copia con campos modificados
  CartItem copyWith({
    int? id,
    Product? product,
    int? quantity,
    double? price,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, product: ${product.name}, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modelo del Carrito completo
class Cart {
  final List<CartItem> items;
  final double total;
  final int itemCount;

  Cart({required this.items, required this.total, required this.itemCount});

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Factory constructor para crear Cart desde JSON
  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList =
        (json['items'] as List?)
            ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return Cart(
      items: itemsList,
      total: (json['total'] is String)
          ? double.parse(json['total'] as String)
          : (json['total'] as num?)?.toDouble() ?? 0.0,
      itemCount: json['item_count'] as int? ?? itemsList.length,
    );
  }

  /// Convertir Cart a JSON
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'item_count': itemCount,
    };
  }

  /// Cart vacío
  factory Cart.empty() {
    return Cart(items: [], total: 0.0, itemCount: 0);
  }

  @override
  String toString() {
    return 'Cart(items: ${items.length}, total: \$${total.toStringAsFixed(2)})';
  }
}
