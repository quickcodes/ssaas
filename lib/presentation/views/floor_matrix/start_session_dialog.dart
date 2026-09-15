import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/club_branch.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';

class StartSessionDialog extends StatefulWidget {
  final ClubTable table;
  final ClubBranch branch;
  final UserAccount activeOperator;

  const StartSessionDialog({
    super.key,
    required this.table,
    required this.branch,
    required this.activeOperator,
  });

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  final _playerController = TextEditingController();
  final _phoneController = TextEditingController();
  BillingMode _selectedMode = BillingMode.hourly;
  final _uuid = const Uuid();

  @override
  void dispose() {
    _playerController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START TABLE SESSION',
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
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

            // Operator Tag Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: AppColors.brandAccentLight,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Operator Tag: ${widget.activeOperator.name}',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Player details
            TextField(
              controller: _playerController,
              decoration: const InputDecoration(
                labelText: 'Player / Group Name *',
                hintText: 'e.g. Karan & Friends',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number (Optional)',
                hintText: '+91 98765 43210',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing Mode Selection
            const Text(
              'Pricing Mode & Rate Engine',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModeChoice(
                  BillingMode.hourly,
                  'Standard Hourly (₹${widget.table.standardRatePerHour.toInt()}/h)',
                  'Auto-switches to Peak ₹${widget.table.peakRatePerHour.toInt()}/h after ${widget.branch.peakStartHour}:00 PM',
                ),
                _buildModeChoice(
                  BillingMode.fixedFrame,
                  'Fixed Frame (₹${widget.table.fixedFrameRate.toInt()})',
                  'Flat rate per frame played regardless of time',
                ),
                _buildModeChoice(
                  BillingMode.vip,
                  'VIP Tournament (₹${widget.table.vipRatePerHour.toInt()}/h)',
                  'Dedicated VIP table rate with match lights',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tableAvailable,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'START CLOCK',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChoice(BillingMode mode, String title, String subtitle) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandAccent.withAlpha(25)
              : AppColors.inputSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.brandAccent
                : AppColors.cardBorderStroke,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? AppColors.brandAccentLight
                  : AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession() {
    final playerName = _playerController.text.trim();
    if (playerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter player / group name')),
      );
      return;
    }

    final newSession = TableSession(
      id: _uuid.v4(),
      branchId: widget.branch.id,
      tableId: widget.table.id,
      tableName: widget.table.name,
      operatorId: widget.activeOperator.id,
      operatorName: widget.activeOperator.name,
      playerName: playerName,
      playerPhone: _phoneController.text.trim(),
      startTime: DateTime.now(),
      billingMode: _selectedMode,
      standardRatePerHour: widget.table.standardRatePerHour,
      peakRatePerHour: widget.table.peakRatePerHour,
      peakStartHour: widget.branch.peakStartHour,
      peakEndHour: widget.branch.peakEndHour,
      fixedFrameFee: widget.table.fixedFrameRate,
      rateSchedules: widget.table.rateSchedules,
    );

    Navigator.of(context).pop(newSession);
  }
}
