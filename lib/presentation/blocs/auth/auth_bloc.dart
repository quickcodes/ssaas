import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../data/datasources/session_local_storage.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';

// -------------------------------------------------------------
// EVENTS
// -------------------------------------------------------------

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class InitAuthEvent extends AuthEvent {}

class LoadCompaniesEvent extends AuthEvent {}

class SelectCompanyEvent extends AuthEvent {
  final Company company;
  const SelectCompanyEvent(this.company);
  @override
  List<Object?> get props => [company];
}

class LoginCompanyUserEvent extends AuthEvent {
  final String companyCode;
  final String emailOrNumber;
  final String password;

  const LoginCompanyUserEvent({
    required this.companyCode,
    required this.emailOrNumber,
    required this.password,
  });

  @override
  List<Object?> get props => [companyCode, emailOrNumber, password];
}

class LogoutEvent extends AuthEvent {}

class CreateCompanyWithAdminEvent extends AuthEvent {
  final String name;
  final String code;
  final String number;
  final DateTime expiryDate;
  final String initialUserName;
  final String initialUserNumber;
  final String initialUserEmail;
  final String initialUserPassword;

  const CreateCompanyWithAdminEvent({
    required this.name,
    required this.code,
    required this.number,
    required this.expiryDate,
    required this.initialUserName,
    required this.initialUserNumber,
    required this.initialUserEmail,
    required this.initialUserPassword,
  });

  @override
  List<Object?> get props => [
        name,
        code,
        number,
        expiryDate,
        initialUserName,
        initialUserNumber,
        initialUserEmail,
        initialUserPassword,
      ];
}

class CreateCompanyUserEvent extends AuthEvent {
  final UserAccount user;
  const CreateCompanyUserEvent(this.user);
  @override
  List<Object?> get props => [user];
}

class ToggleUserAdminStatusEvent extends AuthEvent {
  final String userId;
  final bool isAdmin;
  const ToggleUserAdminStatusEvent({
    required this.userId,
    required this.isAdmin,
  });
  @override
  List<Object?> get props => [userId, isAdmin];
}

class ToggleUserActiveStatusEvent extends AuthEvent {
  final String userId;
  final bool isActive;
  const ToggleUserActiveStatusEvent({
    required this.userId,
    required this.isActive,
  });
  @override
  List<Object?> get props => [userId, isActive];
}

class UpdateUserRoleEvent extends AuthEvent {
  final String userId;
  final String role;
  const UpdateUserRoleEvent({
    required this.userId,
    required this.role,
  });
  @override
  List<Object?> get props => [userId, role];
}

class ToggleUserOnlineStatusEvent extends AuthEvent {
  final String userId;
  final bool isOnline;
  const ToggleUserOnlineStatusEvent({
    required this.userId,
    required this.isOnline,
  });
  @override
  List<Object?> get props => [userId, isOnline];
}

class ClearAuthErrorEvent extends AuthEvent {}

class _CompanyUpdatedInternalEvent extends AuthEvent {
  final Company? company;
  const _CompanyUpdatedInternalEvent(this.company);
  @override
  List<Object?> get props => [company];
}

class _UsersUpdatedInternalEvent extends AuthEvent {
  final List<UserAccount> users;
  const _UsersUpdatedInternalEvent(this.users);
  @override
  List<Object?> get props => [users];
}

// -------------------------------------------------------------
// STATE
// -------------------------------------------------------------

class AuthState extends Equatable {
  final UserAccount? currentUser;
  final Company? activeCompany;
  final List<Company> companies;
  final List<UserAccount> companyUsers;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubscriptionExpired;
  final bool isUserDeactivated;

  const AuthState({
    this.currentUser,
    this.activeCompany,
    this.companies = const [],
    this.companyUsers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isSubscriptionExpired = false,
    this.isUserDeactivated = false,
  });

  bool get isAuthenticated =>
      currentUser != null &&
      activeCompany != null &&
      !isSubscriptionExpired &&
      !isUserDeactivated;

  AuthState copyWith({
    UserAccount? currentUser,
    bool clearCurrentUser = false,
    Company? activeCompany,
    bool clearActiveCompany = false,
    List<Company>? companies,
    List<UserAccount>? companyUsers,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    bool? isSubscriptionExpired,
    bool? isUserDeactivated,
  }) {
    return AuthState(
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      activeCompany: clearActiveCompany
          ? null
          : (activeCompany ?? this.activeCompany),
      companies: companies ?? this.companies,
      companyUsers: companyUsers ?? this.companyUsers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      isSubscriptionExpired:
          isSubscriptionExpired ?? this.isSubscriptionExpired,
      isUserDeactivated:
          isUserDeactivated ?? (clearErrorMessage ? false : this.isUserDeactivated),
    );
  }

  @override
  List<Object?> get props => [
        currentUser,
        activeCompany,
        companies,
        companyUsers,
        isLoading,
        errorMessage,
        successMessage,
        isSubscriptionExpired,
        isUserDeactivated,
      ];
}

// -------------------------------------------------------------
// BLOC
// -------------------------------------------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirestoreService _firestoreService;
  final SessionLocalStorage _sessionLocalStorage;
  StreamSubscription<Company?>? _companySub;
  StreamSubscription<List<UserAccount>>? _usersSub;

  AuthBloc({
    required FirestoreService firestoreService,
    required SessionLocalStorage sessionLocalStorage,
  })  : _firestoreService = firestoreService,
        _sessionLocalStorage = sessionLocalStorage,
        super(const AuthState(isLoading: true)) {
    on<InitAuthEvent>(_onInitAuth);
    on<LoadCompaniesEvent>(_onLoadCompanies);
    on<SelectCompanyEvent>(_onSelectCompany);
    on<LoginCompanyUserEvent>(_onLoginCompanyUser);
    on<LogoutEvent>(_onLogout);
    on<CreateCompanyWithAdminEvent>(_onCreateCompanyWithAdmin);
    on<CreateCompanyUserEvent>(_onCreateCompanyUser);
    on<ToggleUserAdminStatusEvent>(_onToggleUserAdminStatus);
    on<ToggleUserActiveStatusEvent>(_onToggleUserActiveStatus);
    on<UpdateUserRoleEvent>(_onUpdateUserRole);
    on<ToggleUserOnlineStatusEvent>(_onToggleUserOnlineStatus);
    on<ClearAuthErrorEvent>(_onClearAuthError);
    on<_CompanyUpdatedInternalEvent>(_onCompanyUpdatedInternal);
    on<_UsersUpdatedInternalEvent>(_onUsersUpdatedInternal);

    // Automatically trigger auth verification upon bloc creation
    add(InitAuthEvent());
  }

  Future<void> _onInitAuth(
    InitAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      // 1. Check if there is an active local session
      final session = await _sessionLocalStorage.getSession();
      if (session != null &&
          !session.isExpired &&
          session.companyId.isNotEmpty &&
          session.userId.isNotEmpty) {
        // 2. Fetch company and check subscription
        var company =
            await _firestoreService.getCompanyById(session.companyId);
        if (company != null && !company.isExpired) {
          // Ensure dueBufferAmount is present in company details and store if missing
          company = await _firestoreService.ensureCompanyDueBuffer(company);

          // 3. Verify user and check 10-day session expiry stored in Firebase DB
          final user = await _firestoreService.getUserById(
            session.companyId,
            session.userId,
          );
          if (user != null && user.isSessionValid) {
            if (!user.isActive) {
              debugPrint(
                '[AuthBloc] User account is deactivated. Clearing local session.',
              );
              await _sessionLocalStorage.clearSession();
              final companies = await _firestoreService.getCompanies();
              emit(
                state.copyWith(
                  companies: companies,
                  isLoading: false,
                  isUserDeactivated: true,
                  errorMessage:
                      'Your account has been deactivated by the club owner. Please contact your club owner to regain access.',
                ),
              );
              return;
            }

            debugPrint(
              '[AuthBloc] Valid session found for ${user.name}. Auto-logging in...',
            );
            // Active session verified in Firebase DB! Auto-login
            _companySub?.cancel();
            _companySub =
                _firestoreService.watchCompany(company.id).listen((updated) {
              add(_CompanyUpdatedInternalEvent(updated));
            });

            _usersSub?.cancel();
            _usersSub = _firestoreService
                .watchCompanyUsers(company.id)
                .listen((users) {
              add(_UsersUpdatedInternalEvent(users));
            });

            emit(
              state.copyWith(
                currentUser: user,
                activeCompany: company,
                isLoading: false,
                isSubscriptionExpired: false,
                clearErrorMessage: true,
              ),
            );
            return;
          } else {
            debugPrint(
              '[AuthBloc] User session invalid or expired in DB. Clearing local session.',
            );
            await _sessionLocalStorage.clearSession();
          }
        } else {
          debugPrint(
            '[AuthBloc] Company not found or subscription expired. Clearing local session.',
          );
          await _sessionLocalStorage.clearSession();
          if (company != null && company.isExpired) {
            final companies = await _firestoreService.getCompanies();
            emit(
              state.copyWith(
                companies: companies,
                isLoading: false,
                isSubscriptionExpired: true,
                errorMessage:
                    'Subscription for "${company.name}" has expired. Direct app access is disabled. Please contact developers to extend your subscription.',
              ),
            );
            return;
          }
        }
      } else if (session != null && session.isExpired) {
        await _sessionLocalStorage.clearSession();
      }

      // If no valid session exists, load companies for login screen
      final companies = await _firestoreService.getCompanies();
      emit(state.copyWith(companies: companies, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadCompanies(
    LoadCompaniesEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final companies = await _firestoreService.getCompanies();
      emit(state.copyWith(companies: companies));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onSelectCompany(
    SelectCompanyEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(activeCompany: event.company));
  }

  Future<void> _onLoginCompanyUser(
    LoginCompanyUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      final cleanCode = event.companyCode.trim().toUpperCase();
      final company = await _firestoreService.getCompanyByCode(cleanCode);
      if (company == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage:
                'Invalid company code. No club found with code "$cleanCode".',
          ),
        );
        return;
      }

      // Check subscription expiry
      if (company.isExpired) {
        emit(
          state.copyWith(
            isLoading: false,
            isSubscriptionExpired: true,
            errorMessage:
                'Subscription for "${company.name}" has expired. Direct app access is disabled. Please contact developers to extend your subscription in Firebase Firestore.',
          ),
        );
        return;
      }

      // Authenticate user
      final user = await _firestoreService.loginUser(
        company.id,
        event.emailOrNumber,
        event.password,
      );

      if (user == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Invalid email/phone number or password.',
          ),
        );
        return;
      }

      if (!user.isActive) {
        emit(
          state.copyWith(
            isLoading: false,
            isUserDeactivated: true,
            errorMessage:
                'Your account has been deactivated by the club owner. Please contact your club owner for assistance.',
          ),
        );
        return;
      }

      // Configure 10-day session: Store in Firebase DB on that user doc & locally
      final sessionExpiresAt = DateTime.now().add(const Duration(days: 10));
      await _firestoreService.updateUserSession(
        company.id,
        user.id,
        sessionExpiresAt,
      );
      await _sessionLocalStorage.saveSession(
        companyId: company.id,
        userId: user.id,
        expiresAt: sessionExpiresAt,
      );

      final userWithSession = user.copyWith(sessionExpiresAt: sessionExpiresAt);

      // Ensure dueBufferAmount is present in company details and store if missing
      final updatedCompany =
          await _firestoreService.ensureCompanyDueBuffer(company);

      // Subscribe to active company to monitor expiry in real-time
      _companySub?.cancel();
      _companySub =
          _firestoreService.watchCompany(updatedCompany.id).listen((updated) {
        add(_CompanyUpdatedInternalEvent(updated));
      });

      // Subscribe to company users
      _usersSub?.cancel();
      _usersSub = _firestoreService
          .watchCompanyUsers(updatedCompany.id)
          .listen((users) {
        add(_UsersUpdatedInternalEvent(users));
      });

      emit(
        state.copyWith(
          currentUser: userWithSession,
          activeCompany: updatedCompany,
          isLoading: false,
          isSubscriptionExpired: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onCompanyUpdatedInternal(
    _CompanyUpdatedInternalEvent event,
    Emitter<AuthState> emit,
  ) {
    if (event.company == null) return;
    final company = event.company!;
    if (company.isExpired) {
      // Auto-logout user immediately if expiry date has passed
      _companySub?.cancel();
      _usersSub?.cancel();
      _sessionLocalStorage.clearSession();
      emit(
        state.copyWith(
          clearCurrentUser: true,
          activeCompany: company,
          isSubscriptionExpired: true,
          errorMessage:
              'Subscription for "${company.name}" has expired. You have been logged out. Please contact developers to extend your subscription.',
        ),
      );
    } else {
      emit(state.copyWith(activeCompany: company, isSubscriptionExpired: false));
    }
  }

  void _onUsersUpdatedInternal(
    _UsersUpdatedInternalEvent event,
    Emitter<AuthState> emit,
  ) {
    UserAccount? updatedCurrentUser = state.currentUser;
    if (state.currentUser != null) {
      try {
        updatedCurrentUser =
            event.users.firstWhere((u) => u.id == state.currentUser!.id);
      } catch (_) {}
    }

    // Check if the currently logged-in user has been deactivated in real-time
    if (state.currentUser != null &&
        updatedCurrentUser != null &&
        !updatedCurrentUser.isActive) {
      _companySub?.cancel();
      _usersSub?.cancel();
      _sessionLocalStorage.clearSession();
      emit(
        state.copyWith(
          clearCurrentUser: true,
          companyUsers: event.users,
          isUserDeactivated: true,
          errorMessage:
              'Your account has been deactivated by the club owner. You have been logged out. Please contact the owner for assistance.',
        ),
      );
      return;
    }

    emit(state.copyWith(
      companyUsers: event.users,
      currentUser: updatedCurrentUser,
    ));
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _companySub?.cancel();
    await _usersSub?.cancel();

    // Invalidate session and clear online shift in Firebase DB and locally
    if (state.activeCompany != null && state.currentUser != null) {
      try {
        await _firestoreService.updateUserSession(
          state.activeCompany!.id,
          state.currentUser!.id,
          null,
        );
        if (state.currentUser!.isOnline) {
          await _firestoreService.setUserOnlineStatus(
            companyId: state.activeCompany!.id,
            userId: state.currentUser!.id,
            isOnline: false,
          );
        }
      } catch (_) {}
    }
    await _sessionLocalStorage.clearSession();

    final companies = await _firestoreService.getCompanies();

    emit(
      state.copyWith(
        clearCurrentUser: true,
        clearActiveCompany: true,
        companies: companies,
        isSubscriptionExpired: false,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onCreateCompanyWithAdmin(
    CreateCompanyWithAdminEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      final newCompany = await _firestoreService.createCompanyWithInitialAdmin(
        name: event.name,
        code: event.code,
        number: event.number,
        expiryDate: event.expiryDate,
        initialUserName: event.initialUserName,
        initialUserNumber: event.initialUserNumber,
        initialUserEmail: event.initialUserEmail,
        initialUserPassword: event.initialUserPassword,
      );

      final companies = await _firestoreService.getCompanies();
      emit(
        state.copyWith(
          isLoading: false,
          companies: companies,
          activeCompany: newCompany,
          successMessage:
              'Company "${newCompany.name}" and initial Admin user created successfully!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateCompanyUser(
    CreateCompanyUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    if ((state.currentUser?.isOwner != true && state.currentUser?.isAdmin != true) || state.activeCompany == null) {
      emit(state.copyWith(errorMessage: 'Only the Club Owner can create new users.'));
      return;
    }
    emit(state.copyWith(isLoading: true));
    try {
      await _firestoreService.createUser(event.user);
      emit(
        state.copyWith(
          isLoading: false,
          successMessage: 'User "${event.user.name}" created successfully.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleUserAdminStatus(
    ToggleUserAdminStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state.currentUser?.isOwner != true || state.activeCompany == null) {
      emit(
        state.copyWith(
          errorMessage: 'Only the Club Owner can change user roles.',
        ),
      );
      return;
    }
    try {
      await _firestoreService.updateUserAdminStatus(
        state.activeCompany!.id,
        event.userId,
        event.isAdmin,
      );
      emit(
        state.copyWith(
          successMessage: 'User role updated successfully.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleUserActiveStatus(
    ToggleUserActiveStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state.currentUser?.isOwner != true || state.activeCompany == null) {
      emit(
        state.copyWith(
          errorMessage: 'Only the Club Owner can activate or deactivate accounts.',
        ),
      );
      return;
    }
    if (state.currentUser?.id == event.userId) {
      emit(
        state.copyWith(
          errorMessage: 'You cannot deactivate your own account.',
        ),
      );
      return;
    }
    try {
      await _firestoreService.updateUserActiveStatus(
        state.activeCompany!.id,
        event.userId,
        event.isActive,
      );
      emit(
        state.copyWith(
          successMessage: event.isActive
              ? 'User account activated successfully.'
              : 'User account deactivated successfully.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRoleEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state.currentUser?.isOwner != true || state.activeCompany == null) {
      emit(
        state.copyWith(
          errorMessage: 'Only the Club Owner can modify user roles.',
        ),
      );
      return;
    }
    try {
      await _firestoreService.updateUserRole(
        state.activeCompany!.id,
        event.userId,
        event.role,
      );
      emit(
        state.copyWith(
          successMessage: 'User role updated to ${event.role.toUpperCase()}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleUserOnlineStatus(
    ToggleUserOnlineStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state.activeCompany == null) return;
    try {
      final result = await _firestoreService.setUserOnlineStatus(
        companyId: state.activeCompany!.id,
        userId: event.userId,
        isOnline: event.isOnline,
      );

      if (!result.success) {
        emit(
          state.copyWith(
            errorMessage:
                '${result.conflictingUserName ?? "Another operator"} is currently online. They must go offline before you can go online.',
          ),
        );
        return;
      }

      if (state.currentUser?.id == event.userId) {
        emit(
          state.copyWith(
            currentUser: state.currentUser!.copyWith(isOnline: event.isOnline),
            successMessage: event.isOnline
                ? 'You are now ONLINE. You can now open and close tables.'
                : 'You are now OFFLINE.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            successMessage: event.isOnline
                ? 'Operator status updated to ONLINE.'
                : 'Operator status updated to OFFLINE.',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onClearAuthError(
    ClearAuthErrorEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
      isUserDeactivated: false,
    ));
  }

  @override
  Future<void> close() {
    _companySub?.cancel();
    _usersSub?.cancel();
    return super.close();
  }
}
