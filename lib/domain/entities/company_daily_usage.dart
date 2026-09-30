import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CompanyDailyUsage extends Equatable {
  final String date; // Format: yyyy-MM-dd
  final int reads;
  final int writes;
  final int deletes;
  final DateTime lastUpdated;

  const CompanyDailyUsage({
    required this.date,
    required this.reads,
    required this.writes,
    required this.deletes,
    required this.lastUpdated,
  });

  factory CompanyDailyUsage.fromMap(String date, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CompanyDailyUsage(
      date: date,
      reads: (map['reads'] as num?)?.toInt() ?? 0,
      writes: (map['writes'] as num?)?.toInt() ?? 0,
      deletes: (map['deletes'] as num?)?.toInt() ?? 0,
      lastUpdated: parseDate(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'reads': reads,
      'writes': writes,
      'deletes': deletes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  CompanyDailyUsage copyWith({
    String? date,
    int? reads,
    int? writes,
    int? deletes,
    DateTime? lastUpdated,
  }) {
    return CompanyDailyUsage(
      date: date ?? this.date,
      reads: reads ?? this.reads,
      writes: writes ?? this.writes,
      deletes: deletes ?? this.deletes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [date, reads, writes, deletes, lastUpdated];
}
