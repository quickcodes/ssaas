import 'package:equatable/equatable.dart';
import 'rate_schedule.dart';

enum BillingMode {
  perMinute,
  hourly,
  fixedFrame,
  vip;

  String get displayName {
    switch (this) {
      case BillingMode.perMinute:
        return 'Per Minute Dynamic';
      case BillingMode.hourly:
        return 'Standard Hourly';
      case BillingMode.fixedFrame:
        return 'Fixed Frame Flat';
      case BillingMode.vip:
        return 'VIP Tournament Rate';
    }
  }
}

enum PaymentMethod {
  cash,
  upi,
  card;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI / QR Pay';
      case PaymentMethod.card:
        return 'Card';
    }
  }
}

class TableSession extends Equatable {
  final String id;
  final String branchId;
  final String tableId;
  final String tableName;
  final String operatorId;
  final String operatorName;
  final String playerName;
  final String playerPhone;
  final DateTime startTime;
  final DateTime? endTime;
  final int pausedSeconds;
  final bool isPaused;
  final DateTime? lastPauseTime;
  final BillingMode billingMode;
  final double standardRatePerHour;
  final double peakRatePerHour;
  final int peakStartHour;
  final int peakEndHour;
  final double fixedFrameFee;
  final double tableAmount;
  final double fnbAmount;
  final double discountAmount;
  final double totalAmount;
  final bool isPaid;
  final PaymentMethod? paymentMethod;
  final String notes;
  final List<RateSchedule> rateSchedules;

  const TableSession({
    required this.id,
    required this.branchId,
    required this.tableId,
    required this.tableName,
    required this.operatorId,
    required this.operatorName,
    required this.playerName,
    this.playerPhone = '',
    required this.startTime,
    this.endTime,
    this.pausedSeconds = 0,
    this.isPaused = false,
    this.lastPauseTime,
    required this.billingMode,
    required this.standardRatePerHour,
    required this.peakRatePerHour,
    this.peakStartHour = 18,
    this.peakEndHour = 23,
    this.fixedFrameFee = 100.0,
    this.tableAmount = 0.0,
    this.fnbAmount = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.isPaid = false,
    this.paymentMethod,
    this.notes = '',
    this.rateSchedules = const [],
  });

  /// Duration played in seconds up to a given reference time (defaults to now or endTime)
  int playedSecondsAt(DateTime now) {
    if (endTime != null) {
      final total = endTime!.difference(startTime).inSeconds - pausedSeconds;
      return total > 0 ? total : 0;
    }
    int extraPaused = 0;
    if (isPaused && lastPauseTime != null) {
      extraPaused = now.difference(lastPauseTime!).inSeconds;
    }
    final diff =
        now.difference(startTime).inSeconds - pausedSeconds - extraPaused;
    return diff > 0 ? diff : 0;
  }

  /// Calculates dynamic table charge with peak/off-peak prorating
  double computeTableChargeAt(DateTime now) {
    if (billingMode == BillingMode.fixedFrame) {
      return fixedFrameFee;
    }

    final seconds = playedSecondsAt(now);
    if (seconds <= 0) return 0.0;

    // Bill against the actual time range, then proportionally remove any
    // completed pause time. This keeps rate-boundary calculations exact and
    // avoids rounding a partial minute up to a full minute.
    final effectiveEndTime =
        endTime ?? (isPaused && lastPauseTime != null ? lastPauseTime! : now);
    double totalCharge = 0.0;

    if (billingMode == BillingMode.vip) {
      // VIP rate applies uniformly
      final hours = seconds / 3600.0;
      totalCharge = hours * peakRatePerHour;
    } else {
      DateTime cursor = startTime;
      while (cursor.isBefore(effectiveEndTime)) {
        final configuredRate = rateSchedules
            .where((slot) => slot.appliesAt(cursor))
            .toList();
        final currentRate = configuredRate.isNotEmpty
            ? configuredRate.last.hourlyRate
            : (cursor.hour >= peakStartHour && cursor.hour < peakEndHour
                  ? peakRatePerHour
                  : standardRatePerHour);

        final nextHour = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          cursor.hour + 1,
        );
        final boundaries = <DateTime>[nextHour];
        for (final slot in rateSchedules) {
          for (final minute in [slot.startMinuteOfDay, slot.endMinuteOfDay]) {
            var boundary = DateTime(
              cursor.year,
              cursor.month,
              cursor.day,
              minute ~/ 60,
              minute % 60,
            );
            if (!boundary.isAfter(cursor)) {
              boundary = boundary.add(const Duration(days: 1));
            }
            boundaries.add(boundary);
          }
        }
        final nextBoundary = boundaries.reduce(
          (first, value) => value.isBefore(first) ? value : first,
        );
        final sliceEnd = nextBoundary.isBefore(effectiveEndTime)
            ? nextBoundary
            : effectiveEndTime;
        totalCharge +=
            (currentRate / 3600.0) *
            sliceEnd.difference(cursor).inMilliseconds /
            1000.0;
        cursor = sliceEnd;
      }

      final elapsedSeconds =
          effectiveEndTime.difference(startTime).inMilliseconds / 1000.0;
      if (elapsedSeconds > 0 && seconds < elapsedSeconds) {
        totalCharge *= seconds / elapsedSeconds;
      }
    }

    // Round to 2 decimal places
    return double.parse(totalCharge.toStringAsFixed(2));
  }

  double computeGrandTotalAt(DateTime now) {
    final tAmount = computeTableChargeAt(now);
    final total = tAmount + fnbAmount - discountAmount;
    return total > 0 ? double.parse(total.toStringAsFixed(2)) : 0.0;
  }

  TableSession copyWith({
    String? id,
    String? branchId,
    String? tableId,
    String? tableName,
    String? operatorId,
    String? operatorName,
    String? playerName,
    String? playerPhone,
    DateTime? startTime,
    DateTime? endTime,
    int? pausedSeconds,
    bool? isPaused,
    DateTime? lastPauseTime,
    BillingMode? billingMode,
    double? standardRatePerHour,
    double? peakRatePerHour,
    int? peakStartHour,
    int? peakEndHour,
    double? fixedFrameFee,
    double? tableAmount,
    double? fnbAmount,
    double? discountAmount,
    double? totalAmount,
    bool? isPaid,
    PaymentMethod? paymentMethod,
    String? notes,
    List<RateSchedule>? rateSchedules,
  }) {
    return TableSession(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      playerName: playerName ?? this.playerName,
      playerPhone: playerPhone ?? this.playerPhone,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      isPaused: isPaused ?? this.isPaused,
      lastPauseTime: lastPauseTime ?? this.lastPauseTime,
      billingMode: billingMode ?? this.billingMode,
      standardRatePerHour: standardRatePerHour ?? this.standardRatePerHour,
      peakRatePerHour: peakRatePerHour ?? this.peakRatePerHour,
      peakStartHour: peakStartHour ?? this.peakStartHour,
      peakEndHour: peakEndHour ?? this.peakEndHour,
      fixedFrameFee: fixedFrameFee ?? this.fixedFrameFee,
      tableAmount: tableAmount ?? this.tableAmount,
      fnbAmount: fnbAmount ?? this.fnbAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      rateSchedules: rateSchedules ?? this.rateSchedules,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branchId,
    tableId,
    tableName,
    operatorId,
    operatorName,
    playerName,
    playerPhone,
    startTime,
    endTime,
    pausedSeconds,
    isPaused,
    lastPauseTime,
    billingMode,
    standardRatePerHour,
    peakRatePerHour,
    peakStartHour,
    peakEndHour,
    fixedFrameFee,
    tableAmount,
    fnbAmount,
    discountAmount,
    totalAmount,
    isPaid,
    paymentMethod,
    notes,
    rateSchedules,
  ];
}
