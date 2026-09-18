import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/constants.dart';

class Company extends Equatable {
  final String id;
  final String name;
  final String code;
  final String number;
  final DateTime expiryDate;
  final DateTime createdAt;
  final double dueBufferAmount;

  const Company({
    required this.id,
    required this.name,
    required this.code,
    required this.number,
    required this.expiryDate,
    required this.createdAt,
    this.dueBufferAmount = Constants.dueBufferAmount,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  Company copyWith({
    String? id,
    String? name,
    String? code,
    String? number,
    DateTime? expiryDate,
    DateTime? createdAt,
    double? dueBufferAmount,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      number: number ?? this.number,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      dueBufferAmount: dueBufferAmount ?? this.dueBufferAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code.trim().toUpperCase(),
      'number': number,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'dueBufferAmount': dueBufferAmount,
    };
  }

  factory Company.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawCode = map['code'] as String?;
    final code = (rawCode != null && rawCode.trim().isNotEmpty)
        ? rawCode.trim().toUpperCase()
        : id;

    return Company(
      id: id,
      name: map['name'] as String? ?? '',
      code: code,
      number: map['number'] as String? ?? '',
      expiryDate: parseDate(map['expiryDate']),
      createdAt: parseDate(map['createdAt']),
      dueBufferAmount: (map['dueBufferAmount'] as num?)?.toDouble() ??
          Constants.dueBufferAmount,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, code, number, expiryDate, createdAt, dueBufferAmount];
}
