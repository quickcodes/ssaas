import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/payment_transaction.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';

class CheckoutSessionDialog extends StatefulWidget {
  final TableSession session;
  final DateTime now;
  final UserAccount activeOperator;

  const CheckoutSessionDialog({
    super.key,
    required this.session,
    required this.now,
    required this.activeOperator,
  });

  @override
  State<CheckoutSessionDialog> createState() => _CheckoutSessionDialogState();
}

class _CheckoutSessionDialogState extends State<CheckoutSessionDialog> {
  final _closingPersonCtrl = TextEditingController();
  final _closingNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _partialAmountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _settlementMode = 'Full'; // 'Full', 'Partial', 'Due'
  String _paymentMethod = 'Cash'; // 'Cash', 'UPI', 'Card'

  @override
  void initState() {
    super.initState();
    _closingPersonCtrl.text = widget.session.customerName;
    _closingNameCtrl.text = widget.activeOperator.name;
  }

  @override
  void dispose() {
    _closingPersonCtrl.dispose();
    _closingNameCtrl.dispose();
    _notesCtrl.dispose();
    _partialAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playedSeconds = widget.session.playedSecondsAt(widget.now);
    final durationMinutes = (playedSeconds / 60).ceil();
    final tableCharge = widget.session.computeTableChargeAt(widget.now);
    final itemsCharge = widget.session.itemsAmount;
    final grandTotal = tableCharge + itemsCharge;

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(26),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CLOSE TABLE & SETTLE BILL',
                          style: TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.session.tableName,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.cardBorderStroke),
                const SizedBox(height: 14),

                // Match details summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.session.customerName,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Duration Played',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatDuration(playedSeconds),
                            style: const TextStyle(
                              color: AppColors.tableAvailable,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Price Breakdown Itemization
                const Text(
                  'PRICE BREAKDOWN',
                  style: TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // Table time charge
                _buildBreakdownRow(
                  title: 'Table Rental Fee',
                  subtitle:
                      'Dynamic rate • $durationMinutes mins (${(playedSeconds / 3600.0).toStringAsFixed(1)} hrs)',
                  amount: '₹${tableCharge.toStringAsFixed(2)}',
                  isHighlight: false,
                ),

                // Snacks / Canteen & Custom items
                if (widget.session.items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      children: widget.session.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.quantity}x ${item.name}${item.isCustom ? " (Custom)" : ""}',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '₹${item.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                // Total Amount Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.brandAccent.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bill Amount',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '₹${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.brandAccentLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Closing Person Name Field (On which person the table got closed)
                TextFormField(
                  controller: _closingPersonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Closing Person Name *',
                    hintText: 'Enter player/customer name on whom the table is closing',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Closing person name is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Closing Staff Name Field (Staff closing this table)
                TextFormField(
                  controller: _closingNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Closed By (Staff / Marker) *',
                    hintText: 'Enter staff/marker name closing this match',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Staff name is required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Payment Status: Full Received vs Partial vs Full Due
                const Text(
                  'PAYMENT SETTLEMENT',
                  style: TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    _buildSettlementOption(
                      mode: 'Full',
                      icon: Icons.check_circle_outline,
                      title: 'Full Paid',
                      subtitle: '₹${grandTotal.toStringAsFixed(0)}',
                      activeColor: AppColors.tableAvailable,
                    ),
                    const SizedBox(width: 8),
                    _buildSettlementOption(
                      mode: 'Partial',
                      icon: Icons.timelapse,
                      title: 'Partial Paid',
                      subtitle: 'Part payment',
                      activeColor: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildSettlementOption(
                      mode: 'Due',
                      icon: Icons.pending_actions,
                      title: 'Full Due',
                      subtitle: '₹0 now',
                      activeColor: AppColors.tableOccupied,
                    ),
                  ],
                ),

                // If Partial, show amount input with validation & real-time calculation
                if (_settlementMode == 'Partial') ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _partialAmountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Amount Received Now (₹) *',
                      prefixText: '₹ ',
                      helperText:
                          'Max payable now: ₹${(grandTotal - 0.01).clamp(0.0, grandTotal).toStringAsFixed(2)}',
                      errorText: () {
                        final text = _partialAmountCtrl.text.trim();
                        if (text.isEmpty) return 'Please enter partial amount';
                        final val = double.tryParse(text);
                        if (val == null || val <= 0) {
                          return 'Amount must be greater than ₹0';
                        }
                        if (val >= grandTotal) {
                          return 'Amount cannot equal or exceed total (select Full Paid)';
                        }
                        return null;
                      }(),
                    ),
                  ),
                  if (double.tryParse(_partialAmountCtrl.text.trim()) != null &&
                      (double.tryParse(_partialAmountCtrl.text.trim())! > 0) &&
                      (double.tryParse(_partialAmountCtrl.text.trim())! <
                          grandTotal)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Received: ₹${double.parse(_partialAmountCtrl.text.trim()).toStringAsFixed(2)} • Remaining DUE: ₹${(grandTotal - double.parse(_partialAmountCtrl.text.trim())).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Payment Method (if money received now)
                if (_settlementMode != 'Due') ...[
                  const SizedBox(height: 14),
                  const Text(
                    'PAYMENT METHOD FOR RECEIVED AMOUNT',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMethodChip('Cash', Icons.money),
                      const SizedBox(width: 8),
                      _buildMethodChip('UPI', Icons.qr_code),
                      const SizedBox(width: 8),
                      _buildMethodChip('Card', Icons.credit_card),
                    ],
                  ),
                ],

                const SizedBox(height: 26),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;

                          double paidAmount = 0.0;
                          final transactions = <PaymentTransaction>[];
                          String status = 'Due';
                          String? method;

                          if (_settlementMode == 'Full') {
                            paidAmount = grandTotal;
                            status = 'Received';
                            method = _paymentMethod;
                            transactions.add(
                              PaymentTransaction(
                                id: const Uuid().v4(),
                                amount: grandTotal,
                                paymentMethod: _paymentMethod,
                                receivedAt: widget.now,
                                receivedBy: _closingNameCtrl.text.trim(),
                                notes: 'Initial full settlement at checkout',
                              ),
                            );
                          } else if (_settlementMode == 'Partial') {
                            final entered = double.tryParse(
                              _partialAmountCtrl.text.trim(),
                            );
                            if (entered == null || entered <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a partial amount greater than ₹0.',
                                  ),
                                  backgroundColor: AppColors.tableOccupied,
                                ),
                              );
                              return;
                            }
                            if (entered >= grandTotal) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Partial amount cannot equal or exceed total bill. Select Full Paid.',
                                  ),
                                  backgroundColor: AppColors.tableOccupied,
                                ),
                              );
                              return;
                            }
                            paidAmount = entered;
                            status = 'Due';
                            method = _paymentMethod;
                            transactions.add(
                              PaymentTransaction(
                                id: const Uuid().v4(),
                                amount: entered,
                                paymentMethod: _paymentMethod,
                                receivedAt: widget.now,
                                receivedBy: _closingNameCtrl.text.trim(),
                                notes: 'Initial partial payment at checkout',
                              ),
                            );
                          } else {
                            // Full Due
                            paidAmount = 0.0;
                            status = 'Due';
                            method = null;
                          }

                          final historyRecord = TableHistoryRecord(
                            id: const Uuid().v4(),
                            companyId: widget.session.companyId,
                            tableId: widget.session.tableId,
                            tableName: widget.session.tableName,
                            customerName: _closingPersonCtrl.text.trim(),
                            startedByName: widget.session.startedByName,
                            closedByName: _closingNameCtrl.text.trim(),
                            startedAt: widget.session.startTime,
                            closedAt: widget.now,
                            durationMinutes: durationMinutes,
                            tableAmount: tableCharge,
                            itemsAmount: itemsCharge,
                            totalAmount: grandTotal,
                            paidAmount: paidAmount,
                            paymentStatus: status,
                            paymentMethod: method,
                            items: widget.session.items,
                            transactions: transactions,
                            createdAt: DateTime.now(),
                          );

                          Navigator.of(context).pop(historyRecord);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _settlementMode == 'Full'
                              ? AppColors.tableAvailable
                              : (_settlementMode == 'Partial'
                                  ? Colors.orange
                                  : AppColors.tableOccupied),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _settlementMode == 'Full'
                              ? 'CONFIRM RECEIVED ₹${grandTotal.toStringAsFixed(0)}'
                              : (_settlementMode == 'Partial'
                                  ? () {
                                      final p = double.tryParse(
                                            _partialAmountCtrl.text.trim(),
                                          ) ??
                                          0.0;
                                      final due = (grandTotal - p)
                                          .clamp(0.0, grandTotal);
                                      return 'CONFIRM (₹${due.toStringAsFixed(0)} DUE)';
                                    }()
                                  : 'CONFIRM DUE ₹${grandTotal.toStringAsFixed(0)}'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementOption({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color activeColor,
  }) {
    final isSelected = _settlementMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _settlementMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withAlpha(35)
                : AppColors.inputSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.cardBorderStroke,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : AppColors.secondaryText,
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? activeColor : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String subtitle,
    required String amount,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = method),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandAccent.withAlpha(40)
                : AppColors.inputSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandAccent
                  : AppColors.cardBorderStroke,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.brandAccentLight
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                method,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
