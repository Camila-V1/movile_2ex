/// Modelo de Solicitud de Devolución - Sistema Simplificado

/// Detalles del producto en la devolución
class ProductDetails {
  final int id;
  final String name;
  final double price;
  final String category;

  ProductDetails({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] is String)
          ? double.parse(json['price'] as String)
          : (json['price'] as num).toDouble(),
      category: json['category'] as String,
    );
  }
}

/// Detalles de la orden en la devolución
class OrderDetails {
  final int id;
  final String orderNumber;
  final DateTime orderDate;
  final double totalPrice;
  final String status;

  OrderDetails({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.totalPrice,
    required this.status,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      totalPrice: (json['total_price'] is String)
          ? double.parse(json['total_price'] as String)
          : (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}

/// Detalles del cliente en la devolución
class CustomerDetails {
  final int id;
  final String username;
  final String email;
  final String fullName;

  CustomerDetails({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
    );
  }
}

/// Modelo de Solicitud de Devolución - Sistema Simplificado
class ReturnRequest {
  final int id;
  final int orderId;
  final int productId;
  final int userId;
  final int quantity;
  final String reason;
  final String reasonDisplay;
  final String? description;
  final String
  status; // REQUESTED, IN_EVALUATION, APPROVED, REJECTED, COMPLETED
  final String statusDisplay;
  final double refundAmount;
  final String refundMethod; // WALLET, ORIGINAL, BANK
  final String refundMethodDisplay;
  final String? evaluationNotes;
  final String? managerNotes;

  // Detalles anidados del backend
  final ProductDetails? productDetails;
  final OrderDetails? orderDetails;
  final CustomerDetails? customerDetails;

  // Timestamps
  final DateTime? requestedAt;
  final DateTime? evaluatedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.reason,
    required this.reasonDisplay,
    this.description,
    required this.status,
    required this.statusDisplay,
    required this.refundAmount,
    required this.refundMethod,
    required this.refundMethodDisplay,
    this.evaluationNotes,
    this.managerNotes,
    this.productDetails,
    this.orderDetails,
    this.customerDetails,
    this.requestedAt,
    this.evaluatedAt,
    this.processedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRequested => status == 'REQUESTED';
  bool get isInEvaluation => status == 'IN_EVALUATION';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isCompleted => status == 'COMPLETED';

  String get statusLabel => statusDisplay;

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'] as int,
      orderId: json['order'] as int,
      productId: json['product'] as int,
      userId: json['user'] as int,
      quantity: json['quantity'] as int,
      reason: json['reason'] as String,
      reasonDisplay: json['reason_display'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      statusDisplay: json['status_display'] as String,
      refundAmount: (json['refund_amount'] is String)
          ? double.parse(json['refund_amount'] as String)
          : (json['refund_amount'] as num).toDouble(),
      refundMethod: json['refund_method'] as String,
      refundMethodDisplay: json['refund_method_display'] as String,
      evaluationNotes: json['evaluation_notes'] as String?,
      managerNotes: json['manager_notes'] as String?,
      productDetails: json['product_details'] != null
          ? ProductDetails.fromJson(
              json['product_details'] as Map<String, dynamic>,
            )
          : null,
      orderDetails: json['order_details'] != null
          ? OrderDetails.fromJson(json['order_details'] as Map<String, dynamic>)
          : null,
      customerDetails: json['customer_details'] != null
          ? CustomerDetails.fromJson(
              json['customer_details'] as Map<String, dynamic>,
            )
          : null,
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String)
          : null,
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.parse(json['evaluated_at'] as String)
          : null,
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'product': productId,
      'user': userId,
      'quantity': quantity,
      'reason': reason,
      'description': description,
      'status': status,
      'refund_amount': refundAmount,
      'refund_method': refundMethod,
      'evaluation_notes': evaluationNotes,
      'manager_notes': managerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReturnRequest copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? userId,
    int? quantity,
    String? reason,
    String? reasonDisplay,
    String? description,
    String? status,
    String? statusDisplay,
    double? refundAmount,
    String? refundMethod,
    String? refundMethodDisplay,
    String? evaluationNotes,
    String? managerNotes,
    ProductDetails? productDetails,
    OrderDetails? orderDetails,
    CustomerDetails? customerDetails,
    DateTime? requestedAt,
    DateTime? evaluatedAt,
    DateTime? processedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReturnRequest(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      reasonDisplay: reasonDisplay ?? this.reasonDisplay,
      description: description ?? this.description,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      refundAmount: refundAmount ?? this.refundAmount,
      refundMethod: refundMethod ?? this.refundMethod,
      refundMethodDisplay: refundMethodDisplay ?? this.refundMethodDisplay,
      evaluationNotes: evaluationNotes ?? this.evaluationNotes,
      managerNotes: managerNotes ?? this.managerNotes,
      productDetails: productDetails ?? this.productDetails,
      orderDetails: orderDetails ?? this.orderDetails,
      customerDetails: customerDetails ?? this.customerDetails,
      requestedAt: requestedAt ?? this.requestedAt,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReturnRequest(id: $id, status: $status, amount: \$${refundAmount.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReturnRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
