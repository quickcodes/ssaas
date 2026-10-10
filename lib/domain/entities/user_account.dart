import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserAccount extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String number;
  final String email;
  final String password;
  final String role;
  final bool isAdmin;
  final bool isActive;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime? sessionExpiresAt;
  final int shiftCount;
  final int totalWorkingSeconds;

  const UserAccount({
    required this.id,
    required this.companyId,
    required this.name,
    required this.number,
    required this.email,
    required this.password,
    this.role = 'employee',
    this.isAdmin = false,
    this.isActive = true,
    this.isOnline = false,
    required this.createdAt,
    this.sessionExpiresAt,
    this.shiftCount = 0,
    this.totalWorkingSeconds = 0,
  });

  // Role permissions & helpers
  bool get isOwner =>
      role.toLowerCase() == 'owner' || (role.isEmpty && isAdmin);
  bool get isEmployee => !isOwner;
  bool get isDeactivated => !isActive;

  bool get canManageUsers => isOwner || isAdmin;
  bool get canCreateTables => isOwner || isAdmin;
  bool get canSetTablePrices => isOwner || isAdmin;
  bool get canManageRates => isOwner || isAdmin;
  bool get canDeactivateUsers => isOwner;
  String get phoneNumber => number;

  // Session state
  bool get isSessionValid =>
      isActive &&
      sessionExpiresAt != null &&
      DateTime.now().isBefore(sessionExpiresAt!);

  Duration get totalWorkingDuration => Duration(seconds: totalWorkingSeconds);

  UserAccount copyWith({
    String? id,
    String? companyId,
    String? name,
    String? number,
    String? email,
    String? password,
    String? role,
    bool? isAdmin,
    bool? isActive,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? sessionExpiresAt,
    int? shiftCount,
    int? totalWorkingSeconds,
    bool clearSession = false,
  }) {
    final effectiveRole = role ?? this.role;
    final effectiveIsAdmin =
        isAdmin ??
        (role != null ? (role.toLowerCase() == 'owner') : this.isAdmin);

    return UserAccount(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      number: number ?? this.number,
      email: email ?? this.email,
      password: password ?? this.password,
      role: effectiveRole,
      isAdmin: effectiveIsAdmin,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      sessionExpiresAt: clearSession
          ? null
          : (sessionExpiresAt ?? this.sessionExpiresAt),
      shiftCount: shiftCount ?? this.shiftCount,
      totalWorkingSeconds: totalWorkingSeconds ?? this.totalWorkingSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'number': number,
      'email': email,
      'password': password,
      'role': role.toLowerCase(),
      'isAdmin': isOwner,
      'isActive': isActive,
      'isDeactivated': !isActive,
      'isOnline': isOnline,
      'createdAt': Timestamp.fromDate(createdAt),
      'sessionExpiresAt': sessionExpiresAt != null
          ? Timestamp.fromDate(sessionExpiresAt!)
          : null,
      'shiftCount': shiftCount,
      'totalWorkingSeconds': totalWorkingSeconds,
    };
  }

  factory UserAccount.fromMap(String id, Map<String, dynamic> map) {
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

    final rawRole = map['role'] as String?;
    final legacyIsAdmin = map['isAdmin'] as bool? ?? false;
    final role = (rawRole != null && rawRole.trim().isNotEmpty)
        ? rawRole.trim().toLowerCase()
        : (legacyIsAdmin ? 'owner' : 'employee');

    final rawIsActive = map['isActive'] as bool?;
    final rawIsDeactivated = map['isDeactivated'] as bool?;
    final isActive =
        rawIsActive ?? (rawIsDeactivated != null ? !rawIsDeactivated : true);

    return UserAccount(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      number: map['number'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: role,
      isAdmin: role == 'owner' || legacyIsAdmin,
      isActive: isActive,
      isOnline: map['isOnline'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      sessionExpiresAt: parseOptionalDate(map['sessionExpiresAt']),
      shiftCount: map['shiftCount'] as int? ?? 0,
      totalWorkingSeconds: map['totalWorkingSeconds'] as int? ?? 0,
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
    role,
    isAdmin,
    isActive,
    isOnline,
    createdAt,
    sessionExpiresAt,
    shiftCount,
    totalWorkingSeconds,
  ];
}
