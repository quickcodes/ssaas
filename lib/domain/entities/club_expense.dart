import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A company-scoped operational expense recorded by a club operator.
class ClubExpense extends Equatable {
  final String id;
  final String companyId;
  final String title;
  final double amount;
  final String category;
  final DateTime expenseDate;
  final String addedBy;
  final String addedById;
  final String paymentMethod;
  final String notes;
  /// Restricts sensitive records (for example salaries) to the club owner.
  final bool isOwnerOnly;
  final DateTime createdAt;

  const ClubExpense({
    required this.id,
    required this.companyId,
    required this.title,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.addedBy,
    required this.addedById,
    required this.paymentMethod,
    this.notes = '',
    this.isOwnerOnly = false,
    required this.createdAt,
  });

  ClubExpense copyWith({
    String? id,
    String? companyId,
    String? title,
    double? amount,
    String? category,
    DateTime? expenseDate,
    String? addedBy,
    String? addedById,
    String? paymentMethod,
    String? notes,
    bool? isOwnerOnly,
    DateTime? createdAt,
  }) {
    return ClubExpense(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      addedBy: addedBy ?? this.addedBy,
      addedById: addedById ?? this.addedById,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isOwnerOnly: isOwnerOnly ?? this.isOwnerOnly,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'title': title,
        'amount': amount,
        'category': category,
        'expenseDate': Timestamp.fromDate(expenseDate),
        'addedBy': addedBy,
        'addedById': addedById,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'isOwnerOnly': isOwnerOnly,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ClubExpense.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ClubExpense(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? 'Other',
      expenseDate: parseDate(map['expenseDate']),
      addedBy: map['addedBy'] as String? ?? '',
      addedById: map['addedById'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      notes: map['notes'] as String? ?? '',
      isOwnerOnly: map['isOwnerOnly'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        title,
        amount,
        category,
        expenseDate,
        addedBy,
        addedById,
        paymentMethod,
        notes,
        isOwnerOnly,
        createdAt,
      ];
}
