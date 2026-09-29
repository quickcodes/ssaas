import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/constants.dart';
import 'payment_transaction.dart';
import 'table_billing_item.dart';

class TableHistoryRecord extends Equatable {
  final String id;
  final String companyId;
  final String tableId;
  final String tableName;
  final String customerName;
  final String customerPhone;
  final String startedByName;
  final String closedByName;
  final DateTime startedAt;
  final DateTime closedAt;
  final int durationMinutes;
  final double tableAmount;
  final double itemsAmount;
  final double totalAmount;
  final double? _paidAmount;
  final String paymentStatus; // "Received" or "Due"
  final String? paymentMethod; // "Cash", "UPI", "Card"
  final List<TableBillingItem> items;
  final List<PaymentTransaction> transactions;
  final double dueBufferAmount;
  final DateTime createdAt;

  const TableHistoryRecord({
    required this.id,
    required this.companyId,
    required this.tableId,
    required this.tableName,
    required this.customerName,
    this.customerPhone = '',
    required this.startedByName,
    required this.closedByName,
    required this.startedAt,
    required this.closedAt,
    required this.durationMinutes,
    required this.tableAmount,
    required this.itemsAmount,
    required this.totalAmount,
    double? paidAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.items = const [],
    this.transactions = const [],
    this.dueBufferAmount = Constants.dueBufferAmount,
    required this.createdAt,
  }) : _paidAmount = paidAmount;

  double get paidAmount {
    if (transactions.isNotEmpty) {
      return transactions.fold<double>(0.0, (total, t) => total + t.amount);
    }
    return _paidAmount ?? 0.0;
  }

  double get dueAmount {
    if (paymentStatus.toLowerCase() == 'received') return 0.0;
    final remaining = totalAmount - paidAmount;
    // Waive/settle remaining due if less than buffer cap
    if (remaining < dueBufferAmount) return 0.0;
    return remaining > 0.001 ? remaining : 0.0;
  }

  bool get isFullyPaid => dueAmount <= 0.001;
  bool get isPartiallyPaid => paidAmount > 0.001 && dueAmount > 0.001;
  bool get isDue => !isFullyPaid;
  bool get isReceived => isFullyPaid;

  TableHistoryRecord copyWith({
    String? id,
    String? companyId,
    String? tableId,
    String? tableName,
    String? customerName,
    String? customerPhone,
    String? startedByName,
    String? closedByName,
    DateTime? startedAt,
    DateTime? closedAt,
    int? durationMinutes,
    double? tableAmount,
    double? itemsAmount,
    double? totalAmount,
    double? paidAmount,
    String? paymentStatus,
    String? paymentMethod,
    List<TableBillingItem>? items,
    List<PaymentTransaction>? transactions,
    double? dueBufferAmount,
    DateTime? createdAt,
  }) {
    return TableHistoryRecord(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      startedByName: startedByName ?? this.startedByName,
      closedByName: closedByName ?? this.closedByName,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt ?? this.closedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tableAmount: tableAmount ?? this.tableAmount,
      itemsAmount: itemsAmount ?? this.itemsAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      transactions: transactions ?? this.transactions,
      dueBufferAmount: dueBufferAmount ?? this.dueBufferAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'tableId': tableId,
      'tableName': tableName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'startedByName': startedByName,
      'closedByName': closedByName,
      'startedAt': Timestamp.fromDate(startedAt),
      'closedAt': Timestamp.fromDate(closedAt),
      'durationMinutes': durationMinutes,
      'tableAmount': tableAmount,
      'itemsAmount': itemsAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentStatus': isFullyPaid ? 'Received' : 'Due',
      'paymentMethod': paymentMethod,
      'items': items.map((i) => i.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'dueBufferAmount': dueBufferAmount,
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

    final rawTransactions = map['transactions'] as List<dynamic>? ?? [];
    var transactions = rawTransactions
        .map((e) => PaymentTransaction.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final total = (map['totalAmount'] as num?)?.toDouble() ?? 0.0;
    var status = map['paymentStatus'] as String? ?? 'Received';
    final rawPaid = (map['paidAmount'] as num?)?.toDouble();
    final legacyPaid = rawPaid ?? (status.toLowerCase() == 'received' ? total : 0.0);
    final buffer = (map['dueBufferAmount'] as num?)?.toDouble() ?? Constants.dueBufferAmount;

    // If remaining due is less than buffer amount, consider it as Received
    if ((total - legacyPaid) < buffer) {
      status = 'Received';
    }

    // If no transactions recorded yet but legacy paid amount > 0, synthesize 1 transaction
    if (transactions.isEmpty && legacyPaid > 0.001) {
      transactions = [
        PaymentTransaction(
          id: 'legacy_init',
          amount: legacyPaid,
          paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
          receivedAt: parseDate(map['closedAt']),
          receivedBy: map['closedByName'] as String? ?? 'Staff',
          notes: 'Initial settlement',
        ),
      ];
    }

    return TableHistoryRecord(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      tableId: map['tableId'] as String? ?? '',
      tableName: map['tableName'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      startedByName: map['startedByName'] as String? ?? '',
      closedByName: map['closedByName'] as String? ?? '',
      startedAt: parseDate(map['startedAt']),
      closedAt: parseDate(map['closedAt']),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      tableAmount: (map['tableAmount'] as num?)?.toDouble() ?? 0.0,
      itemsAmount: (map['itemsAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: total,
      paidAmount: legacyPaid,
      paymentStatus: status,
      paymentMethod: map['paymentMethod'] as String?,
      items: items,
      transactions: transactions,
      dueBufferAmount: buffer,
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
        customerPhone,
        startedByName,
        closedByName,
        startedAt,
        closedAt,
        durationMinutes,
        tableAmount,
        itemsAmount,
        totalAmount,
        paidAmount,
        paymentStatus,
        paymentMethod,
        items,
        transactions,
        dueBufferAmount,
        createdAt,
      ];
}

