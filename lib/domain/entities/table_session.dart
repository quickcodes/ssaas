import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'rate_schedule.dart';
import 'rental_calculation_breakdown.dart';
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
  final int? lastPlayedSeconds;
  final double? lastTableCharge;
  final double? lastGrandTotal;

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
    this.lastPlayedSeconds,
    this.lastTableCharge,
    this.lastGrandTotal,
  });

  /// Duration played in seconds up to a given reference time (defaults to now or endTime).
  /// When isPaused is true, active time stops accumulating at lastPauseTime,
  /// ensuring 100% identical duration on all devices regardless of clock skew.
  int playedSecondsAt(DateTime referenceTime) {
    final effectiveEnd = endTime ?? referenceTime;
    if (!effectiveEnd.isAfter(startTime)) return 0;

    DateTime calcEnd = effectiveEnd;
    if (isPaused && lastPauseTime != null) {
      if (calcEnd.isAfter(lastPauseTime!)) {
        calcEnd = lastPauseTime!;
      }
    }

    final played = calcEnd.difference(startTime).inSeconds - pausedSeconds;
    return played.clamp(0, 86400 * 7);
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

  /// Computes the table time charge dynamically at the given reference time.
  /// Uses exact second-level precision so charges are uniform, continuous, and match
  /// across devices without jumping in minute steps.
  double computeTableChargeAt(DateTime referenceTime) {
    final effectiveEnd = endTime ?? referenceTime;
    if (!effectiveEnd.isAfter(startTime)) return 0.0;
    final activeSeconds = playedSecondsAt(referenceTime);
    if (activeSeconds <= 0) return 0.0;

    if (customPricings.isEmpty) {
      return (activeSeconds / 3600.0) * generalPrice;
    }

    double totalCost = 0.0;
    const stepMinutes = 5;
    var cursor = startTime;
    final fullMinutes = activeSeconds ~/ 60;
    final remainingSeconds = activeSeconds % 60;
    int processedMinutes = 0;

    while (processedMinutes < fullMinutes) {
      final chunk = (fullMinutes - processedMinutes) < stepMinutes
          ? (fullMinutes - processedMinutes)
          : stepMinutes;
      final rate = effectiveRateAt(cursor);
      totalCost += (chunk / 60.0) * rate;
      processedMinutes += chunk;
      cursor = cursor.add(Duration(minutes: chunk));
    }

    if (remainingSeconds > 0) {
      final rate = effectiveRateAt(cursor);
      totalCost += (remainingSeconds / 3600.0) * rate;
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

  /// Computes a full itemized breakdown of table rent including base rate,
  /// custom pricing schedules applied, duration per rate tier, and pause time.
  RentalCalculationBreakdown computeRentalBreakdownAt(DateTime referenceTime) {
    final effectiveEnd = endTime ?? referenceTime;
    if (!effectiveEnd.isAfter(startTime)) {
      return RentalCalculationBreakdown(
        baseHourlyRate: generalPrice,
        totalPlayedSeconds: 0,
        pausedSeconds: pausedSeconds,
        totalRentAmount: 0.0,
        hasCustomRates: customPricings.isNotEmpty,
        segments: const [],
      );
    }

    final activeSeconds = playedSecondsAt(referenceTime);
    if (activeSeconds <= 0) {
      return RentalCalculationBreakdown(
        baseHourlyRate: generalPrice,
        totalPlayedSeconds: 0,
        pausedSeconds: pausedSeconds,
        totalRentAmount: 0.0,
        hasCustomRates: customPricings.isNotEmpty,
        segments: const [],
      );
    }

    if (customPricings.isEmpty) {
      final charge = (activeSeconds / 3600.0) * generalPrice;
      return RentalCalculationBreakdown(
        baseHourlyRate: generalPrice,
        totalPlayedSeconds: activeSeconds,
        pausedSeconds: pausedSeconds,
        totalRentAmount: charge,
        hasCustomRates: false,
        segments: [
          RentalRateSegment(
            rateName: 'Standard Hourly Rate',
            hourlyRate: generalPrice,
            durationSeconds: activeSeconds,
            amount: charge,
            isCustomRate: false,
          ),
        ],
      );
    }

    // Accumulate time & cost into ordered rate buckets
    final List<_RateBucketHelper> buckets = [];
    const stepMinutes = 1;
    var cursor = startTime;
    final fullMinutes = activeSeconds ~/ 60;
    final remainingSeconds = activeSeconds % 60;
    int processedMinutes = 0;

    void recordTimeAtCursor(DateTime time, int seconds) {
      RateSchedule? applied;
      for (final schedule in customPricings) {
        if (schedule.appliesAt(time)) {
          applied = schedule;
          break;
        }
      }

      final isCustom = applied != null;
      final name = isCustom ? applied.label : 'Standard Rate';
      final rate = isCustom ? applied.hourlyRate : generalPrice;
      final timeWindow = applied != null
          ? '${_formatMinuteOfDay(applied.startMinuteOfDay)} - ${_formatMinuteOfDay(applied.endMinuteOfDay)}'
          : null;

      final existingIndex = buckets.indexWhere(
        (b) => b.rateName == name && b.hourlyRate == rate,
      );

      if (existingIndex >= 0) {
        buckets[existingIndex].durationSeconds += seconds;
        buckets[existingIndex].amount += (seconds / 3600.0) * rate;
      } else {
        buckets.add(
          _RateBucketHelper(
            rateName: name,
            hourlyRate: rate,
            durationSeconds: seconds,
            amount: (seconds / 3600.0) * rate,
            isCustomRate: isCustom,
            timeWindow: timeWindow,
          ),
        );
      }
    }

    while (processedMinutes < fullMinutes) {
      final chunkMinutes = (fullMinutes - processedMinutes) < stepMinutes
          ? (fullMinutes - processedMinutes)
          : stepMinutes;
      recordTimeAtCursor(cursor, chunkMinutes * 60);
      processedMinutes += chunkMinutes;
      cursor = cursor.add(Duration(minutes: chunkMinutes));
    }

    if (remainingSeconds > 0) {
      recordTimeAtCursor(cursor, remainingSeconds);
    }

    final segments = buckets
        .map(
          (b) => RentalRateSegment(
            rateName: b.rateName,
            hourlyRate: b.hourlyRate,
            durationSeconds: b.durationSeconds,
            amount: b.amount,
            isCustomRate: b.isCustomRate,
            timeWindow: b.timeWindow,
          ),
        )
        .toList();

    final totalCost = segments.fold<double>(0.0, (acc, s) => acc + s.amount);
    final hasActiveCustomRates = segments.any((s) => s.isCustomRate);

    return RentalCalculationBreakdown(
      baseHourlyRate: generalPrice,
      totalPlayedSeconds: activeSeconds,
      pausedSeconds: pausedSeconds,
      totalRentAmount: totalCost,
      hasCustomRates: hasActiveCustomRates || customPricings.isNotEmpty,
      segments: segments,
    );
  }

  static String _formatMinuteOfDay(int minuteOfDay) {
    final h = minuteOfDay ~/ 60;
    final m = minuteOfDay % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final displayM = m.toString().padLeft(2, '0');
    return '$displayH:$displayM $period';
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
    int? lastPlayedSeconds,
    double? lastTableCharge,
    double? lastGrandTotal,
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
      lastPlayedSeconds: lastPlayedSeconds ?? this.lastPlayedSeconds,
      lastTableCharge: lastTableCharge ?? this.lastTableCharge,
      lastGrandTotal: lastGrandTotal ?? this.lastGrandTotal,
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
      'lastPlayedSeconds': lastPlayedSeconds,
      'lastTableCharge': lastTableCharge,
      'lastGrandTotal': lastGrandTotal,
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
      lastPlayedSeconds: (map['lastPlayedSeconds'] as num?)?.toInt(),
      lastTableCharge: (map['lastTableCharge'] as num?)?.toDouble(),
      lastGrandTotal: (map['lastGrandTotal'] as num?)?.toDouble(),
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
        lastPlayedSeconds,
        lastTableCharge,
        lastGrandTotal,
      ];
}

class _RateBucketHelper {
  final String rateName;
  final double hourlyRate;
  int durationSeconds;
  double amount;
  final bool isCustomRate;
  final String? timeWindow;

  _RateBucketHelper({
    required this.rateName,
    required this.hourlyRate,
    required this.durationSeconds,
    required this.amount,
    required this.isCustomRate,
    this.timeWindow,
  });
}

