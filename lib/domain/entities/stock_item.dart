import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum StockCategory {
  equipment,
  food;

  String get displayName {
    switch (this) {
      case StockCategory.equipment:
        return 'Equipment / Stock';
      case StockCategory.food:
        return 'Food & Canteen';
    }
  }
}

class StockItem extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final int stock;
  final String desc;
  final double? price; // Unit selling price (for food/canteen)
  final DateTime? expiryDate;
  final StockCategory category;
  final DateTime createdAt;

  const StockItem({
    required this.id,
    required this.companyId,
    required this.name,
    required this.stock,
    this.desc = '',
    this.price,
    this.expiryDate,
    required this.category,
    required this.createdAt,
  });

  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);

  StockItem copyWith({
    String? id,
    String? companyId,
    String? name,
    int? stock,
    String? desc,
    double? price,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    StockCategory? category,
    DateTime? createdAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      desc: desc ?? this.desc,
      price: price ?? this.price,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'stock': stock,
      'desc': desc,
      'price': price,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'category': category.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StockItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final catStr = map['category'] as String? ?? 'equipment';
    final category = catStr == 'food' ? StockCategory.food : StockCategory.equipment;

    return StockItem(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      desc: map['desc'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble(),
      expiryDate: parseDate(map['expiryDate']),
      category: category,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        stock,
        desc,
        price,
        expiryDate,
        category,
        createdAt,
      ];
}
