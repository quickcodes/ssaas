import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/payment_transaction.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../blocs/auth/auth_bloc.dart';

class SettleDuePaymentScreen extends StatefulWidget {
  final TableHistoryRecord record;

  const SettleDuePaymentScreen({super.key, required this.record});

  @override
  State<SettleDuePaymentScreen> createState() => _SettleDuePaymentScreenState();
}

class _SettleDuePaymentScreenState extends State<SettleDuePaymentScreen> {
  late final TextEditingController _amountCtrl;
  late String _selectedMethod;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.record.dueAmount.toStringAsFixed(0),
    );
    _selectedMethod = widget.record.paymentMethod != null &&
            widget.record.paymentMethod!.isNotEmpty
        ? widget.record.paymentMethod!
        : 'Cash';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 680;
    final enteredText = _amountCtrl.text.trim();
    final parsedAmount = double.tryParse(enteredText);

    String? validationError;
    if (enteredText.isEmpty) {
      validationError = 'Please enter an amount';
    } else if (parsedAmount == null) {
      validationError = 'Invalid amount entered';
    } else if (parsedAmount <= 0) {
      validationError = 'Amount must be greater than ₹0';
    } else if (parsedAmount > widget.record.dueAmount + 0.001) {
      validationError =
          'Cannot exceed remaining due of ₹${widget.record.dueAmount.toStringAsFixed(2)}';
    }

    final isValid =
        validationError == null && parsedAmount != null && parsedAmount > 0;
    final afterPaymentDue = isValid
        ? (widget.record.dueAmount - parsedAmount)
            .clamp(0.0, widget.record.dueAmount)
        : widget.record.dueAmount;
    final willBeSettled = isValid && afterPaymentDue <= 0.001;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'COLLECT PENDING PAYMENT',
              style: TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '${widget.record.tableName} • ${widget.record.customerName}',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorderStroke),
                ),
                padding: EdgeInsets.all(isMobile ? 18 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Card: Total, Paid, Due
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Bill',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${widget.record.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Already Paid',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${widget.record.paidAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.tableAvailable,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Current Due',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${widget.record.dueAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.tableOccupied,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Amount Received Field
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Amount to Pay Now (₹) *',
                        prefixText: '₹ ',
                        helperText: validationError == null
                            ? 'Max payable: ₹${widget.record.dueAmount.toStringAsFixed(2)}'
                            : null,
                        errorText: validationError,
                        suffixIcon: TextButton(
                          onPressed: () {
                            _amountCtrl.text =
                                widget.record.dueAmount.toStringAsFixed(0);
                            setState(() {});
                          },
                          child: const Text(
                            'PAY FULL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandAccentLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick action chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          label: Text(
                            'Full Due: ₹${widget.record.dueAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: AppColors.inputSurface,
                          side: const BorderSide(
                              color: AppColors.cardBorderStroke),
                          onPressed: () {
                            _amountCtrl.text =
                                widget.record.dueAmount.toStringAsFixed(0);
                            setState(() {});
                          },
                        ),
                        if (widget.record.dueAmount >= 20)
                          ActionChip(
                            label: Text(
                              'Half: ₹${(widget.record.dueAmount / 2).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.inputSurface,
                            side: const BorderSide(
                                color: AppColors.cardBorderStroke),
                            onPressed: () {
                              _amountCtrl.text = (widget.record.dueAmount / 2)
                                  .toStringAsFixed(0);
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Preview Calculation Banner
                    if (isValid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: willBeSettled
                              ? AppColors.tableAvailable.withAlpha(20)
                              : AppColors.tableOccupied.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: willBeSettled
                                ? AppColors.tableAvailable.withAlpha(80)
                                : AppColors.tableOccupied.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              willBeSettled
                                  ? Icons.check_circle_outline
                                  : Icons.pending_actions,
                              size: 16,
                              color: willBeSettled
                                  ? AppColors.tableAvailable
                                  : AppColors.tableOccupied,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                willBeSettled
                                    ? 'Paying ₹${parsedAmount.toStringAsFixed(2)} will fully settle this match.'
                                    : 'Remaining due will be ₹${afterPaymentDue.toStringAsFixed(2)} (Status will remain DUE).',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: willBeSettled
                                      ? AppColors.tableAvailable
                                      : AppColors.tableOccupied,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Payment Method Selector
                    const Text(
                      'PAYMENT METHOD',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Cash', 'UPI', 'Card'].map((method) {
                        final isSelected = _selectedMethod == method;
                        IconData iconData;
                        switch (method) {
                          case 'UPI':
                            iconData = Icons.qr_code_2;
                            break;
                          case 'Card':
                            iconData = Icons.credit_card;
                            break;
                          default:
                            iconData = Icons.payments_outlined;
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedMethod = method),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.brandAccent.withAlpha(40)
                                      : AppColors.inputSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.brandAccent
                                        : AppColors.cardBorderStroke,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      iconData,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.brandAccentLight
                                          : AppColors.secondaryText,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      method,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primaryText
                                            : AppColors.secondaryText,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            border: Border(top: BorderSide(color: AppColors.cardBorderStroke)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: (_isSubmitting || !isValid)
                      ? null
                      : () async {
                          final enteredAmount = parsedAmount;
                          if (enteredAmount <= 0 ||
                              enteredAmount > widget.record.dueAmount + 0.001) {
                            return;
                          }

                          setState(() => _isSubmitting = true);

                          final newPaid = (widget.record.paidAmount +
                                  enteredAmount)
                              .clamp(0.0, widget.record.totalAmount);
                          final remaining =
                              (widget.record.totalAmount - newPaid)
                                  .clamp(0.0, widget.record.totalAmount);
                          final isComplete = remaining <= 0.001;

                          final currentOperator = context
                                  .read<AuthBloc>()
                                  .state
                                  .currentUser
                                  ?.name ??
                              'Staff';
                          final newTx = PaymentTransaction(
                            id: const Uuid().v4(),
                            amount: enteredAmount,
                            paymentMethod: _selectedMethod,
                            receivedAt: DateTime.now(),
                            receivedBy: currentOperator,
                            notes: 'Match history payment collection',
                          );

                          final updatedTransactions = [
                            ...widget.record.transactions,
                            newTx,
                          ];

                          final updated = widget.record.copyWith(
                            transactions: updatedTransactions,
                            paidAmount: newPaid,
                            paymentStatus:
                                isComplete ? 'Received' : 'Due',
                            paymentMethod: _selectedMethod,
                          );

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            await sl<FirestoreService>()
                                .updateTableHistoryRecord(updated);
                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isComplete
                                        ? 'Full payment of ₹${enteredAmount.toStringAsFixed(0)} received via $_selectedMethod for ${widget.record.customerName}. Record settled!'
                                        : 'Payment of ₹${enteredAmount.toStringAsFixed(0)} received via $_selectedMethod. ₹${remaining.toStringAsFixed(0)} is still DUE for ${widget.record.customerName}.',
                                  ),
                                  backgroundColor: isComplete
                                      ? AppColors.tableAvailable
                                      : AppColors.tableOccupied,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update record: $e'),
                                  backgroundColor: AppColors.tableOccupied,
                                ),
                              );
                            }
                          }
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    willBeSettled
                        ? 'SETTLE FULL BILL'
                        : 'COLLECT ₹${(parsedAmount ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: willBeSettled
                        ? AppColors.tableAvailable
                        : AppColors.brandAccent,
                    foregroundColor:
                        willBeSettled ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
