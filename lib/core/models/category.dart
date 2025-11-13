/// Modelo de Categoría de Productos
class Category {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int? productCount;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.productCount,
  });

  /// Factory constructor para crear Category desde JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      productCount: json['product_count'] as int?,
    );
  }

  /// Convertir Category a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'product_count': productCount,
    };
  }

  /// Crear una copia con campos modificados
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? image,
    int? productCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      productCount: productCount ?? this.productCount,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
