import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
  final _closingNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _paymentStatus = 'Received'; // 'Received' or 'Due'
  String _paymentMethod = 'Cash'; // 'Cash', 'UPI', 'Card'

  @override
  void initState() {
    super.initState();
    _closingNameCtrl.text = widget.activeOperator.name;
  }

  @override
  void dispose() {
    _closingNameCtrl.dispose();
    _notesCtrl.dispose();
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

                // Closing Name Field (Prompted at closing as required)
                TextFormField(
                  controller: _closingNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Closing Name (Staff closing this table) *',
                    hintText: 'Enter staff/marker name closing this match',
                    prefixIcon: Icon(Icons.person_pin_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Closing name is required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Payment Status: Amount Received vs Due
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
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _paymentStatus = 'Received'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _paymentStatus == 'Received'
                                ? AppColors.tableAvailable.withAlpha(35)
                                : AppColors.inputSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _paymentStatus == 'Received'
                                  ? AppColors.tableAvailable
                                  : AppColors.cardBorderStroke,
                              width: _paymentStatus == 'Received' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: _paymentStatus == 'Received'
                                    ? AppColors.tableAvailable
                                    : AppColors.secondaryText,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Amount Received',
                                style: TextStyle(
                                  color: _paymentStatus == 'Received'
                                      ? AppColors.primaryText
                                      : AppColors.secondaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _paymentStatus = 'Due'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _paymentStatus == 'Due'
                                ? AppColors.tableOccupied.withAlpha(35)
                                : AppColors.inputSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _paymentStatus == 'Due'
                                  ? AppColors.tableOccupied
                                  : AppColors.cardBorderStroke,
                              width: _paymentStatus == 'Due' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.pending_actions,
                                color: _paymentStatus == 'Due'
                                    ? AppColors.tableOccupied
                                    : AppColors.secondaryText,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Amount Due',
                                style: TextStyle(
                                  color: _paymentStatus == 'Due'
                                      ? AppColors.primaryText
                                      : AppColors.secondaryText,
                                  fontWeight: FontWeight.w700,
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

                // Payment Method (Only if Received)
                if (_paymentStatus == 'Received') ...[
                  const SizedBox(height: 14),
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

                          final historyRecord = TableHistoryRecord(
                            id: const Uuid().v4(),
                            companyId: widget.session.companyId,
                            tableId: widget.session.tableId,
                            tableName: widget.session.tableName,
                            customerName: widget.session.customerName,
                            startedByName: widget.session.startedByName,
                            closedByName: _closingNameCtrl.text.trim(),
                            startedAt: widget.session.startTime,
                            closedAt: widget.now,
                            durationMinutes: durationMinutes,
                            tableAmount: tableCharge,
                            itemsAmount: itemsCharge,
                            totalAmount: grandTotal,
                            paymentStatus: _paymentStatus,
                            paymentMethod: _paymentStatus == 'Received'
                                ? _paymentMethod
                                : null,
                            items: widget.session.items,
                            createdAt: DateTime.now(),
                          );

                          Navigator.of(context).pop(historyRecord);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _paymentStatus == 'Received'
                              ? AppColors.tableAvailable
                              : AppColors.tableOccupied,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _paymentStatus == 'Received'
                              ? 'CONFIRM RECEIVED ₹${grandTotal.toStringAsFixed(0)}'
                              : 'CONFIRM DUE ₹${grandTotal.toStringAsFixed(0)}',
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
