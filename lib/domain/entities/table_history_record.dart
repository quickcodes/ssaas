import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'table_billing_item.dart';

class TableHistoryRecord extends Equatable {
  final String id;
  final String companyId;
  final String tableId;
  final String tableName;
  final String customerName;
  final String startedByName;
  final String closedByName;
  final DateTime startedAt;
  final DateTime closedAt;
  final int durationMinutes;
  final double tableAmount;
  final double itemsAmount;
  final double totalAmount;
  final String paymentStatus; // "Received" or "Due"
  final String? paymentMethod; // "Cash", "UPI", "Card"
  final List<TableBillingItem> items;
  final DateTime createdAt;

  const TableHistoryRecord({
    required this.id,
    required this.companyId,
    required this.tableId,
    required this.tableName,
    required this.customerName,
    required this.startedByName,
    required this.closedByName,
    required this.startedAt,
    required this.closedAt,
    required this.durationMinutes,
    required this.tableAmount,
    required this.itemsAmount,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.items = const [],
    required this.createdAt,
  });

  bool get isDue => paymentStatus.toLowerCase() == 'due';
  bool get isReceived => paymentStatus.toLowerCase() == 'received';

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'tableId': tableId,
      'tableName': tableName,
      'customerName': customerName,
      'startedByName': startedByName,
      'closedByName': closedByName,
      'startedAt': Timestamp.fromDate(startedAt),
      'closedAt': Timestamp.fromDate(closedAt),
      'durationMinutes': durationMinutes,
      'tableAmount': tableAmount,
      'itemsAmount': itemsAmount,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TableHistoryRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => TableBillingItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return TableHistoryRecord(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      tableId: map['tableId'] as String? ?? '',
      tableName: map['tableName'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      startedByName: map['startedByName'] as String? ?? '',
      closedByName: map['closedByName'] as String? ?? '',
      startedAt: parseDate(map['startedAt']),
      closedAt: parseDate(map['closedAt']),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      tableAmount: (map['tableAmount'] as num?)?.toDouble() ?? 0.0,
      itemsAmount: (map['itemsAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] as String? ?? 'Received',
      paymentMethod: map['paymentMethod'] as String?,
      items: items,
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        tableId,
        tableName,
        customerName,
        startedByName,
        closedByName,
        startedAt,
        closedAt,
        durationMinutes,
        tableAmount,
        itemsAmount,
        totalAmount,
        paymentStatus,
        paymentMethod,
        items,
        createdAt,
      ];
}
