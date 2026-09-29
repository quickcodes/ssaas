import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';
import '../../widgets/bouncing_tap.dart';
import '../../widgets/pulsing_badge.dart';

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
  final VoidCallback? onDeleteTable;

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
    this.onDeleteTable,
  });

  Color get _statusColor {
    switch (table.status) {
      case TableStatus.available:
        return AppColors.tableAvailable;
      case TableStatus.occupied:
        return AppColors.tableOccupied;
      case TableStatus.maintenance:
        return AppColors.tableMaintenance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = session != null;
    final playedSeconds = hasActiveSession ? session!.playedSecondsAt(now) : 0;
    final liveTableFee = hasActiveSession
        ? session!.computeTableChargeAt(now)
        : 0.0;
    final liveItemsFee = hasActiveSession ? session!.itemsAmount : 0.0;
    final liveGrandTotal = liveTableFee + liveItemsFee;
    final currentHourlyRate = hasActiveSession
        ? session!.effectiveRateAt(now)
        : table.effectiveRateAt(now);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasActiveSession
              ? _statusColor.withAlpha(200)
              : AppColors.cardBorderStroke,
          width: hasActiveSession ? 1.8 : 1.0,
        ),
        boxShadow: [
          if (hasActiveSession)
            BoxShadow(
              color: _statusColor.withAlpha(35),
              blurRadius: 22,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header: Table Name & Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputSurface.withAlpha(160),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.cardBorderStroke),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (table.status == TableStatus.occupied)
                      PulsingBadge(color: _statusColor, size: 10)
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withAlpha(160),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      table.name,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Popup Menu
                    PopupMenuButton<TableStatus>(
                      initialValue: table.status,
                      tooltip: 'Change Table Status',
                      onSelected: (status) {
                        AppHaptics.selection();
                        onUpdateStatus(status);
                      },
                      color: AppColors.cardSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: AppColors.cardBorderStroke,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _statusColor.withAlpha(160),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              table.status.displayName,
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: _statusColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => TableStatus.values
                          .where((e) => e != TableStatus.occupied)
                          .map((s) {
                            return PopupMenuItem<TableStatus>(
                              value: s,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getStatusColorFor(s),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.displayName,
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ),

                    if (activeOperator.isAdmin) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        tooltip: 'Table Options',
                        icon: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.secondaryText,
                        ),
                        color: AppColors.cardSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.cardBorderStroke,
                          ),
                        ),
                        onSelected: (val) {
                          AppHaptics.selection();
                          if (val == 'edit') {
                            onConfigureRates();
                          } else if (val == 'delete') {
                            onDeleteTable?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.brandAccentLight,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Edit Table & Rates',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            enabled: !hasActiveSession,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: hasActiveSession
                                      ? AppColors.textDisabled
                                      : AppColors.tableOccupied,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Table',
                                  style: TextStyle(
                                    color: hasActiveSession
                                        ? AppColors.textDisabled
                                        : AppColors.tableOccupied,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
                            session!.customerPhone.isNotEmpty
                                ? 'Customer: ${session!.customerName} (${session!.customerPhone})'
                                : 'Customer: ${session!.customerName}',
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatDuration(playedSeconds),
                            style: const TextStyle(
                              color: AppColors.tableAvailable,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              fontFamily: 'monospace',
                              letterSpacing: 1.0,
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${liveGrandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.brandAccentLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 21,
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
                            fontWeight: FontWeight.w600,
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
                        child: BouncingTap(
                          onTap: () {
                            AppHaptics.light();
                            onAddItem();
                          },
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppHaptics.light();
                              onAddItem();
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text(
                              'Add Items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: const BorderSide(
                                color: AppColors.brandAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Pause / Resume toggle
                      BouncingTap(
                        onTap: () {
                          AppHaptics.medium();
                          if (session!.isPaused) {
                            onResumeSession();
                          } else {
                            onPauseSession();
                          }
                        },
                        child: IconButton(
                          onPressed: () {
                            AppHaptics.medium();
                            if (session!.isPaused) {
                              onResumeSession();
                            } else {
                              onPauseSession();
                            }
                          },
                          tooltip: session!.isPaused
                              ? 'Resume Clock'
                              : 'Pause Clock',
                          icon: Icon(
                            session!.isPaused ? Icons.play_arrow : Icons.pause,
                            color: session!.isPaused
                                ? AppColors.tableAvailable
                                : AppColors.tableOccupied,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.inputSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BouncingTap(
                    onTap: () {
                      AppHaptics.medium();
                      onCheckoutSession();
                    },
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AppHaptics.medium();
                        onCheckoutSession();
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'CLOSE TABLE & SETTLE',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₹${table.generalPrice.toStringAsFixed(0)} / hr',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w800,
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
                  if (table.status == TableStatus.available)
                    BouncingTap(
                      onTap: () {
                        AppHaptics.medium();
                        onStartSession();
                      },
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppHaptics.medium();
                          onStartSession();
                        },
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text(
                          'START TABLE',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tableAvailable,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                  // Admin Only: Edit & Delete Table Buttons
                  // if (activeOperator.isAdmin) ...[
                  //   const SizedBox(height: 10),
                  //   Row(
                  //     children: [
                  //       Expanded(
                  //         child: TextButton.icon(
                  //           onPressed: () {
                  //             AppHaptics.light();
                  //             onConfigureRates();
                  //           },
                  //           icon: const Icon(Icons.edit_outlined, size: 15),
                  //           label: const Text('Edit Table'),
                  //           style: TextButton.styleFrom(
                  //             foregroundColor: AppColors.secondaryText,
                  //           ),
                  //         ),
                  //       ),
                  //       if (onDeleteTable != null)
                  //         TextButton.icon(
                  //           onPressed: () {
                  //             AppHaptics.light();
                  //             onDeleteTable!();
                  //           },
                  //           icon: const Icon(
                  //             Icons.delete_outline,
                  //             size: 15,
                  //             color: AppColors.tableOccupied,
                  //           ),
                  //           label: const Text(
                  //             'Delete',
                  //             style: TextStyle(color: AppColors.tableOccupied),
                  //           ),
                  //           style: TextButton.styleFrom(
                  //             foregroundColor: AppColors.tableOccupied,
                  //           ),
                  //         ),
                  //     ],
                  //   ),
                  // ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColorFor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppColors.tableAvailable;
      case TableStatus.occupied:
        return AppColors.tableOccupied;
      case TableStatus.maintenance:
        return AppColors.tableMaintenance;
    }
  }
}
