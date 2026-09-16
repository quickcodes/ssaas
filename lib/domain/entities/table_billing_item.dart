import 'package:equatable/equatable.dart';

class TableBillingItem extends Equatable {
  final String id;
  final String name;
  final String desc;
  final double price;
  final int quantity;
  final bool isCustom;
  final String? stockItemId;

  const TableBillingItem({
    required this.id,
    required this.name,
    this.desc = '',
    required this.price,
    this.quantity = 1,
    this.isCustom = false,
    this.stockItemId,
  });

  double get totalAmount => price * quantity;

  TableBillingItem copyWith({
    String? id,
    String? name,
    String? desc,
    double? price,
    int? quantity,
    bool? isCustom,
    String? stockItemId,
  }) {
    return TableBillingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isCustom: isCustom ?? this.isCustom,
      stockItemId: stockItemId ?? this.stockItemId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'price': price,
      'quantity': quantity,
      'isCustom': isCustom,
      'stockItemId': stockItemId,
    };
  }

  factory TableBillingItem.fromMap(Map<String, dynamic> map) {
    return TableBillingItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      desc: map['desc'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      isCustom: map['isCustom'] as bool? ?? false,
      stockItemId: map['stockItemId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        desc,
        price,
        quantity,
        isCustom,
        stockItemId,
      ];
}
