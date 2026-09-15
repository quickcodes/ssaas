import 'package:equatable/equatable.dart';

enum EquipmentType {
  chalkBlock,
  cueTip,
  tableClothFelt,
  ballSet;

  String get displayName {
    switch (this) {
      case EquipmentType.chalkBlock:
        return 'Chalk Inventory';
      case EquipmentType.cueTip:
        return 'Cue Tips Wear';
      case EquipmentType.tableClothFelt:
        return 'Table Cloth (Felt)';
      case EquipmentType.ballSet:
        return 'Tournament Ball Set';
    }
  }
}

enum EquipmentAlertStatus {
  normal,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case EquipmentAlertStatus.normal:
        return 'Good Condition';
      case EquipmentAlertStatus.warning:
        return 'Maintenance Due Soon';
      case EquipmentAlertStatus.critical:
        return 'Urgent Action Required';
    }
  }
}

class EquipmentItem extends Equatable {
  final String id;
  final String branchId;
  final String? tableId;
  final String? tableName;
  final String name;
  final EquipmentType type;
  final double currentMetricValue; // hours played, sessions, or stock count
  final double thresholdValue;     // e.g. 50h ironing, 1000h felt, 200h cue tip, 30 sessions ball set, 10 chalk
  final double maxLifespan;        // max wear or capacity
  final String metricUnit;         // 'hours', 'sessions', 'units'
  final DateTime lastMaintenanceDate;
  final EquipmentAlertStatus alertStatus;
  final String alertMessage;

  const EquipmentItem({
    required this.id,
    required this.branchId,
    this.tableId,
    this.tableName,
    required this.name,
    required this.type,
    required this.currentMetricValue,
    required this.thresholdValue,
    required this.maxLifespan,
    required this.metricUnit,
    required this.lastMaintenanceDate,
    required this.alertStatus,
    required this.alertMessage,
  });

  /// Computes wear percentage (0.0 to 100.0)
  double get wearPercentage {
    if (type == EquipmentType.chalkBlock) {
      // For stock, lower stock = higher depletion
      if (maxLifespan <= 0) return 0.0;
      final depleted = (maxLifespan - currentMetricValue) / maxLifespan * 100.0;
      return depleted.clamp(0.0, 100.0);
    }
    if (maxLifespan <= 0) return 0.0;
    return ((currentMetricValue / maxLifespan) * 100.0).clamp(0.0, 100.0);
  }

  EquipmentItem copyWith({
    String? id,
    String? branchId,
    String? tableId,
    String? tableName,
    String? name,
    EquipmentType? type,
    double? currentMetricValue,
    double? thresholdValue,
    double? maxLifespan,
    String? metricUnit,
    DateTime? lastMaintenanceDate,
    EquipmentAlertStatus? alertStatus,
    String? alertMessage,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      name: name ?? this.name,
      type: type ?? this.type,
      currentMetricValue: currentMetricValue ?? this.currentMetricValue,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      maxLifespan: maxLifespan ?? this.maxLifespan,
      metricUnit: metricUnit ?? this.metricUnit,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      alertStatus: alertStatus ?? this.alertStatus,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        tableId,
        tableName,
        name,
        type,
        currentMetricValue,
        thresholdValue,
        maxLifespan,
        metricUnit,
        lastMaintenanceDate,
        alertStatus,
        alertMessage,
      ];
}
