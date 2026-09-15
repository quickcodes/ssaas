import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  rent,
  utilities,
  staffSalaries,
  maintenanceRepairs,
  inventorySourcing,
  miscellaneous;

  String get displayName {
    switch (this) {
      case ExpenseCategory.rent:
        return 'Rent & Lease';
      case ExpenseCategory.utilities:
        return 'Electricity & Utilities';
      case ExpenseCategory.staffSalaries:
        return 'Staff Salaries';
      case ExpenseCategory.maintenanceRepairs:
        return 'Maintenance & Repairs';
      case ExpenseCategory.inventorySourcing:
        return 'Inventory Sourcing';
      case ExpenseCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }
}

class ExpenseRecord extends Equatable {
  final String id;
  final String branchId;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String vendorName;
  final String? receiptAttachmentName;
  final String loggedByOperatorId;
  final String loggedByOperatorName;
  final DateTime date;

  const ExpenseRecord({
    required this.id,
    required this.branchId,
    required this.category,
    required this.amount,
    required this.description,
    required this.vendorName,
    this.receiptAttachmentName,
    required this.loggedByOperatorId,
    required this.loggedByOperatorName,
    required this.date,
  });

  ExpenseRecord copyWith({
    String? id,
    String? branchId,
    ExpenseCategory? category,
    double? amount,
    String? description,
    String? vendorName,
    String? receiptAttachmentName,
    String? loggedByOperatorId,
    String? loggedByOperatorName,
    DateTime? date,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      vendorName: vendorName ?? this.vendorName,
      receiptAttachmentName: receiptAttachmentName ?? this.receiptAttachmentName,
      loggedByOperatorId: loggedByOperatorId ?? this.loggedByOperatorId,
      loggedByOperatorName: loggedByOperatorName ?? this.loggedByOperatorName,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        category,
        amount,
        description,
        vendorName,
        receiptAttachmentName,
        loggedByOperatorId,
        loggedByOperatorName,
        date,
      ];
}
