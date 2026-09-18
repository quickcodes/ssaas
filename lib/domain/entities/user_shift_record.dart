import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserShiftRecord extends Equatable {
  final String id;
  final DateTime onlineAt;
  final DateTime? offlineAt;

  const UserShiftRecord({
    required this.id,
    required this.onlineAt,
    this.offlineAt,
  });

  bool get isActive => offlineAt == null;

  Duration get duration {
    final end = offlineAt ?? DateTime.now();
    return end.difference(onlineAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'onlineAt': Timestamp.fromDate(onlineAt),
      'offlineAt': offlineAt != null ? Timestamp.fromDate(offlineAt!) : null,
    };
  }

  factory UserShiftRecord.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserShiftRecord(
      id: map['id'] as String? ?? '',
      onlineAt: parseDate(map['onlineAt']),
      offlineAt: parseOptionalDate(map['offlineAt']),
    );
  }

  UserShiftRecord copyWith({
    String? id,
    DateTime? onlineAt,
    DateTime? offlineAt,
  }) {
    return UserShiftRecord(
      id: id ?? this.id,
      onlineAt: onlineAt ?? this.onlineAt,
      offlineAt: offlineAt ?? this.offlineAt,
    );
  }

  @override
  List<Object?> get props => [id, onlineAt, offlineAt];
}
