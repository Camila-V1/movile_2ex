class Recommendation {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final double averageRating;
  final int reviewCount;
  final int stock;
  final String categoryName;
  final double? recommendationScore; // Score de ML (0-1)
  final String? recommendationReason; // Por qué se recomienda

  Recommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.averageRating,
    required this.reviewCount,
    required this.stock,
    required this.categoryName,
    this.recommendationScore,
    this.recommendationReason,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'],
      averageRating: json['average_rating'] != null
          ? double.parse(json['average_rating'].toString())
          : 0.0,
      reviewCount: json['review_count'] ?? 0,
      stock: json['stock'] ?? 0,
      categoryName: json['category_name'] ?? '',
      recommendationScore: json['recommendation_score'] != null
          ? double.parse(json['recommendation_score'].toString())
          : null,
      recommendationReason: json['recommendation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'stock': stock,
      'category_name': categoryName,
      'recommendation_score': recommendationScore,
      'recommendation_reason': recommendationReason,
    };
  }

  // Getters útiles
  bool get isInStock => stock > 0;
  bool get isHighlyRated => averageRating >= 4.0;
  String get priceFormatted => '\$${price.toStringAsFixed(2)}';

  String get recommendationReasonDisplay {
    if (recommendationReason != null) return recommendationReason!;
    if (recommendationScore != null && recommendationScore! >= 0.8) {
      return 'Altamente recomendado para ti';
    }
    if (isHighlyRated) return 'Producto mejor valorado';
    return 'Recomendado';
  }
}
