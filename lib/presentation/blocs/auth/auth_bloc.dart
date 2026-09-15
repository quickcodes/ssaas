import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/club_branch.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/user_account.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../domain/repositories/i_club_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class InitAuthEvent extends AuthEvent {}

class SwitchRoleEvent extends AuthEvent {
  final UserRole role;
  const SwitchRoleEvent(this.role);
  @override
  List<Object?> get props => [role];
}

class SwitchBranchEvent extends AuthEvent {
  final String branchId;
  const SwitchBranchEvent(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class CreateInitialWorkspaceEvent extends AuthEvent {
  final ClubBranch branch;
  final UserAccount owner;
  final List<UserAccount> users;
  final List<ClubTable> tables;

  const CreateInitialWorkspaceEvent({
    required this.branch,
    required this.owner,
    required this.users,
    required this.tables,
  });

  @override
  List<Object?> get props => [branch, owner, users, tables];
}

class LoginUserEvent extends AuthEvent {
  final UserAccount user;
  const LoginUserEvent(this.user);
  @override
  List<Object?> get props => [user];
}

class _UserUpdatedInternalEvent extends AuthEvent {
  final UserAccount? user;
  const _UserUpdatedInternalEvent(this.user);
  @override
  List<Object?> get props => [user];
}

// State
class AuthState extends Equatable {
  final UserAccount? currentUser;
  final List<UserAccount> availableUsers;
  final List<ClubBranch> branches;
  final ClubBranch? activeBranch;
  final bool isLoading;

  const AuthState({
    this.currentUser,
    this.availableUsers = const [],
    this.branches = const [],
    this.activeBranch,
    this.isLoading = false,
  });

  AuthState copyWith({
    UserAccount? currentUser,
    List<UserAccount>? availableUsers,
    List<ClubBranch>? branches,
    ClubBranch? activeBranch,
    bool? isLoading,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      availableUsers: availableUsers ?? this.availableUsers,
      branches: branches ?? this.branches,
      activeBranch: activeBranch ?? this.activeBranch,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    currentUser,
    availableUsers,
    branches,
    activeBranch,
    isLoading,
  ];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepo;
  final IClubRepository _clubRepo;
  StreamSubscription<UserAccount?>? _userSub;

  AuthBloc({
    required IAuthRepository authRepo,
    required IClubRepository clubRepo,
  }) : _authRepo = authRepo,
       _clubRepo = clubRepo,
       super(const AuthState(isLoading: true)) {
    on<InitAuthEvent>(_onInitAuth);
    on<SwitchRoleEvent>(_onSwitchRole);
    on<SwitchBranchEvent>(_onSwitchBranch);
    on<CreateInitialWorkspaceEvent>(_onCreateInitialWorkspace);
    on<LoginUserEvent>(_onLoginUser);
    on<_UserUpdatedInternalEvent>(_onUserUpdatedInternal);

    _userSub = _authRepo.watchCurrentUser().listen((user) {
      add(_UserUpdatedInternalEvent(user));
    });
  }

  Future<void> _onInitAuth(InitAuthEvent event, Emitter<AuthState> emit) async {
    final user = await _authRepo.getCurrentUser();
    final users = await _authRepo.getAvailableUsers();
    final branches = await _clubRepo.getBranches();
    ClubBranch? activeBranch;
    if (user != null) {
      activeBranch = branches.firstWhere(
        (b) => b.id == user.branchId,
        orElse: () => branches.first,
      );
    } else if (branches.isNotEmpty) {
      activeBranch = branches.first;
    }

    emit(
      state.copyWith(
        currentUser: user,
        availableUsers: users,
        branches: branches,
        activeBranch: activeBranch,
        isLoading: false,
      ),
    );
  }

  Future<void> _onSwitchRole(
    SwitchRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepo.switchUserRole(event.role);
    final user = await _authRepo.getCurrentUser();
    emit(state.copyWith(currentUser: user));
  }

  Future<void> _onSwitchBranch(
    SwitchBranchEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepo.switchBranch(event.branchId);
    final activeBranch = state.branches.firstWhere(
      (b) => b.id == event.branchId,
      orElse: () => state.branches.first,
    );
    final user = await _authRepo.getCurrentUser();
    emit(state.copyWith(activeBranch: activeBranch, currentUser: user));
  }

  Future<void> _onCreateInitialWorkspace(
    CreateInitialWorkspaceEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _clubRepo.saveBranch(event.branch);
    for (final user in event.users) {
      await _authRepo.saveUser(user);
    }
    for (final table in event.tables) {
      await _clubRepo.saveTable(table);
    }
    emit(AuthState(availableUsers: event.users, branches: [event.branch]));
  }

  Future<void> _onLoginUser(
    LoginUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepo.setCurrentUser(event.user);
    final branch = state.branches.firstWhere(
      (item) => item.id == event.user.branchId,
    );
    emit(state.copyWith(currentUser: event.user, activeBranch: branch));
  }

  void _onUserUpdatedInternal(
    _UserUpdatedInternalEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(currentUser: event.user));
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    return super.close();
  }
}
