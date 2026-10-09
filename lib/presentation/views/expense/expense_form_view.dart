import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/club_expense.dart';
import '../../../domain/entities/user_account.dart';
import 'add_expense_dialog.dart';

/// Full-page route for creating or editing an expense.
class ExpenseFormView extends StatelessWidget {
  final String companyId;
  final UserAccount currentUser;
  final ClubExpense? expense;

  const ExpenseFormView({
    super.key,
    required this.companyId,
    required this.currentUser,
    this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AddExpenseDialog(
              companyId: companyId,
              currentUser: currentUser,
              initialExpense: expense,
            ),
          ),
        ),
      ),
    );
  }
}
