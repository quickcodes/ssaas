import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PaymentTransaction extends Equatable {
  final String id;
  final double amount;
  final String paymentMethod; // "Cash", "UPI", "Card"
  final DateTime receivedAt;
  final String receivedBy;
  final String? notes;

  const PaymentTransaction({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.receivedAt,
    required this.receivedBy,
    this.notes,
  });

  PaymentTransaction copyWith({
    String? id,
    double? amount,
    String? paymentMethod,
    DateTime? receivedAt,
    String? receivedBy,
    String? notes,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedBy: receivedBy ?? this.receivedBy,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'receivedAt': Timestamp.fromDate(receivedAt),
      'receivedBy': receivedBy,
      if (notes != null) 'notes': notes,
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PaymentTransaction(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      receivedAt: parseDate(map['receivedAt']),
      receivedBy: map['receivedBy'] as String? ?? 'Staff',
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        paymentMethod,
        receivedAt,
        receivedBy,
        notes,
      ];
}
