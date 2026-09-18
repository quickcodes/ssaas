import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'user_shift_record.dart';

class UserAccount extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String number;
  final String email;
  final String password;
  final bool isAdmin;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime? sessionExpiresAt;
  final List<UserShiftRecord> shifts;

  const UserAccount({
    required this.id,
    required this.companyId,
    required this.name,
    required this.number,
    required this.email,
    required this.password,
    this.isAdmin = false,
    this.isOnline = false,
    required this.createdAt,
    this.sessionExpiresAt,
    this.shifts = const [],
  });

  // Role permissions
  bool get canManageUsers => isAdmin;
  bool get canCreateTables => isAdmin;
  bool get canSetTablePrices => isAdmin;
  bool get canManageRates => isAdmin;

  // Session state
  bool get isSessionValid =>
      sessionExpiresAt != null && DateTime.now().isBefore(sessionExpiresAt!);

  // Shift & working hours calculations
  Duration get totalWorkingDuration {
    Duration total = Duration.zero;
    for (final s in shifts) {
      total += s.duration;
    }
    return total;
  }

  UserShiftRecord? get activeShift {
    try {
      return shifts.firstWhere((s) => s.isActive);
    } catch (_) {
      return null;
    }
  }

  UserAccount copyWith({
    String? id,
    String? companyId,
    String? name,
    String? number,
    String? email,
    String? password,
    bool? isAdmin,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? sessionExpiresAt,
    List<UserShiftRecord>? shifts,
    bool clearSession = false,
  }) {
    return UserAccount(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      number: number ?? this.number,
      email: email ?? this.email,
      password: password ?? this.password,
      isAdmin: isAdmin ?? this.isAdmin,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      sessionExpiresAt: clearSession
          ? null
          : (sessionExpiresAt ?? this.sessionExpiresAt),
      shifts: shifts ?? this.shifts,
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
      'isOnline': isOnline,
      'createdAt': Timestamp.fromDate(createdAt),
      'sessionExpiresAt': sessionExpiresAt != null
          ? Timestamp.fromDate(sessionExpiresAt!)
          : null,
      'shifts': shifts.map((s) => s.toMap()).toList(),
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

    return UserAccount(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      number: map['number'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      isAdmin: map['isAdmin'] as bool? ?? false,
      isOnline: map['isOnline'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      sessionExpiresAt: parseOptionalDate(map['sessionExpiresAt']),
      shifts: (map['shifts'] as List<dynamic>?)
              ?.map(
                (e) => UserShiftRecord.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
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
        isOnline,
        createdAt,
        sessionExpiresAt,
        shifts,
      ];
}
