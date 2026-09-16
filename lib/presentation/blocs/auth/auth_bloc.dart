import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/firestore_service.dart';
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
  final String companyId;
  final String emailOrNumber;
  final String password;

  const LoginCompanyUserEvent({
    required this.companyId,
    required this.emailOrNumber,
    required this.password,
  });

  @override
  List<Object?> get props => [companyId, emailOrNumber, password];
}

class LogoutEvent extends AuthEvent {}

class CreateCompanyWithAdminEvent extends AuthEvent {
  final String name;
  final String number;
  final DateTime expiryDate;
  final String initialUserName;
  final String initialUserNumber;
  final String initialUserEmail;
  final String initialUserPassword;

  const CreateCompanyWithAdminEvent({
    required this.name,
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

  const AuthState({
    this.currentUser,
    this.activeCompany,
    this.companies = const [],
    this.companyUsers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isSubscriptionExpired = false,
  });

  bool get isAuthenticated =>
      currentUser != null && activeCompany != null && !isSubscriptionExpired;

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
      ];
}

// -------------------------------------------------------------
// BLOC
// -------------------------------------------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirestoreService _firestoreService;
  StreamSubscription<Company?>? _companySub;
  StreamSubscription<List<UserAccount>>? _usersSub;

  AuthBloc({required FirestoreService firestoreService})
      : _firestoreService = firestoreService,
        super(const AuthState(isLoading: true)) {
    on<InitAuthEvent>(_onInitAuth);
    on<LoadCompaniesEvent>(_onLoadCompanies);
    on<SelectCompanyEvent>(_onSelectCompany);
    on<LoginCompanyUserEvent>(_onLoginCompanyUser);
    on<LogoutEvent>(_onLogout);
    on<CreateCompanyWithAdminEvent>(_onCreateCompanyWithAdmin);
    on<CreateCompanyUserEvent>(_onCreateCompanyUser);
    on<ToggleUserAdminStatusEvent>(_onToggleUserAdminStatus);
    on<ClearAuthErrorEvent>(_onClearAuthError);
    on<_CompanyUpdatedInternalEvent>(_onCompanyUpdatedInternal);
    on<_UsersUpdatedInternalEvent>(_onUsersUpdatedInternal);
  }

  Future<void> _onInitAuth(
    InitAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
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
      final company = await _firestoreService.getCompanyById(event.companyId);
      if (company == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Selected company was not found.',
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

      // Subscribe to active company to monitor expiry in real-time
      _companySub?.cancel();
      _companySub = _firestoreService.watchCompany(company.id).listen((updated) {
        add(_CompanyUpdatedInternalEvent(updated));
      });

      // Subscribe to company users
      _usersSub?.cancel();
      _usersSub =
          _firestoreService.watchCompanyUsers(company.id).listen((users) {
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
    emit(state.copyWith(companyUsers: event.users));
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _companySub?.cancel();
    await _usersSub?.cancel();
    emit(
      state.copyWith(
        clearCurrentUser: true,
        clearActiveCompany: true,
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
    if (state.currentUser?.isAdmin != true || state.activeCompany == null) {
      emit(state.copyWith(errorMessage: 'Only Admin users can create users.'));
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
    if (state.currentUser?.isAdmin != true || state.activeCompany == null) {
      emit(
        state.copyWith(
          errorMessage: 'Only Admin users can change user permissions.',
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
          successMessage: 'Admin status updated successfully.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onClearAuthError(
    ClearAuthErrorEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(clearErrorMessage: true, clearSuccessMessage: true));
  }

  @override
  Future<void> close() {
    _companySub?.cancel();
    _usersSub?.cancel();
    return super.close();
  }
}
