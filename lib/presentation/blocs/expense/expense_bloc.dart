import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_handler.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/club_expense.dart';
import '../../../domain/entities/user_account.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpensesEvent extends ExpenseEvent {
  final String companyId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadExpensesEvent(this.companyId, {this.startDate, this.endDate});

  @override
  List<Object?> get props => [companyId, startDate, endDate];
}

class AddExpenseEvent extends ExpenseEvent {
  final ClubExpense expense;
  final UserAccount operator;

  const AddExpenseEvent(this.expense, {required this.operator});

  @override
  List<Object?> get props => [expense, operator];
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String companyId;
  final String expenseId;
  final UserAccount operator;

  const DeleteExpenseEvent({
    required this.companyId,
    required this.expenseId,
    required this.operator,
  });

  @override
  List<Object?> get props => [companyId, expenseId, operator];
}

class SetExpenseDateFilterEvent extends ExpenseEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String filterPreset;

  const SetExpenseDateFilterEvent({
    required this.startDate,
    required this.endDate,
    this.filterPreset = 'Custom',
  });

  @override
  List<Object?> get props => [startDate, endDate, filterPreset];
}

class ClearExpenseMessagesEvent extends ExpenseEvent {}

class _ExpensesUpdatedEvent extends ExpenseEvent {
  final List<ClubExpense> expenses;
  const _ExpensesUpdatedEvent(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class _ExpensesLoadFailedEvent extends ExpenseEvent {
  final Object error;
  const _ExpensesLoadFailedEvent(this.error);

  @override
  List<Object?> get props => [error];
}

class ExpenseState extends Equatable {
  final String? companyId;
  final List<ClubExpense> expenses;
  final List<ClubExpense> filteredExpenses;
  final DateTime? startDate;
  final DateTime? endDate;
  final String activePreset;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ExpenseState({
    this.companyId,
    this.expenses = const [],
    this.filteredExpenses = const [],
    this.startDate,
    this.endDate,
    this.activePreset = 'This Month',
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  double get totalExpenseAmount => filteredExpenses.fold(
        0,
        (total, expense) => total + expense.amount,
      );

  Map<String, double> get categoryBreakdown {
    final breakdown = <String, double>{};
    for (final expense in filteredExpenses) {
      breakdown.update(
        expense.category,
        (amount) => amount + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return breakdown;
  }

  ExpenseState copyWith({
    String? companyId,
    bool clearCompanyId = false,
    List<ClubExpense>? expenses,
    List<ClubExpense>? filteredExpenses,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? activePreset,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ExpenseState(
      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      activePreset: activePreset ?? this.activePreset,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        companyId,
        expenses,
        filteredExpenses,
        startDate,
        endDate,
        activePreset,
        isLoading,
        errorMessage,
        successMessage,
      ];
}

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final FirestoreService _firestoreService;
  StreamSubscription<List<ClubExpense>>? _expensesSub;

  ExpenseBloc({required FirestoreService firestoreService})
      : _firestoreService = firestoreService,
        super(const ExpenseState()) {
    on<LoadExpensesEvent>(_onLoadExpenses);
    on<AddExpenseEvent>(_onAddExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<SetExpenseDateFilterEvent>(_onSetDateFilter);
    on<ClearExpenseMessagesEvent>(_onClearMessages);
    on<_ExpensesUpdatedEvent>(_onExpensesUpdated);
    on<_ExpensesLoadFailedEvent>(_onExpensesLoadFailed);
  }

  bool _canManageExpenses(UserAccount user) =>
      user.isOwner || user.isAdmin || user.isOnline;

  String _presetForRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return 'All Time';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startsToday = startDate.year == today.year &&
        startDate.month == today.month &&
        startDate.day == today.day;
    if (startsToday) return 'Today';
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    if (startDate.year == weekStart.year &&
        startDate.month == weekStart.month &&
        startDate.day == weekStart.day &&
        endDate.year == today.year &&
        endDate.month == today.month &&
        endDate.day == today.day) {
      return 'This Week';
    }
    if (startDate.year == today.year &&
        startDate.month == today.month &&
        startDate.day == 1 &&
        endDate.year == today.year &&
        endDate.month == today.month &&
        endDate.day == today.day) {
      return 'This Month';
    }
    return 'Custom';
  }

  Future<void> _onLoadExpenses(
    LoadExpensesEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    await _expensesSub?.cancel();
    emit(state.copyWith(
      companyId: event.companyId,
      startDate: event.startDate,
      endDate: event.endDate,
      activePreset: _presetForRange(event.startDate, event.endDate),
      isLoading: true,
      clearErrorMessage: true,
    ));
    _expensesSub = _firestoreService
        .watchCompanyExpenses(
          event.companyId,
          startDate: event.startDate,
          endDate: event.endDate,
        )
        .listen(
          (expenses) => add(_ExpensesUpdatedEvent(expenses)),
          onError: (Object error, StackTrace stackTrace) =>
              add(_ExpensesLoadFailedEvent(error)),
        );
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (!_canManageExpenses(event.operator)) {
      emit(state.copyWith(
        errorMessage: 'Only an owner, admin, or online employee can add expenses.',
      ));
      return;
    }
    if (event.expense.isOwnerOnly && !event.operator.isOwner) {
      emit(state.copyWith(
        errorMessage: 'Only the club owner can create owner-only expenses.',
      ));
      return;
    }
    ClubExpense? existingExpense;
    for (final item in state.expenses) {
      if (item.id == event.expense.id) {
        existingExpense = item;
        break;
      }
    }
    if (existingExpense?.isOwnerOnly == true && !event.operator.isOwner) {
      emit(state.copyWith(
        errorMessage: 'Only the club owner can edit this owner-only expense.',
      ));
      return;
    }
    if (event.expense.amount <= 0 || event.expense.title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter a title and a valid expense amount.'));
      return;
    }
    try {
      await _firestoreService.saveExpense(event.expense);
      emit(state.copyWith(successMessage: 'Expense saved successfully.'));
    } catch (error) {
      emit(state.copyWith(errorMessage: AppErrorHandler.format(error)));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (!_canManageExpenses(event.operator)) {
      emit(state.copyWith(
        errorMessage: 'Only an owner, admin, or online employee can delete expenses.',
      ));
      return;
    }
    final expense = state.expenses.where((item) => item.id == event.expenseId);
    if (expense.isNotEmpty && expense.first.isOwnerOnly && !event.operator.isOwner) {
      emit(state.copyWith(
        errorMessage: 'Only the club owner can delete this owner-only expense.',
      ));
      return;
    }
    try {
      await _firestoreService.deleteExpense(event.companyId, event.expenseId);
      emit(state.copyWith(successMessage: 'Expense deleted successfully.'));
    } catch (error) {
      emit(state.copyWith(errorMessage: AppErrorHandler.format(error)));
    }
  }

  Future<void> _onSetDateFilter(
    SetExpenseDateFilterEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    final companyId = state.companyId;
    if (companyId == null || companyId.isEmpty) return;
    add(LoadExpensesEvent(
      companyId,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
    emit(state.copyWith(activePreset: event.filterPreset));
  }

  void _onClearMessages(
    ClearExpenseMessagesEvent event,
    Emitter<ExpenseState> emit,
  ) {
    emit(state.copyWith(clearErrorMessage: true, clearSuccessMessage: true));
  }

  void _onExpensesUpdated(
    _ExpensesUpdatedEvent event,
    Emitter<ExpenseState> emit,
  ) {
    emit(state.copyWith(
      expenses: event.expenses,
      filteredExpenses: event.expenses,
      isLoading: false,
    ));
  }

  void _onExpensesLoadFailed(
    _ExpensesLoadFailedEvent event,
    Emitter<ExpenseState> emit,
  ) {
    emit(state.copyWith(
      isLoading: false,
      errorMessage: AppErrorHandler.format(event.error),
    ));
  }

  @override
  Future<void> close() async {
    await _expensesSub?.cancel();
    return super.close();
  }
}
