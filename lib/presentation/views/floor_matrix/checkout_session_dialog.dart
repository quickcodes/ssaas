import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/tab_order_item.dart';
import '../../../domain/entities/table_session.dart';

class CheckoutSessionDialog extends StatefulWidget {
  final TableSession session;
  final List<TabOrderItem> tabItems;
  final DateTime now;
  final bool canOverrideDiscount;

  const CheckoutSessionDialog({
    super.key,
    required this.session,
    required this.tabItems,
    required this.now,
    required this.canOverrideDiscount,
  });

  @override
  State<CheckoutSessionDialog> createState() => _CheckoutSessionDialogState();
}

class _CheckoutSessionDialogState extends State<CheckoutSessionDialog> {
  final _discountController = TextEditingController(text: '0');
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _discount = widget.session.discountAmount;
    if (_discount > 0) {
      _discountController.text = _discount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playedSeconds = widget.session.playedSecondsAt(widget.now);
    final tableCharge = widget.session.computeTableChargeAt(widget.now);
    // The session ledger is authoritative. The item list is used only for
    // receipt detail and can be unavailable while the POS stream refreshes.
    final itemizedFnbCharge = widget.tabItems.fold(
      0.0,
      (acc, item) => acc + item.totalAmount,
    );
    final fnbCharge = widget.tabItems.isEmpty
        ? widget.session.fnbAmount
        : itemizedFnbCharge;
    final grossTotal = tableCharge + fnbCharge;
    final grandTotal = (grossTotal - _discount).clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
                        'CHECKOUT & SINGLE-RECEIPT SETTLEMENT',
                        style: TextStyle(
                          color: AppColors.brandAccentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.session.tableName,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.cardBorderStroke),
              const SizedBox(height: 16),

              // Player & Duration Row
              Container(
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
                        const Text(
                          'Player / Customer',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.session.playerName,
                          style: const TextStyle(
                            color: AppColors.primaryText,
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
                          'Total Playing Time',
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
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Itemized Bill Breakdown
              const Text(
                'Receipt Itemization',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // Table line
              _buildBillLine(
                title:
                    'Table Rental (${widget.session.billingMode.displayName})',
                subtitle:
                    '${(playedSeconds / 60).toStringAsFixed(0)} mins played',
                amount: AppFormatters.currency(tableCharge),
                isHighlight: false,
              ),

              // Canteen Tab Items
              if (widget.tabItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface.withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: Column(
                    children: widget.tabItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x ${item.itemName}',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(item.totalAmount),
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 12,
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

              const SizedBox(height: 12),

              // Discount Override
              if (widget.canOverrideDiscount)
                Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Discount Override (₹)',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            prefixText: '₹ ',
                          ),
                          onChanged: (val) {
                            setState(() {
                              _discount = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.cardBorderStroke),
              const SizedBox(height: 10),

              // Grand Total Row
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tableAvailable.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.tableAvailable.withAlpha(100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAYABLE',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      AppFormatters.currency(grandTotal),
                      style: const TextStyle(
                        color: AppColors.tableAvailable,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Choice
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPaymentChip(PaymentMethod.cash, Icons.money, 'Cash'),
                  const SizedBox(width: 8),
                  _buildPaymentChip(
                    PaymentMethod.upi,
                    Icons.qr_code_2,
                    'UPI / QR',
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentChip(
                    PaymentMethod.card,
                    Icons.credit_card,
                    'Card',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'paymentMethod': _selectedPayment,
                          'finalTableAmount': tableCharge,
                          'finalTotalAmount': grandTotal,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'COLLECT ${AppFormatters.currency(grandTotal)}',
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
    );
  }

  Widget _buildBillLine({
    required String title,
    required String subtitle,
    required String amount,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(8),
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
                  fontSize: 12,
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(PaymentMethod method, IconData icon, String label) {
    final isSelected = _selectedPayment == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPayment = method),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandAccent.withAlpha(40)
                : AppColors.inputSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandAccent
                  : AppColors.cardBorderStroke,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.brandAccentLight
                    : AppColors.secondaryText,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
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
