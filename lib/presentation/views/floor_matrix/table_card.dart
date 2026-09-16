import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';

class TableCard extends StatelessWidget {
  final ClubTable table;
  final TableSession? session;
  final DateTime now;
  final UserAccount activeOperator;
  final VoidCallback onStartSession;
  final VoidCallback onPauseSession;
  final VoidCallback onResumeSession;
  final VoidCallback onCheckoutSession;
  final VoidCallback onAddItem;
  final Function(TableStatus) onUpdateStatus;
  final VoidCallback onConfigureRates;

  const TableCard({
    super.key,
    required this.table,
    this.session,
    required this.now,
    required this.activeOperator,
    required this.onStartSession,
    required this.onPauseSession,
    required this.onResumeSession,
    required this.onCheckoutSession,
    required this.onAddItem,
    required this.onUpdateStatus,
    required this.onConfigureRates,
  });

  Color get _statusColor {
    switch (table.status) {
      case TableStatus.available:
        return AppColors.tableAvailable;
      case TableStatus.occupied:
        return AppColors.tableOccupied;
      case TableStatus.maintenance:
        return AppColors.tableMaintenance;
      case TableStatus.reserved:
        return AppColors.tableReserved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = session != null;
    final playedSeconds = hasActiveSession ? session!.playedSecondsAt(now) : 0;
    final liveTableFee =
        hasActiveSession ? session!.computeTableChargeAt(now) : 0.0;
    final liveItemsFee = hasActiveSession ? session!.itemsAmount : 0.0;
    final liveGrandTotal = liveTableFee + liveItemsFee;
    final currentHourlyRate =
        hasActiveSession ? session!.effectiveRateAt(now) : table.effectiveRateAt(now);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveSession
              ? _statusColor.withAlpha(180)
              : AppColors.cardBorderStroke,
          width: hasActiveSession ? 1.8 : 1.0,
        ),
        boxShadow: hasActiveSession
            ? [
                BoxShadow(
                  color: _statusColor.withAlpha(30),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header: Table Name & Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputSurface.withAlpha(160),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: const Border(
                bottom: BorderSide(color: AppColors.cardBorderStroke),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _statusColor.withAlpha(180),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      table.name,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                // Status Popup Menu
                PopupMenuButton<TableStatus>(
                  initialValue: table.status,
                  tooltip: 'Change Table Status',
                  onSelected: onUpdateStatus,
                  color: AppColors.cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorderStroke),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          table.status.displayName,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: _statusColor, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => TableStatus.values.map((s) {
                    return PopupMenuItem<TableStatus>(
                      value: s,
                      child: Text(
                        s.displayName,
                        style: const TextStyle(color: AppColors.primaryText),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Body: Active Session vs Idle State
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasActiveSession) ...[
                  // Customer Name Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.brandAccentLight,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Customer: ${session!.customerName}',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Timer Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Playing Time',
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
                              fontSize: 20,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Live Total Bill',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${liveGrandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.brandAccentLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rate & Item Breakdown Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rate: ₹${currentHourlyRate.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Table: ₹${liveTableFee.toStringAsFixed(0)}  •  Items: ₹${liveItemsFee.toStringAsFixed(0)} (${session!.items.length})',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Actions: Add Item, Pause/Resume, Close
                  Row(
                    children: [
                      // Add Snack / Drink / Custom item button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onAddItem,
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text(
                            'Add Items',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(
                              color: AppColors.brandAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Pause / Resume toggle
                      IconButton(
                        onPressed: session!.isPaused
                            ? onResumeSession
                            : onPauseSession,
                        tooltip: session!.isPaused ? 'Resume Clock' : 'Pause Clock',
                        icon: Icon(
                          session!.isPaused
                              ? Icons.play_arrow
                              : Icons.pause,
                          color: session!.isPaused
                              ? AppColors.tableAvailable
                              : AppColors.tableOccupied,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.inputSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onCheckoutSession,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'CLOSE TABLE & SETTLE',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ] else ...[
                  // Idle Table State
                  Text(
                    table.specsDescription.isEmpty
                        ? 'Standard Snooker Table'
                        : table.specsDescription,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'General Price',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '₹${table.generalPrice.toStringAsFixed(0)} / hr',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (table.customPricings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandAccent.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${table.customPricings.length} Custom Rates',
                            style: const TextStyle(
                              color: AppColors.brandAccentLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Start Match Button
                  ElevatedButton.icon(
                    onPressed: onStartSession,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      'START TABLE',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tableAvailable,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  // Admin Only: Configure Rates Button
                  if (activeOperator.isAdmin) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onConfigureRates,
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Configure Prices & Times'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
