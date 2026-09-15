import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense_record.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/expense/expense_bloc.dart';

class ExpenseManagerView extends StatelessWidget {
  const ExpenseManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final activeUser = authState.currentUser;
        final activeBranch = authState.activeBranch;

        if (activeUser == null || activeBranch == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocConsumer<ExpenseBloc, ExpenseState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.tableAvailable,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header & Add Expense Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MONTHLY OPERATIONAL EXPENSE LEDGER',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Overheads: ${AppFormatters.currency(state.totalExpenses)}',
                            style: const TextStyle(color: AppColors.tableOccupied, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddExpenseDialog(context, activeUser, activeBranch.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Log New Expense'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Breakdown Cards
                  _buildCategoryGrid(state.categoryBreakdown),
                  const SizedBox(height: 24),

                  // Itemized Expense Table / List
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Itemized Overhead Transactions',
                          style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        if (state.expenses.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No expenses recorded for this period', style: TextStyle(color: AppColors.secondaryText)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.expenses.length,
                            separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorderStroke, height: 16),
                            itemBuilder: (context, index) {
                              final exp = state.expenses[index];
                              return _buildExpenseRow(context, exp, activeUser.role.canDeleteBillsOrOverride);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryGrid(Map<ExpenseCategory, double> breakdown) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 3;
        if (constraints.maxWidth < 650) {
          count = 1;
        } else if (constraints.maxWidth < 1000) {
          count = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ExpenseCategory.values.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, index) {
            final cat = ExpenseCategory.values[index];
            final amount = breakdown[cat] ?? 0.0;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getCategoryIcon(cat), color: AppColors.brandAccentLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat.displayName, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.currency(amount),
                          style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseRow(BuildContext context, ExpenseRecord exp, bool canDelete) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.inputSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getCategoryIcon(exp.category), color: AppColors.brandAccentLight, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exp.description, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Vendor: ${exp.vendorName} • Logged by ${exp.loggedByOperatorName}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            exp.date.toLocal().toString().substring(0, 10),
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
        ),
        Text(
          AppFormatters.currency(exp.amount),
          style: const TextStyle(color: AppColors.tableOccupied, fontWeight: FontWeight.w800, fontSize: 14),
        ),
        if (canDelete) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.secondaryText, size: 18),
            tooltip: 'Delete Expense',
            onPressed: () {
              context.read<ExpenseBloc>().add(DeleteExpenseAction(exp.id));
            },
          ),
        ],
      ],
    );
  }

  IconData _getCategoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.rent:
        return Icons.apartment;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.staffSalaries:
        return Icons.people_outline;
      case ExpenseCategory.maintenanceRepairs:
        return Icons.build_outlined;
      case ExpenseCategory.inventorySourcing:
        return Icons.inventory_2_outlined;
      case ExpenseCategory.miscellaneous:
        return Icons.receipt_long_outlined;
    }
  }

  void _showAddExpenseDialog(BuildContext context, dynamic activeUser, String branchId) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final vendorController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.utilities;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorderStroke),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'LOG OPERATIONAL OVERHEAD EXPENSE',
                      style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) *',
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: selectedCategory,
                      dropdownColor: AppColors.cardSurface,
                      decoration: const InputDecoration(labelText: 'Expense Category *'),
                      items: ExpenseCategory.values.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.displayName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Purpose *',
                        hintText: 'e.g. August Torrent Electricity Bill',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: vendorController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier / Vendor Name *',
                        hintText: 'e.g. Torrent Power Ltd',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final amount = double.tryParse(amountController.text.trim());
                              final desc = descController.text.trim();
                              final vendor = vendorController.text.trim();

                              if (amount == null || amount <= 0 || desc.isEmpty || vendor.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill all required expense fields')),
                                );
                                return;
                              }

                              final newExpense = ExpenseRecord(
                                id: const Uuid().v4(),
                                branchId: branchId,
                                category: selectedCategory,
                                amount: amount,
                                description: desc,
                                vendorName: vendor,
                                receiptAttachmentName: 'manual_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
                                loggedByOperatorId: activeUser.id,
                                loggedByOperatorName: activeUser.name,
                                date: DateTime.now(),
                              );

                              context.read<ExpenseBloc>().add(AddExpenseAction(newExpense));
                              Navigator.of(dialogCtx).pop();
                            },
                            child: const Text('Save Expense'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
