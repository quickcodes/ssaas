import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'rate_schedule.dart';
import 'table_billing_item.dart';

class TableSession extends Equatable {
  final String id;
  final String companyId;
  final String tableId;
  final String tableName;
  final String customerName;
  final String customerPhone;
  final String startedById;
  final String startedByName;
  final String closingName;
  final DateTime startTime;
  final DateTime? endTime;
  final int pausedSeconds;
  final bool isPaused;
  final DateTime? lastPauseTime;
  final double generalPrice;
  final List<RateSchedule> customPricings;
  final List<TableBillingItem> items;
  final String paymentStatus; // "Received", "Due", or "" (while active)
  final String? paymentMethod; // "Cash", "UPI", "Card"
  final String notes;

  const TableSession({
    required this.id,
    required this.companyId,
    required this.tableId,
    required this.tableName,
    required this.customerName,
    this.customerPhone = '',
    required this.startedById,
    required this.startedByName,
    this.closingName = '',
    required this.startTime,
    this.endTime,
    this.pausedSeconds = 0,
    this.isPaused = false,
    this.lastPauseTime,
    required this.generalPrice,
    this.customPricings = const [],
    this.items = const [],
    this.paymentStatus = '',
    this.paymentMethod,
    this.notes = '',
  });

  /// Duration played in seconds up to a given reference time (defaults to now or endTime)
  int playedSecondsAt(DateTime referenceTime) {
    final effectiveEnd = endTime ?? referenceTime;
    final totalElapsed = effectiveEnd.difference(startTime).inSeconds;
    int currentPause = 0;
    if (isPaused && lastPauseTime != null) {
      currentPause = effectiveEnd.difference(lastPauseTime!).inSeconds;
    }
    return (totalElapsed - pausedSeconds - currentPause).clamp(0, 86400 * 7);
  }

  /// Calculates effective hourly rate at a specific point in time
  double effectiveRateAt(DateTime time) {
    for (final schedule in customPricings) {
      if (schedule.appliesAt(time)) {
        return schedule.hourlyRate;
      }
    }
    return generalPrice;
  }

  /// Computes the table time charge dynamically at the given reference time
  double computeTableChargeAt(DateTime referenceTime) {
    final effectiveEnd = endTime ?? referenceTime;
    if (!effectiveEnd.isAfter(startTime)) return 0.0;
    final activeSeconds = playedSecondsAt(referenceTime);
    if (activeSeconds <= 0) return 0.0;

    final totalMinutes = (activeSeconds / 60).ceil();
    if (customPricings.isEmpty) {
      return (activeSeconds / 3600.0) * generalPrice;
    }

    double totalCost = 0.0;
    const stepMinutes = 5;
    var cursor = startTime;
    int processedMinutes = 0;

    while (processedMinutes < totalMinutes) {
      final chunk = (totalMinutes - processedMinutes) < stepMinutes
          ? (totalMinutes - processedMinutes)
          : stepMinutes;
      final rate = effectiveRateAt(cursor);
      totalCost += (chunk / 60.0) * rate;
      processedMinutes += chunk;
      cursor = cursor.add(Duration(minutes: chunk));
    }

    return totalCost;
  }

  /// Total sum of all snacks, drinks, and custom items added to the table
  double get itemsAmount {
    return items.fold(0.0, (acc, item) => acc + item.totalAmount);
  }

  /// Total grand bill (Table dynamic time charge + Items amount)
  double computeGrandTotalAt(DateTime referenceTime) {
    return computeTableChargeAt(referenceTime) + itemsAmount;
  }

  TableSession copyWith({
    String? id,
    String? companyId,
    String? tableId,
    String? tableName,
    String? customerName,
    String? customerPhone,
    String? startedById,
    String? startedByName,
    String? closingName,
    DateTime? startTime,
    DateTime? endTime,
    int? pausedSeconds,
    bool? isPaused,
    DateTime? lastPauseTime,
    double? generalPrice,
    List<RateSchedule>? customPricings,
    List<TableBillingItem>? items,
    String? paymentStatus,
    String? paymentMethod,
    String? notes,
  }) {
    return TableSession(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      startedById: startedById ?? this.startedById,
      startedByName: startedByName ?? this.startedByName,
      closingName: closingName ?? this.closingName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      isPaused: isPaused ?? this.isPaused,
      lastPauseTime: lastPauseTime ?? this.lastPauseTime,
      generalPrice: generalPrice ?? this.generalPrice,
      customPricings: customPricings ?? this.customPricings,
      items: items ?? this.items,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'tableId': tableId,
      'tableName': tableName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'startedById': startedById,
      'startedByName': startedByName,
      'closingName': closingName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'pausedSeconds': pausedSeconds,
      'isPaused': isPaused,
      'lastPauseTime': lastPauseTime != null ? Timestamp.fromDate(lastPauseTime!) : null,
      'generalPrice': generalPrice,
      'customPricings': customPricings.map((p) => p.toMap()).toList(),
      'items': items.map((i) => i.toMap()).toList(),
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory TableSession.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawPricings = map['customPricings'] as List<dynamic>? ?? [];
    final customPricings = rawPricings
        .map((e) => RateSchedule.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => TableBillingItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return TableSession(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      tableId: map['tableId'] as String? ?? '',
      tableName: map['tableName'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      startedById: map['startedById'] as String? ?? '',
      startedByName: map['startedByName'] as String? ?? '',
      closingName: map['closingName'] as String? ?? '',
      startTime: parseDate(map['startTime']),
      endTime: parseNullableDate(map['endTime']),
      pausedSeconds: (map['pausedSeconds'] as num?)?.toInt() ?? 0,
      isPaused: map['isPaused'] as bool? ?? false,
      lastPauseTime: parseNullableDate(map['lastPauseTime']),
      generalPrice: (map['generalPrice'] as num?)?.toDouble() ?? 100.0,
      customPricings: customPricings,
      items: items,
      paymentStatus: map['paymentStatus'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String?,
      notes: map['notes'] as String? ?? '',
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
        startedById,
        startedByName,
        closingName,
        startTime,
        endTime,
        pausedSeconds,
        isPaused,
        lastPauseTime,
        generalPrice,
        customPricings,
        items,
        paymentStatus,
        paymentMethod,
        notes,
      ];
}
