import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/i_expense_repository.dart';
import '../datasources/local_data_store.dart';

class ExpenseRepositoryImpl implements IExpenseRepository {
  final LocalDataStore _ds;
  ExpenseRepositoryImpl(this._ds);

  @override
  Stream<List<ExpenseRecord>> watchExpenses(String branchId) => _ds.watchExpenses(branchId);

  @override
  Future<List<ExpenseRecord>> getExpenses(String branchId, {DateTime? monthDate}) async {
    final list = _ds.getExpenses(branchId);
    if (monthDate != null) {
      return list.where((e) => e.date.year == monthDate.year && e.date.month == monthDate.month).toList();
    }
    return list;
  }

  @override
  Future<void> logExpense(ExpenseRecord expense) async {
    _ds.logExpense(expense);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    _ds.deleteExpense(expenseId);
  }

  @override
  Future<Map<ExpenseCategory, double>> getCategoryBreakdown(String branchId, DateTime monthDate) async {
    final expenses = await getExpenses(branchId, monthDate: monthDate);
    final map = <ExpenseCategory, double>{};
    for (final cat in ExpenseCategory.values) {
      map[cat] = 0.0;
    }
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map;
  }
}
