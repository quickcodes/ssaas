import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserAccount extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String number;
  final String email;
  final String password;
  final bool isAdmin;
  final DateTime createdAt;

  const UserAccount({
    required this.id,
    required this.companyId,
    required this.name,
    required this.number,
    required this.email,
    required this.password,
    this.isAdmin = false,
    required this.createdAt,
  });

  // Role permissions
  bool get canManageUsers => isAdmin;
  bool get canCreateTables => isAdmin;
  bool get canSetTablePrices => isAdmin;
  bool get canManageRates => isAdmin;

  UserAccount copyWith({
    String? id,
    String? companyId,
    String? name,
    String? number,
    String? email,
    String? password,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      number: number ?? this.number,
      email: email ?? this.email,
      password: password ?? this.password,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'number': number,
      'email': email,
      'password': password,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserAccount.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserAccount(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      number: map['number'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      isAdmin: map['isAdmin'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        number,
        email,
        password,
        isAdmin,
        createdAt,
      ];
}
