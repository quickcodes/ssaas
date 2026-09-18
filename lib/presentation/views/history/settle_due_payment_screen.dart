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
  double get _dueBuffer {
    final activeCompany = context.read<AuthBloc>().state.activeCompany;
    return activeCompany?.dueBufferAmount ?? widget.record.dueBufferAmount;
  }

  // Mode: 'Single' or 'Split'
  String _paymentMode = 'Single';

  // Single Pay Controllers
  late final TextEditingController _amountCtrl;
  late String _selectedMethod;

  // Split Pay Controllers
  late final TextEditingController _splitCashCtrl;
  late final TextEditingController _splitOnlineCtrl;
  String _splitOnlineMethod = 'UPI';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.record.dueAmount.toStringAsFixed(0),
    );
    _splitCashCtrl = TextEditingController();
    _splitOnlineCtrl = TextEditingController();

    _selectedMethod = widget.record.paymentMethod != null &&
            widget.record.paymentMethod!.isNotEmpty &&
            !widget.record.paymentMethod!.startsWith('Split')
        ? widget.record.paymentMethod!
        : 'Cash';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _splitCashCtrl.dispose();
    _splitOnlineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 680;
    final due = widget.record.dueAmount;

    // Calculations for Single Pay
    final singleEnteredText = _amountCtrl.text.trim();
    final singleParsedAmount = double.tryParse(singleEnteredText);
    String? singleValidationError;
    if (singleEnteredText.isEmpty) {
      singleValidationError = 'Please enter an amount';
    } else if (singleParsedAmount == null) {
      singleValidationError = 'Invalid amount entered';
    } else if (singleParsedAmount <= 0) {
      singleValidationError = 'Amount must be greater than ₹0';
    } else if (singleParsedAmount > due + 0.001) {
      singleValidationError =
          'Cannot exceed remaining due of ₹${due.toStringAsFixed(2)}';
    }

    final isSingleValid = singleValidationError == null &&
        singleParsedAmount != null &&
        singleParsedAmount > 0;
    final singleAfterPaymentDue = isSingleValid
        ? (due - singleParsedAmount).clamp(0.0, due)
        : due;
    final isSingleSettled = isSingleValid && singleAfterPaymentDue < _dueBuffer;

    // Calculations for Split Pay
    final splitCash = double.tryParse(_splitCashCtrl.text.trim()) ?? 0.0;
    final splitOnline = double.tryParse(_splitOnlineCtrl.text.trim()) ?? 0.0;
    final splitTotal = splitCash + splitOnline;
    final splitRemainingDue = (due - splitTotal).clamp(0.0, due);
    final isSplitOverpaid = splitTotal > due + 0.01;
    final isSplitValid = splitTotal > 0 && !isSplitOverpaid;
    final isSplitSettled = isSplitValid && splitRemainingDue < _dueBuffer;

    final isCurrentValid =
        _paymentMode == 'Single' ? isSingleValid : isSplitValid;
    final willBeSettled =
        _paymentMode == 'Single' ? isSingleSettled : isSplitSettled;
    final currentTotalPaying =
        _paymentMode == 'Single' ? (singleParsedAmount ?? 0.0) : splitTotal;

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
            constraints: const BoxConstraints(maxWidth: 560),
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
                                '₹${due.toStringAsFixed(0)}',
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

                    // Payment Mode Toggle: Single Pay vs Split Pay
                    const Text(
                      'COLLECTION METHOD',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _paymentMode = 'Single'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _paymentMode == 'Single'
                                    ? AppColors.brandAccent.withAlpha(40)
                                    : AppColors.inputSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _paymentMode == 'Single'
                                      ? AppColors.brandAccent
                                      : AppColors.cardBorderStroke,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                    color: _paymentMode == 'Single'
                                        ? AppColors.brandAccentLight
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Single Pay',
                                    style: TextStyle(
                                      color: _paymentMode == 'Single'
                                          ? AppColors.primaryText
                                          : AppColors.secondaryText,
                                      fontWeight: _paymentMode == 'Single'
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _paymentMode = 'Split';
                                if (_splitCashCtrl.text.isEmpty &&
                                    _splitOnlineCtrl.text.isEmpty) {
                                  // Pre-fill cash with half or full
                                  _splitCashCtrl.text =
                                      (due / 2).round().toString();
                                  _splitOnlineCtrl.text =
                                      (due - (due / 2).round()).toString();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _paymentMode == 'Split'
                                    ? AppColors.brandAccentLight.withAlpha(40)
                                    : AppColors.inputSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _paymentMode == 'Split'
                                      ? AppColors.brandAccentLight
                                      : AppColors.cardBorderStroke,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call_split,
                                    size: 16,
                                    color: _paymentMode == 'Split'
                                        ? AppColors.brandAccentLight
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Split Pay',
                                    style: TextStyle(
                                      color: _paymentMode == 'Split'
                                          ? AppColors.primaryText
                                          : AppColors.secondaryText,
                                      fontWeight: _paymentMode == 'Split'
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Mode 1: Single Pay Content
                    if (_paymentMode == 'Single') ...[
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Amount to Pay Now (₹) *',
                          prefixText: '₹ ',
                          helperText: singleValidationError == null
                              ? 'Max payable: ₹${due.toStringAsFixed(2)}'
                              : null,
                          errorText: singleValidationError,
                          suffixIcon: TextButton(
                            onPressed: () {
                              _amountCtrl.text = due.toStringAsFixed(0);
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
                              'Full Due: ₹${due.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.inputSurface,
                            side: const BorderSide(
                              color: AppColors.cardBorderStroke,
                            ),
                            onPressed: () {
                              _amountCtrl.text = due.toStringAsFixed(0);
                              setState(() {});
                            },
                          ),
                          if (due >= 20)
                            ActionChip(
                              label: Text(
                                'Half: ₹${(due / 2).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.inputSurface,
                              side: const BorderSide(
                                color: AppColors.cardBorderStroke,
                              ),
                              onPressed: () {
                                _amountCtrl.text =
                                    (due / 2).toStringAsFixed(0);
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Preview Calculation Banner
                      if (isSingleValid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSingleSettled
                                ? AppColors.tableAvailable.withAlpha(20)
                                : AppColors.tableOccupied.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSingleSettled
                                  ? AppColors.tableAvailable.withAlpha(80)
                                  : AppColors.tableOccupied.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSingleSettled
                                    ? Icons.check_circle_outline
                                    : Icons.pending_actions,
                                size: 16,
                                color: isSingleSettled
                                    ? AppColors.tableAvailable
                                    : AppColors.tableOccupied,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isSingleSettled
                                      ? (singleAfterPaymentDue > 0
                                          ? 'Paying ₹${singleParsedAmount.toStringAsFixed(2)} leaves ₹${singleAfterPaymentDue.toStringAsFixed(2)} (< ₹${_dueBuffer.toStringAsFixed(0)}). Record will be fully SETTLED as Received!'
                                          : 'Paying ₹${singleParsedAmount.toStringAsFixed(2)} will fully settle this match.')
                                      : 'Remaining due will be ₹${singleAfterPaymentDue.toStringAsFixed(2)} (Status will remain DUE).',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSingleSettled
                                        ? AppColors.tableAvailable
                                        : AppColors.tableOccupied,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),

                      // Single Payment Method Selector
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedMethod = method),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
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

                    // Mode 2: Split Pay Content (Cash + Online/UPI)
                    if (_paymentMode == 'Split') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.inputSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.brandAccent.withAlpha(80),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.call_split,
                                  size: 16,
                                  color: AppColors.brandAccentLight,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'SPLIT DUE PAYMENT (CASH + ONLINE)',
                                  style: TextStyle(
                                    color: AppColors.brandAccentLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Cash input
                            TextField(
                              controller: _splitCashCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Cash Amount (₹) *',
                                prefixText: '₹ ',
                                suffixIcon: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _splitCashCtrl.text =
                                          due.toStringAsFixed(0);
                                      _splitOnlineCtrl.text = '0';
                                    });
                                  },
                                  child: const Text(
                                    'All Cash',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.brandAccentLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Online input
                            TextField(
                              controller: _splitOnlineCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Online / UPI Amount (₹) *',
                                prefixText: '₹ ',
                                suffixIcon: TextButton(
                                  onPressed: () {
                                    final cash =
                                        double.tryParse(
                                          _splitCashCtrl.text.trim(),
                                        ) ??
                                        0.0;
                                    final rem =
                                        (due - cash).clamp(0.0, due);
                                    setState(() {
                                      _splitOnlineCtrl.text =
                                          rem.toStringAsFixed(0);
                                    });
                                  },
                                  child: const Text(
                                    'Fill Rest',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.brandAccentLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Online method selector (UPI vs Card)
                            const Text(
                              'ONLINE PAYMENT VIA:',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _splitOnlineMethod = 'UPI',
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _splitOnlineMethod == 'UPI'
                                            ? AppColors.brandAccent
                                                .withAlpha(50)
                                            : AppColors.cardSurface,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _splitOnlineMethod == 'UPI'
                                              ? AppColors.brandAccentLight
                                              : AppColors.cardBorderStroke,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2,
                                            size: 15,
                                            color: AppColors.brandAccentLight,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'UPI / QR',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _splitOnlineMethod = 'Card',
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _splitOnlineMethod == 'Card'
                                            ? AppColors.brandAccent
                                                .withAlpha(50)
                                            : AppColors.cardSurface,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _splitOnlineMethod == 'Card'
                                              ? AppColors.brandAccentLight
                                              : AppColors.cardBorderStroke,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.credit_card,
                                            size: 15,
                                            color: AppColors.brandAccentLight,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Card / POS',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Live Split Summary Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSplitOverpaid
                              ? AppColors.error.withAlpha(20)
                              : (isSplitSettled
                                  ? AppColors.tableAvailable.withAlpha(20)
                                  : AppColors.inputSurface),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSplitOverpaid
                                ? AppColors.error.withAlpha(90)
                                : (isSplitSettled
                                    ? AppColors.tableAvailable.withAlpha(90)
                                    : AppColors.cardBorderStroke),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Paid via Cash:',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${splitCash.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid via $_splitOnlineMethod:',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${splitOnline.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              color: AppColors.cardBorderStroke,
                              height: 16,
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isSplitOverpaid
                                      ? 'OVERPAID BY:'
                                      : (isSplitSettled
                                          ? 'TOTAL COLLECTED (SETTLED):'
                                          : 'TOTAL COLLECTED:'),
                                  style: TextStyle(
                                    color: isSplitOverpaid
                                        ? AppColors.error
                                        : (isSplitSettled
                                            ? AppColors.tableAvailable
                                            : AppColors.primaryText),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${splitTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isSplitOverpaid
                                        ? AppColors.error
                                        : (isSplitSettled
                                            ? AppColors.tableAvailable
                                            : AppColors.primaryText),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (!isSplitSettled && !isSplitOverpaid) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Remaining DUE:',
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '₹${splitRemainingDue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (isSplitSettled &&
                                splitRemainingDue > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Due Waived (< ₹${_dueBuffer.toStringAsFixed(0)}):',
                                    style: const TextStyle(
                                      color: AppColors.tableAvailable,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '₹${splitRemainingDue.toStringAsFixed(2)} waived (Received)',
                                    style: const TextStyle(
                                      color: AppColors.tableAvailable,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
            border:
                Border(top: BorderSide(color: AppColors.cardBorderStroke)),
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
                  onPressed: (_isSubmitting || !isCurrentValid)
                      ? null
                      : () async {
                          final payingNow = currentTotalPaying;
                          if (payingNow <= 0 ||
                              payingNow > due + 0.01) {
                            return;
                          }

                          setState(() => _isSubmitting = true);

                          final currentOperator = context
                                  .read<AuthBloc>()
                                  .state
                                  .currentUser
                                  ?.name ??
                              'Staff';

                          final newTxs = <PaymentTransaction>[];

                          if (_paymentMode == 'Single') {
                            newTxs.add(
                              PaymentTransaction(
                                id: const Uuid().v4(),
                                amount: payingNow,
                                paymentMethod: _selectedMethod,
                                receivedAt: DateTime.now(),
                                receivedBy: currentOperator,
                                notes:
                                    'Match history pending payment collection',
                              ),
                            );
                          } else {
                            // Split mode
                            if (splitCash > 0) {
                              newTxs.add(
                                PaymentTransaction(
                                  id: const Uuid().v4(),
                                  amount: splitCash,
                                  paymentMethod: 'Cash',
                                  receivedAt: DateTime.now(),
                                  receivedBy: currentOperator,
                                  notes:
                                      'Due settlement - Cash portion',
                                ),
                              );
                            }
                            if (splitOnline > 0) {
                              newTxs.add(
                                PaymentTransaction(
                                  id: const Uuid().v4(),
                                  amount: splitOnline,
                                  paymentMethod: _splitOnlineMethod,
                                  receivedAt: DateTime.now(),
                                  receivedBy: currentOperator,
                                  notes:
                                      'Due settlement - $_splitOnlineMethod portion',
                                ),
                              );
                            }
                          }

                          final newPaid = (widget.record.paidAmount +
                                  payingNow)
                              .clamp(0.0, widget.record.totalAmount);
                          final remaining =
                              (widget.record.totalAmount - newPaid)
                                  .clamp(0.0, widget.record.totalAmount);

                          // If remaining due < buffer amount, consider it as Received
                          final isComplete = remaining < _dueBuffer;

                          final updatedTransactions = [
                            ...widget.record.transactions,
                            ...newTxs,
                          ];

                          final updatedMethod = _paymentMode == 'Split'
                              ? 'Split (Cash + $_splitOnlineMethod)'
                              : _selectedMethod;

                          final updated = widget.record.copyWith(
                            transactions: updatedTransactions,
                            paidAmount: newPaid,
                            paymentStatus:
                                isComplete ? 'Received' : 'Due',
                            paymentMethod: updatedMethod,
                            dueBufferAmount: _dueBuffer,
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
                                        ? (remaining > 0
                                            ? 'Payment of ₹${payingNow.toStringAsFixed(0)} received for ${widget.record.customerName}. Remaining ₹${remaining.toStringAsFixed(2)} waived (< ₹${_dueBuffer.toStringAsFixed(0)}) — record fully SETTLED!'
                                            : 'Full payment of ₹${payingNow.toStringAsFixed(0)} received for ${widget.record.customerName}. Record settled!')
                                        : 'Payment of ₹${payingNow.toStringAsFixed(0)} received. ₹${remaining.toStringAsFixed(0)} is still DUE for ${widget.record.customerName}.',
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
                                  content:
                                      Text('Failed to update record: $e'),
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
                        ? 'SETTLE FULL RECORD'
                        : 'COLLECT ₹${currentTotalPaying.toStringAsFixed(0)}',
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
