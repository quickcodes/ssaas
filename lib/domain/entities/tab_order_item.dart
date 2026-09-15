import 'package:equatable/equatable.dart';

class TabOrderItem extends Equatable {
  final String id;
  final String? sessionId; // null if direct walk-in sale
  final String branchId;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime timestamp;
  final String operatorId;
  final String operatorName;

  const TabOrderItem({
    required this.id,
    this.sessionId,
    required this.branchId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.timestamp,
    required this.operatorId,
    required this.operatorName,
  });

  TabOrderItem copyWith({
    String? id,
    String? sessionId,
    String? branchId,
    String? itemId,
    String? itemName,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    DateTime? timestamp,
    String? operatorId,
    String? operatorName,
  }) {
    return TabOrderItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      branchId: branchId ?? this.branchId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      timestamp: timestamp ?? this.timestamp,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        branchId,
        itemId,
        itemName,
        quantity,
        unitPrice,
        totalAmount,
        timestamp,
        operatorId,
        operatorName,
      ];
}
