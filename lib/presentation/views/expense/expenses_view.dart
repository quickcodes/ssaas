import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/club_expense.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../../widgets/empty_state_card.dart';
import '../dashboard/user_online_status_dialog.dart';
import 'expense_analytics_card.dart';
import 'expense_form_view.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  String _searchQuery = '';
  String _category = 'All';
  final _searchController = TextEditingController();
  Timer? _permissionSnackBarDismissTimer;

  @override
  void dispose() {
    _permissionSnackBarDismissTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  DateTime _dayStart(DateTime value) => DateTime(value.year, value.month, value.day);
  DateTime _dayEnd(DateTime value) => DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  void _showExpensePermissionSnackBar(UserAccount currentUser) {
    final activeCompany = context.read<AuthBloc>().state.activeCompany;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    _permissionSnackBarDismissTimer?.cancel();
    AppHaptics.error();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Only an owner, admin, or active Online employee can add expenses. Please switch to Online first.',
        ),
        backgroundColor: AppColors.tableOccupied,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: activeCompany == null
            ? null
            : SnackBarAction(
                label: 'GO ONLINE',
                textColor: AppColors.primaryText,
                onPressed: () {
                  _permissionSnackBarDismissTimer?.cancel();
                  messenger.hideCurrentSnackBar();
                  showDialog(
                    context: context,
                    builder: (_) => UserOnlineStatusDialog(
                      currentUser: currentUser,
                      activeCompany: activeCompany,
                    ),
                  );
                },
              ),
      ),
    );
    _permissionSnackBarDismissTimer = Timer(const Duration(seconds: 4), () {
      try {
        controller.close();
      } catch (_) {}
    });
    controller.closed.then((_) => _permissionSnackBarDismissTimer?.cancel());
  }

  void _setPreset(String preset) {
    final now = DateTime.now();
    if (preset == 'All Time') {
      context.read<ExpenseBloc>().add(LoadExpensesEvent(context.read<AuthBloc>().state.activeCompany!.id));
      return;
    }
    final start = switch (preset) {
      'Today' => _dayStart(now),
      'This Week' => _dayStart(now.subtract(Duration(days: now.weekday - 1))),
      _ => DateTime(now.year, now.month),
    };
    context.read<ExpenseBloc>().add(SetExpenseDateFilterEvent(
          startDate: start,
          endDate: _dayEnd(now),
          filterPreset: preset,
        ));
  }

  Future<void> _selectCustomRange() async {
    final state = context.read<ExpenseBloc>().state;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : DateTimeRange(start: DateTime(now.year, now.month), end: now),
    );
    if (range == null || !mounted) return;
    AppHaptics.selection();
    context.read<ExpenseBloc>().add(SetExpenseDateFilterEvent(
          startDate: _dayStart(range.start),
          endDate: _dayEnd(range.end),
          filterPreset: 'Custom',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        context.read<ExpenseBloc>().add(ClearExpenseMessagesEvent());
      },
      builder: (context, expenseState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final currentUser = authState.currentUser;
            final company = authState.activeCompany;
            if (currentUser == null || company == null) return const SizedBox.shrink();
            final ownerVisibleExpenses = expenseState.filteredExpenses.where(
              (expense) => !expense.isOwnerOnly || currentUser.isOwner,
            );
            final visibleExpenses = ownerVisibleExpenses.where((expense) {
              final matchesSearch = expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  expense.addedBy.toLowerCase().contains(_searchQuery.toLowerCase());
              return matchesSearch && (_category == 'All' || expense.category == _category);
            }).toList();
            final categories = {
              'All',
              ...ownerVisibleExpenses.map((expense) => expense.category),
            }.toList();
            final canManage = currentUser.isOwner || currentUser.isAdmin || currentUser.isOnline;
            return Scaffold(
              backgroundColor: AppColors.backgroundBase,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                        if (!canManage) {
                          _showExpensePermissionSnackBar(currentUser);
                          return;
                        }
                        AppHaptics.light();
                        AppNavigation.pushSmooth(
                          context,
                          ExpenseFormView(
                            companyId: company.id,
                            currentUser: currentUser,
                          ),
                        );
                      },
                backgroundColor: AppColors.brandAccent,
                foregroundColor: AppColors.primaryText,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Expense Management', style: TextStyle(color: AppColors.primaryText, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Track and analyze your club operating costs.', style: TextStyle(color: AppColors.secondaryText)),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        ...['Today', 'This Week', 'This Month', 'All Time'].map((preset) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(preset), selected: expenseState.activePreset == preset,
                            selectedColor: AppColors.brandAccent.withAlpha(75), backgroundColor: AppColors.cardSurface,
                            side: const BorderSide(color: AppColors.cardBorderStroke), labelStyle: const TextStyle(color: AppColors.primaryText),
                            onSelected: (_) { AppHaptics.selection(); _setPreset(preset); },
                          ),
                        )),
                        ChoiceChip(
                          label: const Text('Custom'), selected: expenseState.activePreset == 'Custom',
                          selectedColor: AppColors.brandAccent.withAlpha(75), backgroundColor: AppColors.cardSurface,
                          side: const BorderSide(color: AppColors.cardBorderStroke), labelStyle: const TextStyle(color: AppColors.primaryText),
                          onSelected: (_) => _selectCustomRange(),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    ExpenseAnalyticsCard(
                      totalAmount: ownerVisibleExpenses.fold(
                        0,
                        (total, expense) => total + expense.amount,
                      ),
                      categoryBreakdown: _categoryBreakdown(
                        ownerVisibleExpenses.toList(),
                      ),
                      periodLabel: expenseState.activePreset,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.primaryText),
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search expenses or operator', hintStyle: const TextStyle(color: AppColors.secondaryText),
                        prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText), filled: true, fillColor: AppColors.inputSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorderStroke)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category), selected: _category == category,
                          selectedColor: AppColors.brandAccent.withAlpha(60), backgroundColor: AppColors.cardSurface,
                          labelStyle: const TextStyle(color: AppColors.primaryText), side: const BorderSide(color: AppColors.cardBorderStroke),
                          onSelected: (_) { AppHaptics.selection(); setState(() => _category = category); },
                        ),
                      )).toList()),
                    ),
                    const SizedBox(height: 14),
                    if (expenseState.isLoading)
                      const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.brandAccent)))
                    else if (visibleExpenses.isEmpty)
                      EmptyStateCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'No expenses found',
                        subtitle: 'Record club costs here to see spending insights.',
                        actionLabel: canManage ? 'Add Expense' : null,
                        onAction: canManage
                            ? () => AppNavigation.pushSmooth(
                                  context,
                                  ExpenseFormView(
                                    companyId: company.id,
                                    currentUser: currentUser,
                                  ),
                                )
                            : null,
                      )
                    else
                      ...visibleExpenses.map((expense) => _ExpenseCard(expense: expense, currentUser: currentUser)),
                    const SizedBox(height: 84),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _categoryBreakdown(List<ClubExpense> expenses) {
    final breakdown = <String, double>{};
    for (final expense in expenses) {
      breakdown.update(
        expense.category,
        (amount) => amount + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return breakdown;
  }
}

class _ExpenseCard extends StatelessWidget {
  final ClubExpense expense;
  final UserAccount currentUser;

  const _ExpenseCard({required this.expense, required this.currentUser});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showAdaptiveModal<bool>(
      context: context,
      builder: (dialogContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(dialogContext).size.height * .9,
          maxWidth: 440,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.cardBorderStroke),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Delete expense?', style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('“${expense.title}” will be permanently removed.', style: const TextStyle(color: AppColors.secondaryText)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.tableOccupied, foregroundColor: AppColors.primaryText), child: const Text('Delete'))),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    AppHaptics.light();
    context.read<ExpenseBloc>().add(DeleteExpenseEvent(
          companyId: expense.companyId,
          expenseId: expense.id,
          operator: currentUser,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final canManage = currentUser.isOwner || currentUser.isAdmin || currentUser.isOnline;
    final canDelete = canManage && (!expense.isOwnerOnly || currentUser.isOwner);
    final canEdit = canManage && (!expense.isOwnerOnly || currentUser.isOwner);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorderStroke)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.brandAccent.withAlpha(30), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_outlined, color: AppColors.brandAccentLight)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 15))),
            Text('₹${expense.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 7, runSpacing: 5, children: [
            _Tag(expense.category), _Tag(expense.paymentMethod),
            if (expense.isOwnerOnly) const _Tag('Owner only'),
            Text(DateFormat('dd MMM, hh:mm a').format(expense.expenseDate), style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text('Added by ${expense.addedBy.isEmpty ? 'Unknown' : expense.addedBy}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          if (expense.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(expense.notes, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12))),
        ])),
        if (canEdit || canDelete) Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit) IconButton(
              tooltip: 'Edit expense',
              icon: const Icon(Icons.edit_outlined, color: AppColors.brandAccentLight),
              onPressed: () {
                AppHaptics.light();
                AppNavigation.pushSmooth(
                  context,
                  ExpenseFormView(
                    companyId: expense.companyId,
                    currentUser: currentUser,
                    expense: expense,
                  ),
                );
              },
            ),
            if (canDelete) IconButton(
              tooltip: 'Delete expense', icon: const Icon(Icons.delete_outline, color: AppColors.tableOccupied),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: AppColors.inputSurface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.cardBorderStroke)),
    child: Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}
