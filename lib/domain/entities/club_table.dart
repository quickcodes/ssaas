import 'package:equatable/equatable.dart';
import 'rate_schedule.dart';

enum TableStatus {
  available,
  occupied,
  maintenance,
  reserved;

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.maintenance:
        return 'Maintenance / Ironing';
      case TableStatus.reserved:
        return 'Reserved';
    }
  }
}

enum TableType {
  standardSnooker12ft,
  pool10ft,
  vipSlate12ft,
  englishPool8ft;

  String get displayName {
    switch (this) {
      case TableType.standardSnooker12ft:
        return '12ft Standard Snooker';
      case TableType.pool10ft:
        return '10ft American Pool';
      case TableType.vipSlate12ft:
        return '12ft VIP Tournament Slate';
      case TableType.englishPool8ft:
        return '8ft English Pool';
    }
  }
}

class ClubTable extends Equatable {
  final String id;
  final String branchId;
  final int tableNumber;
  final String name;
  final TableType type;
  final String specsDescription;
  final TableStatus status;
  final double standardRatePerHour;
  final double peakRatePerHour;
  final double fixedFrameRate;
  final double vipRatePerHour;
  final String? currentSessionId;
  final double cumulativeClothHours;
  final int totalFramesPlayed;
  final List<RateSchedule> rateSchedules;

  const ClubTable({
    required this.id,
    required this.branchId,
    required this.tableNumber,
    required this.name,
    required this.type,
    required this.specsDescription,
    required this.status,
    required this.standardRatePerHour,
    required this.peakRatePerHour,
    required this.fixedFrameRate,
    required this.vipRatePerHour,
    this.currentSessionId,
    this.cumulativeClothHours = 0.0,
    this.totalFramesPlayed = 0,
    this.rateSchedules = const [],
  });

  ClubTable copyWith({
    String? id,
    String? branchId,
    int? tableNumber,
    String? name,
    TableType? type,
    String? specsDescription,
    TableStatus? status,
    double? standardRatePerHour,
    double? peakRatePerHour,
    double? fixedFrameRate,
    double? vipRatePerHour,
    String? currentSessionId,
    bool clearCurrentSessionId = false,
    double? cumulativeClothHours,
    int? totalFramesPlayed,
    List<RateSchedule>? rateSchedules,
  }) {
    return ClubTable(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      tableNumber: tableNumber ?? this.tableNumber,
      name: name ?? this.name,
      type: type ?? this.type,
      specsDescription: specsDescription ?? this.specsDescription,
      status: status ?? this.status,
      standardRatePerHour: standardRatePerHour ?? this.standardRatePerHour,
      peakRatePerHour: peakRatePerHour ?? this.peakRatePerHour,
      fixedFrameRate: fixedFrameRate ?? this.fixedFrameRate,
      vipRatePerHour: vipRatePerHour ?? this.vipRatePerHour,
      currentSessionId: clearCurrentSessionId
          ? null
          : (currentSessionId ?? this.currentSessionId),
      cumulativeClothHours: cumulativeClothHours ?? this.cumulativeClothHours,
      totalFramesPlayed: totalFramesPlayed ?? this.totalFramesPlayed,
      rateSchedules: rateSchedules ?? this.rateSchedules,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branchId,
    tableNumber,
    name,
    type,
    specsDescription,
    status,
    standardRatePerHour,
    peakRatePerHour,
    fixedFrameRate,
    vipRatePerHour,
    currentSessionId,
    cumulativeClothHours,
    totalFramesPlayed,
    rateSchedules,
  ];
}
