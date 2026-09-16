import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';

class StartSessionDialog extends StatefulWidget {
  final ClubTable table;
  final UserAccount activeOperator;

  const StartSessionDialog({
    super.key,
    required this.table,
    required this.activeOperator,
  });

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentRate = widget.table.effectiveRateAt(now);

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(26),
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
                        'START SNOOKER SESSION',
                        style: TextStyle(
                          color: AppColors.tableAvailable,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.table.name,
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
              const SizedBox(height: 16),

              // Operator & Live Rate Info Badge
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
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: AppColors.brandAccentLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Operator: ${widget.activeOperator.name}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Current: ₹${currentRate.toStringAsFixed(0)}/hr',
                        style: const TextStyle(
                          color: AppColors.brandAccentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Customer Name Input
              TextFormField(
                controller: _customerController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'Enter customer or player name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Customer name is required to start table'
                    : null,
              ),
              const SizedBox(height: 14),

              // Optional Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Table reservation or special request',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 20),

              // Pricing Summary Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'General rate is ₹${widget.table.generalPrice.toStringAsFixed(0)}/hr with ${widget.table.customPricings.length} custom peak/weekday schedules configured.',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        final session = TableSession(
                          id: const Uuid().v4(),
                          companyId: widget.table.companyId,
                          tableId: widget.table.id,
                          tableName: widget.table.name,
                          customerName: _customerController.text.trim(),
                          startedById: widget.activeOperator.id,
                          startedByName: widget.activeOperator.name,
                          startTime: DateTime.now(),
                          generalPrice: widget.table.generalPrice,
                          customPricings: widget.table.customPricings,
                          notes: _notesController.text.trim(),
                        );

                        Navigator.of(context).pop(session);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'START TABLE CLOCK',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tableAvailable,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
}
