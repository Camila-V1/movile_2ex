import 'category.dart';

/// Modelo de Producto
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final Category? category;
  final int? categoryId;
  final double? rating;
  final int? reviewCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.category,
    this.categoryId,
    this.rating,
    this.reviewCount,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => stock > 0 && isActive;
  bool get isLowStock => stock > 0 && stock <= 5;
  bool get isOutOfStock => stock == 0;

  String get priceFormatted => '\$${price.toStringAsFixed(2)}';

  /// Factory constructor para crear Product desde JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] is String)
          ? double.parse(json['price'] as String)
          : (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      imageUrl: json['image_url'] as String?,
      // Leer category_details (Map) en lugar de category (int)
      category:
          json['category_details'] != null && json['category_details'] is Map
          ? Category.fromJson(json['category_details'] as Map<String, dynamic>)
          : null,
      // El backend devuelve 'category' como int (ID)
      categoryId: json['category'] is int
          ? json['category'] as int
          : json['category_id'] as int?,
      rating: json['rating'] != null
          ? (json['rating'] is String)
                ? double.parse(json['rating'] as String)
                : (json['rating'] as num).toDouble()
          : null,
      reviewCount: json['review_count'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convertir Product a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'category': category?.toJson(),
      'category_id': categoryId,
      'rating': rating,
      'review_count': reviewCount,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crear una copia con campos modificados
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? imageUrl,
    Category? category,
    int? categoryId,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
