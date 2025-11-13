import 'order.dart';
import 'user.dart';

/// Modelo de Solicitud de Devolución
class ReturnRequest {
  final int id;
  final Order order;
  final User? user;
  final String reason;
  final String? description;
  final String status; // 'pending', 'approved', 'rejected', 'refunded'
  final double refundAmount;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;

  ReturnRequest({
    required this.id,
    required this.order,
    this.user,
    required this.reason,
    this.description,
    required this.status,
    required this.refundAmount,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isRefunded => status == 'refunded';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      case 'refunded':
        return 'Reembolsada';
      default:
        return status;
    }
  }

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'] as int,
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      refundAmount: (json['refund_amount'] is String)
          ? double.parse(json['refund_amount'] as String)
          : (json['refund_amount'] as num).toDouble(),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order.toJson(),
      'user': user?.toJson(),
      'reason': reason,
      'description': description,
      'status': status,
      'refund_amount': refundAmount,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  ReturnRequest copyWith({
    int? id,
    Order? order,
    User? user,
    String? reason,
    String? description,
    String? status,
    double? refundAmount,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
  }) {
    return ReturnRequest(
      id: id ?? this.id,
      order: order ?? this.order,
      user: user ?? this.user,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      refundAmount: refundAmount ?? this.refundAmount,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
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
