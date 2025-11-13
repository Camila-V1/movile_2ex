import 'package:movile_2ex/core/models/product.dart';

/// Representa un ítem en el carrito de compras
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  /// Calcula el subtotal (precio * cantidad)
  double get subtotal => product.price * quantity;

  /// Crea un CartItem desde JSON (para persistencia)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
    );
  }

  /// Convierte el CartItem a JSON (para persistencia)
  Map<String, dynamic> toJson() {
    return {'product': product.toJson(), 'quantity': quantity};
  }

  /// Crea una copia con valores actualizados
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.product.id == product.id;
  }

  @override
  int get hashCode => product.id.hashCode;

  @override
  String toString() {
    return 'CartItem(product: ${product.name}, quantity: $quantity, subtotal: \$${subtotal.toStringAsFixed(2)})';
  }
}
