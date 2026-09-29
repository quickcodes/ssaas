import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'rate_schedule.dart';

enum TableStatus {
  available,
  occupied,
  maintenance;

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Running';
      case TableStatus.maintenance:
        return 'Maintenance';
    }
  }

  static TableStatus fromString(String? val) {
    if (val == null) return TableStatus.available;
    final lower = val.toLowerCase();
    if (lower == 'running' || lower == 'occupied') return TableStatus.occupied;
    if (lower == 'maintenance') return TableStatus.maintenance;
    return TableStatus.available;
  }
}

class ClubTable extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final double generalPrice; // General hourly rate
  final List<RateSchedule> customPricings; // Time & weekday custom rates
  final String specsDescription;
  final TableStatus status;
  final String? currentSessionId;
  final DateTime createdAt;

  const ClubTable({
    required this.id,
    required this.companyId,
    required this.name,
    required this.generalPrice,
    this.customPricings = const [],
    this.specsDescription = '',
    this.status = TableStatus.available,
    this.currentSessionId,
    required this.createdAt,
  });

  /// Calculates the effective hourly rate at a specific point in time
  double effectiveRateAt(DateTime time) {
    for (final schedule in customPricings) {
      if (schedule.appliesAt(time)) {
        return schedule.hourlyRate;
      }
    }
    return generalPrice;
  }

  /// Computes dynamic table charge for a duration taking custom rate schedules into account
  double computeDynamicCharge(DateTime start, DateTime end, {int pausedSeconds = 0}) {
    if (!end.isAfter(start)) return 0.0;
    final totalSeconds = (end.difference(start).inSeconds - pausedSeconds).clamp(0, 86400 * 7);
    if (totalSeconds <= 0) return 0.0;

    if (customPricings.isEmpty) {
      return (totalSeconds / 3600.0) * generalPrice;
    }

    double totalCost = 0.0;
    const stepMinutes = 5;
    var cursor = start;
    final fullMinutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
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

  ClubTable copyWith({
    String? id,
    String? companyId,
    String? name,
    double? generalPrice,
    List<RateSchedule>? customPricings,
    String? specsDescription,
    TableStatus? status,
    String? currentSessionId,
    bool clearCurrentSessionId = false,
    DateTime? createdAt,
  }) {
    return ClubTable(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      generalPrice: generalPrice ?? this.generalPrice,
      customPricings: customPricings ?? this.customPricings,
      specsDescription: specsDescription ?? this.specsDescription,
      status: status ?? this.status,
      currentSessionId: clearCurrentSessionId
          ? null
          : (currentSessionId ?? this.currentSessionId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'generalPrice': generalPrice,
      'customPricings': customPricings.map((p) => p.toMap()).toList(),
      'specsDescription': specsDescription,
      'status': status.displayName,
      'currentSessionId': currentSessionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ClubTable.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawPricings = map['customPricings'] as List<dynamic>? ?? [];
    final customPricings = rawPricings
        .map((e) => RateSchedule.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return ClubTable(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      generalPrice: (map['generalPrice'] as num?)?.toDouble() ?? 100.0,
      customPricings: customPricings,
      specsDescription: map['specsDescription'] as String? ?? '',
      status: TableStatus.fromString(map['status'] as String?),
      currentSessionId: map['currentSessionId'] as String?,
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        generalPrice,
        customPricings,
        specsDescription,
        status,
        currentSessionId,
        createdAt,
      ];
}
