import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/expense_record.dart';
import '../../../domain/repositories/i_expense_repository.dart';

// Events
abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  @override
  List<Object?> get props => [];
}

class LoadExpensesEvent extends ExpenseEvent {
  final String branchId;
  final DateTime? month;
  const LoadExpensesEvent(this.branchId, {this.month});
  @override
  List<Object?> get props => [branchId, month];
}

class _ExpensesUpdatedEvent extends ExpenseEvent {
  final List<ExpenseRecord> expenses;
  const _ExpensesUpdatedEvent(this.expenses);
  @override
  List<Object?> get props => [expenses];
}

class AddExpenseAction extends ExpenseEvent {
  final ExpenseRecord expense;
  const AddExpenseAction(this.expense);
  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseAction extends ExpenseEvent {
  final String expenseId;
  const DeleteExpenseAction(this.expenseId);
  @override
  List<Object?> get props => [expenseId];
}

// State
class ExpenseState extends Equatable {
  final List<ExpenseRecord> expenses;
  final Map<ExpenseCategory, double> categoryBreakdown;
  final DateTime selectedMonth;
  final bool isLoading;
  final String? successMessage;

  const ExpenseState({
    this.expenses = const [],
    this.categoryBreakdown = const {},
    required this.selectedMonth,
    this.isLoading = false,
    this.successMessage,
  });

  double get totalExpenses =>
      expenses.fold(0.0, (acc, item) => acc + item.amount);

  ExpenseState copyWith({
    List<ExpenseRecord>? expenses,
    Map<ExpenseCategory, double>? categoryBreakdown,
    DateTime? selectedMonth,
    bool? isLoading,
    String? successMessage,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        expenses,
        categoryBreakdown,
        selectedMonth,
        isLoading,
        successMessage,
      ];
}

// BLoC
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final IExpenseRepository _expenseRepo;
  StreamSubscription<List<ExpenseRecord>>? _sub;

  ExpenseBloc({required IExpenseRepository expenseRepo})
      : _expenseRepo = expenseRepo,
        super(ExpenseState(selectedMonth: DateTime.now(), isLoading: true)) {
    on<LoadExpensesEvent>(_onLoadExpenses);
    on<_ExpensesUpdatedEvent>(_onExpensesUpdated);
    on<AddExpenseAction>(_onAddExpense);
    on<DeleteExpenseAction>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(LoadExpensesEvent event, Emitter<ExpenseState> emit) async {
    await _sub?.cancel();
    _sub = _expenseRepo.watchExpenses(event.branchId).listen((expenses) {
      add(_ExpensesUpdatedEvent(expenses));
    });

    final month = event.month ?? state.selectedMonth;
    final expenses = await _expenseRepo.getExpenses(event.branchId, monthDate: month);
    final breakdown = await _expenseRepo.getCategoryBreakdown(event.branchId, month);

    emit(state.copyWith(
      expenses: expenses,
      categoryBreakdown: breakdown,
      selectedMonth: month,
      isLoading: false,
    ));
  }

  void _onExpensesUpdated(_ExpensesUpdatedEvent event, Emitter<ExpenseState> emit) {
    emit(state.copyWith(expenses: event.expenses));
  }

  Future<void> _onAddExpense(AddExpenseAction event, Emitter<ExpenseState> emit) async {
    await _expenseRepo.logExpense(event.expense);
    emit(state.copyWith(successMessage: 'Operational expense logged successfully!'));
  }

  Future<void> _onDeleteExpense(DeleteExpenseAction event, Emitter<ExpenseState> emit) async {
    await _expenseRepo.deleteExpense(event.expenseId);
    emit(state.copyWith(successMessage: 'Expense deleted and flagged in audit log.'));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
