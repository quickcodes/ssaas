import '../entities/expense_record.dart';

abstract class IExpenseRepository {
  Stream<List<ExpenseRecord>> watchExpenses(String branchId);
  Future<List<ExpenseRecord>> getExpenses(String branchId, {DateTime? monthDate});
  Future<void> logExpense(ExpenseRecord expense);
  Future<void> deleteExpense(String expenseId);
  Future<Map<ExpenseCategory, double>> getCategoryBreakdown(String branchId, DateTime monthDate);
}
