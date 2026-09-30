import 'package:equatable/equatable.dart';

/// A segment representing time spent at a specific rate tier.
class RentalRateSegment extends Equatable {
  final String rateName;
  final double hourlyRate;
  final int durationSeconds;
  final double amount;
  final bool isCustomRate;
  final String? timeWindow;

  const RentalRateSegment({
    required this.rateName,
    required this.hourlyRate,
    required this.durationSeconds,
    required this.amount,
    this.isCustomRate = false,
    this.timeWindow,
  });

  int get durationMinutes => (durationSeconds / 60).round();
  double get durationHours => durationSeconds / 3600.0;

  Map<String, dynamic> toMap() {
    return {
      'rateName': rateName,
      'hourlyRate': hourlyRate,
      'durationSeconds': durationSeconds,
      'amount': amount,
      'isCustomRate': isCustomRate,
      if (timeWindow != null) 'timeWindow': timeWindow,
    };
  }

  factory RentalRateSegment.fromMap(Map<String, dynamic> map) {
    return RentalRateSegment(
      rateName: map['rateName'] as String? ?? 'Standard Rate',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isCustomRate: map['isCustomRate'] as bool? ?? false,
      timeWindow: map['timeWindow'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        rateName,
        hourlyRate,
        durationSeconds,
        amount,
        isCustomRate,
        timeWindow,
      ];
}

/// Comprehensive breakdown of how the table rental fee was calculated.
class RentalCalculationBreakdown extends Equatable {
  final double baseHourlyRate;
  final int totalPlayedSeconds;
  final int pausedSeconds;
  final double totalRentAmount;
  final bool hasCustomRates;
  final List<RentalRateSegment> segments;

  const RentalCalculationBreakdown({
    required this.baseHourlyRate,
    required this.totalPlayedSeconds,
    this.pausedSeconds = 0,
    required this.totalRentAmount,
    this.hasCustomRates = false,
    this.segments = const [],
  });

  int get durationMinutes => (totalPlayedSeconds / 60).ceil();
  double get durationHours => totalPlayedSeconds / 3600.0;
  int get pausedMinutes => (pausedSeconds / 60).ceil();

  Map<String, dynamic> toMap() {
    return {
      'baseHourlyRate': baseHourlyRate,
      'totalPlayedSeconds': totalPlayedSeconds,
      'pausedSeconds': pausedSeconds,
      'totalRentAmount': totalRentAmount,
      'hasCustomRates': hasCustomRates,
      'segments': segments.map((s) => s.toMap()).toList(),
    };
  }

  factory RentalCalculationBreakdown.fromMap(Map<String, dynamic> map) {
    final rawSegments = map['segments'] as List<dynamic>? ?? [];
    return RentalCalculationBreakdown(
      baseHourlyRate: (map['baseHourlyRate'] as num?)?.toDouble() ?? 0.0,
      totalPlayedSeconds: (map['totalPlayedSeconds'] as num?)?.toInt() ?? 0,
      pausedSeconds: (map['pausedSeconds'] as num?)?.toInt() ?? 0,
      totalRentAmount: (map['totalRentAmount'] as num?)?.toDouble() ?? 0.0,
      hasCustomRates: map['hasCustomRates'] as bool? ?? false,
      segments: rawSegments
          .map((e) => RentalRateSegment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        baseHourlyRate,
        totalPlayedSeconds,
        pausedSeconds,
        totalRentAmount,
        hasCustomRates,
        segments,
      ];
}
