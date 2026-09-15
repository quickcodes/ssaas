import 'package:equatable/equatable.dart';

enum CanteenCategory {
  beverages,
  snacks,
  accessories,
  cueCare;

  String get displayName {
    switch (this) {
      case CanteenCategory.beverages:
        return 'Beverages & Drinks';
      case CanteenCategory.snacks:
        return 'Snacks & Quick Bites';
      case CanteenCategory.accessories:
        return 'Chalk & Accessories';
      case CanteenCategory.cueCare:
        return 'Cue Care & Rentals';
    }
  }
}

class CanteenItem extends Equatable {
  final String id;
  final String branchId;
  final String name;
  final CanteenCategory category;
  final double unitPrice;
  final double costPrice;
  final int stockQuantity;
  final int minThreshold;
  final String unit;

  const CanteenItem({
    required this.id,
    required this.branchId,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.costPrice,
    required this.stockQuantity,
    this.minThreshold = 10,
    this.unit = 'pcs',
  });

  bool get isLowStock => stockQuantity <= minThreshold;

  CanteenItem copyWith({
    String? id,
    String? branchId,
    String? name,
    CanteenCategory? category,
    double? unitPrice,
    double? costPrice,
    int? stockQuantity,
    int? minThreshold,
    String? unit,
  }) {
    return CanteenItem(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minThreshold: minThreshold ?? this.minThreshold,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        name,
        category,
        unitPrice,
        costPrice,
        stockQuantity,
        minThreshold,
        unit,
      ];
}
