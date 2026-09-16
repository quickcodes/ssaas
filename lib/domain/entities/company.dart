import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Company extends Equatable {
  final String id;
  final String name;
  final String number;
  final DateTime expiryDate;
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    required this.number,
    required this.expiryDate,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  Company copyWith({
    String? id,
    String? name,
    String? number,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Company.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Company(
      id: id,
      name: map['name'] as String? ?? '',
      number: map['number'] as String? ?? '',
      expiryDate: parseDate(map['expiryDate']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, name, number, expiryDate, createdAt];
}
