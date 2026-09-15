import 'package:equatable/equatable.dart';

enum UserRole {
  superAdmin,
  counterAdmin,
  attendantMarker;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin (Owner)';
      case UserRole.counterAdmin:
        return 'Counter Admin (Cashier)';
      case UserRole.attendantMarker:
        return 'Attendant / Marker';
    }
  }

  bool get canViewFinancials => this != UserRole.attendantMarker;
  bool get canManageRates => this == UserRole.superAdmin;
  bool get canDeleteBillsOrOverride => this == UserRole.superAdmin;
  bool get canAccessNetProfitLedger => this == UserRole.superAdmin;
  bool get canManageExpenses => this != UserRole.attendantMarker;
  bool get canControlTimers => this != UserRole.attendantMarker;
  bool get canSellCanteen => this != UserRole.attendantMarker;
  bool get canPerformShiftHandover => this == UserRole.counterAdmin || this == UserRole.superAdmin;
}

class UserAccount extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String branchId;

  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.branchId,
  });

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? branchId,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, branchId];
}
