import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClubReminder extends Equatable {
  final String id;
  final String companyId;
  final String description;
  final DateTime remindAt;
  final DateTime createdAt;
  final String createdBy;
  final bool isDismissed;

  const ClubReminder({
    required this.id,
    required this.companyId,
    required this.description,
    required this.remindAt,
    required this.createdAt,
    this.createdBy = '',
    this.isDismissed = false,
  });

  /// True when current time is within 1 hour before scheduled time
  /// and up to 4 hours after (unless explicitly dismissed).
  bool isDueSoon(DateTime now) {
    if (isDismissed) return false;
    final oneHourBefore = remindAt.subtract(const Duration(hours: 1));
    final expiresAfter = remindAt.add(const Duration(hours: 4));
    return now.isAfter(oneHourBefore) && now.isBefore(expiresAfter);
  }

  ClubReminder copyWith({
    String? id,
    String? companyId,
    String? description,
    DateTime? remindAt,
    DateTime? createdAt,
    String? createdBy,
    bool? isDismissed,
  }) {
    return ClubReminder(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      description: description ?? this.description,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'description': description.trim(),
      'remindAt': Timestamp.fromDate(remindAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isDismissed': isDismissed,
    };
  }

  factory ClubReminder.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ClubReminder(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      remindAt: parseDate(map['remindAt']),
      createdAt: parseDate(map['createdAt']),
      createdBy: map['createdBy'] as String? ?? '',
      isDismissed: map['isDismissed'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        description,
        remindAt,
        createdAt,
        createdBy,
        isDismissed,
      ];
}
