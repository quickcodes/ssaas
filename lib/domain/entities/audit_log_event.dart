import 'package:equatable/equatable.dart';

enum AuditSeverity {
  info,
  warning,
  criticalAlert;

  String get displayName {
    switch (this) {
      case AuditSeverity.info:
        return 'Info';
      case AuditSeverity.warning:
        return 'Flagged Action';
      case AuditSeverity.criticalAlert:
        return 'Tamper Alert';
    }
  }
}

class AuditLogEvent extends Equatable {
  final String id;
  final String branchId;
  final String operatorId;
  final String operatorName;
  final String action;
  final String details;
  final DateTime timestamp;
  final AuditSeverity severity;
  final bool isTamperFlag;

  const AuditLogEvent({
    required this.id,
    required this.branchId,
    required this.operatorId,
    required this.operatorName,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.severity,
    this.isTamperFlag = false,
  });

  AuditLogEvent copyWith({
    String? id,
    String? branchId,
    String? operatorId,
    String? operatorName,
    String? action,
    String? details,
    DateTime? timestamp,
    AuditSeverity? severity,
    bool? isTamperFlag,
  }) {
    return AuditLogEvent(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      action: action ?? this.action,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      severity: severity ?? this.severity,
      isTamperFlag: isTamperFlag ?? this.isTamperFlag,
    );
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        operatorId,
        operatorName,
        action,
        details,
        timestamp,
        severity,
        isTamperFlag,
      ];
}
