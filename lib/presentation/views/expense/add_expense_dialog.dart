import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/club_expense.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/expense/expense_bloc.dart';

class AddExpenseDialog extends StatefulWidget {
  final String companyId;
  final UserAccount currentUser;
  final ClubExpense? initialExpense;

  const AddExpenseDialog({
    super.key,
    required this.companyId,
    required this.currentUser,
    this.initialExpense,
  });

  static Future<void> show(
    BuildContext context, {
    required String companyId,
    required UserAccount currentUser,
  }) {
    return showAdaptiveModal<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: AddExpenseDialog(
          companyId: companyId,
          currentUser: currentUser,
        ),
      ),
    );
  }

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  static const _categories = [
    'Utilities',
    'Maintenance',
    'Inventory Stock',
    'Rent',
    'Staff Salary',
    'Other',
  ];
  static const _paymentMethods = ['Cash', 'UPI', 'Card'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = _categories.first;
  String _paymentMethod = _paymentMethods.first;
  DateTime _expenseDate = DateTime.now();
  bool _isOwnerOnly = false;

  bool get _isEditing => widget.initialExpense != null;

  bool get _canManage =>
      widget.currentUser.isOwner ||
      widget.currentUser.isAdmin ||
      widget.currentUser.isOnline;

  @override
  void initState() {
    super.initState();
    final expense = widget.initialExpense;
    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _notesController.text = expense.notes;
      _category = _categories.contains(expense.category)
          ? expense.category
          : _categories.last;
      _paymentMethod = _paymentMethods.contains(expense.paymentMethod)
          ? expense.paymentMethod
          : _paymentMethods.first;
      _expenseDate = expense.expenseDate;
      _isOwnerOnly = expense.isOwnerOnly;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expenseDate),
    );
    if (time == null) return;
    setState(() {
      _expenseDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (!_canManage) {
      AppHaptics.error();
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false) || amount <= 0) {
      AppHaptics.error();
      setState(() {});
      return;
    }
    if (_isEditing && !await _confirmEdit()) return;
    if (!mounted) return;
    AppHaptics.light();
    context.read<ExpenseBloc>().add(
          AddExpenseEvent(
            ClubExpense(
              id: widget.initialExpense?.id ?? '',
              companyId: widget.companyId,
              title: _titleController.text.trim(),
              amount: amount,
              category: _category,
              expenseDate: _expenseDate,
              addedBy: widget.initialExpense?.addedBy ?? widget.currentUser.name,
              addedById:
                  widget.initialExpense?.addedById ?? widget.currentUser.id,
              paymentMethod: _paymentMethod,
              notes: _notesController.text.trim(),
              isOwnerOnly: _isOwnerOnly,
              createdAt: widget.initialExpense?.createdAt ?? DateTime.now(),
            ),
            operator: widget.currentUser,
          ),
        );
    Navigator.of(context).pop();
  }

  Future<bool> _confirmEdit() async {
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
              const Text('Save expense changes?', style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('The updated expense details will replace the existing record.', style: TextStyle(color: AppColors.secondaryText)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent, foregroundColor: AppColors.primaryText), child: const Text('Save changes'))),
              ]),
            ],
          ),
        ),
      ),
    );
    return confirmed ?? false;
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.secondaryText),
        filled: true,
        fillColor: AppColors.inputSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorderStroke),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .9,
        maxWidth: 580,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_isEditing ? 'Edit Expense' : 'Add Expense', style: const TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                if (!_canManage) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tableMaintenance.withAlpha(24),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.tableMaintenance.withAlpha(110)),
                    ),
                    child: const Text(
                      'You are offline. Go online, or ask an owner/admin to record an expense.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.primaryText),
                  decoration: _inputDecoration('Expense title'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter an expense title.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  style: const TextStyle(color: AppColors.primaryText),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  decoration: _inputDecoration('Amount (₹)'),
                  validator: (value) => (double.tryParse(value ?? '') ?? 0) > 0 ? null : 'Enter an amount greater than zero.',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: AppColors.cardSurface,
                  style: const TextStyle(color: AppColors.primaryText),
                  decoration: _inputDecoration('Category'),
                  items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                  onChanged: (value) => setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 16),
                const Text('PAYMENT METHOD', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w700, fontSize: 11)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _paymentMethods.map((method) => ChoiceChip(
                    label: Text(method),
                    selected: _paymentMethod == method,
                    selectedColor: AppColors.brandAccent.withAlpha(70),
                    backgroundColor: AppColors.inputSurface,
                    labelStyle: const TextStyle(color: AppColors.primaryText),
                    side: const BorderSide(color: AppColors.cardBorderStroke),
                    onSelected: (_) { AppHaptics.selection(); setState(() => _paymentMethod = method); },
                  )).toList(),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('Date & time: ${MaterialLocalizations.of(context).formatMediumDate(_expenseDate)} • ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_expenseDate))}'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  style: const TextStyle(color: AppColors.primaryText),
                  decoration: _inputDecoration('Notes (optional)'),
                  maxLines: 3,
                ),
                if (widget.currentUser.isOwner) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isOwnerOnly,
                    activeColor: AppColors.brandAccent,
                    checkColor: AppColors.primaryText,
                    title: const Text(
                      'Visible to owner only',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Use for sensitive expenses such as salaries.',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    onChanged: (value) {
                      AppHaptics.selection();
                      setState(() => _isOwnerOnly = value ?? false);
                    },
                  ),
                ],
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _canManage ? _submit : null,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_isEditing ? 'Save changes' : 'Save expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandAccent,
                    foregroundColor: AppColors.primaryText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
