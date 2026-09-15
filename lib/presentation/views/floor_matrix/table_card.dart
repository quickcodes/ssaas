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
  final VoidCallback onAddFnb;
  final VoidCallback onOpenQrHub;
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
    required this.onAddFnb,
    required this.onOpenQrHub,
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
    final hasActiveSession = session != null && !session!.isPaid;
    final playedSeconds = hasActiveSession ? session!.playedSecondsAt(now) : 0;
    final liveTableFee = hasActiveSession
        ? session!.computeTableChargeAt(now)
        : 0.0;
    final liveGrandTotal = hasActiveSession
        ? session!.computeGrandTotalAt(now)
        : 0.0;

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
                  color: _statusColor.withAlpha(25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Table Number, Status Tag, and QR button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputSurface.withAlpha(160),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.cardBorderStroke),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Table Name & Type
                Expanded(
                  child: Row(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              table.name,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              table.type.displayName,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _statusColor.withAlpha(120)),
                  ),
                  child: Text(
                    table.status.displayName.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // QR Code Button
                Tooltip(
                  message: 'Open Table QR Information Hub',
                  child: InkWell(
                    onTap: onOpenQrHub,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        size: 16,
                        color: AppColors.brandAccentLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: Content based on status
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: hasActiveSession
                  ? _buildOccupiedBody(
                      liveTableFee,
                      liveGrandTotal,
                      playedSeconds,
                    )
                  : _buildAvailableOrOtherBody(),
            ),
          ),

          // Footer: Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(
                top: BorderSide(color: AppColors.cardBorderStroke),
              ),
            ),
            child: _buildActionButtons(hasActiveSession),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupiedBody(
    double liveTableFee,
    double liveGrandTotal,
    int playedSeconds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Running Timer Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.tableOccupied.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.tableOccupied.withAlpha(80)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    session!.isPaused
                        ? Icons.pause_circle_outline
                        : Icons.timer,
                    color: session!.isPaused
                        ? AppColors.tableMaintenance
                        : AppColors.tableOccupied,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    session!.isPaused ? 'PAUSED' : 'LIVE TIME',
                    style: TextStyle(
                      color: session!.isPaused
                          ? AppColors.tableMaintenance
                          : AppColors.tableOccupied,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                AppFormatters.formatDuration(playedSeconds),
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Player Name & Operator Tag
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Player / Group',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                Text(
                  session!.playerName,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Shift Operator',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                Text(
                  session!.operatorName,
                  style: const TextStyle(
                    color: AppColors.brandAccentLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Live Bill Breakdown
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorderStroke),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table (${session!.billingMode.displayName})',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(liveTableFee),
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (session!.fnbAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'F&B / Canteen Tab',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      AppFormatters.currency(session!.fnbAmount),
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              const Divider(color: AppColors.cardBorderStroke),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Total',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(liveGrandTotal),
                    style: const TextStyle(
                      color: AppColors.tableAvailable,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableOrOtherBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Specs Description
        Text(
          table.specsDescription,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),

        // Rates & Felt hours
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoCol(
              'Std Rate',
              '₹${table.standardRatePerHour.toInt()}/hr',
            ),
            _buildInfoCol('Peak Rate', '₹${table.peakRatePerHour.toInt()}/hr'),
            _buildInfoCol(
              'Felt Hours',
              '${table.cumulativeClothHours.toStringAsFixed(1)}h',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Only timer-capable operators can change operational table state.
        if (activeOperator.role.canManageRates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: onConfigureRates,
              icon: const Icon(Icons.tune, size: 15),
              label: Text(
                'Configure rates${table.rateSchedules.isEmpty ? '' : ' (${table.rateSchedules.length})'}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        if (activeOperator.role.canControlTimers)
          Row(
            children: [
              if (table.status != TableStatus.available)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onUpdateStatus(TableStatus.available),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: AppColors.tableAvailable,
                      side: const BorderSide(color: AppColors.tableAvailable),
                    ),
                    child: const Text(
                      'Mark Open',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              if (table.status == TableStatus.available) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onUpdateStatus(TableStatus.maintenance),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: AppColors.tableMaintenance,
                      side: const BorderSide(color: AppColors.tableMaintenance),
                    ),
                    child: const Text(
                      'Iron Felt',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onUpdateStatus(TableStatus.reserved),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: AppColors.tableReserved,
                      side: const BorderSide(color: AppColors.tableReserved),
                    ),
                    child: const Text(
                      'Reserve',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool hasActiveSession) {
    final canControl = activeOperator.role.canControlTimers;

    if (hasActiveSession) {
      return Row(
        children: [
          // Pause/Resume toggle
          IconButton(
            onPressed: canControl
                ? (session!.isPaused ? onResumeSession : onPauseSession)
                : null,
            icon: Icon(
              session!.isPaused ? Icons.play_arrow : Icons.pause,
              color: session!.isPaused
                  ? AppColors.tableAvailable
                  : AppColors.tableMaintenance,
              size: 20,
            ),
            tooltip: session!.isPaused ? 'Resume Clock' : 'Pause Clock',
            style: IconButton.styleFrom(backgroundColor: AppColors.cardSurface),
          ),
          const SizedBox(width: 6),

          // Add F&B to Tab
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canControl ? onAddFnb : null,
              icon: const Icon(
                Icons.fastfood_outlined,
                size: 14,
                color: AppColors.brandAccentLight,
              ),
              label: const Text('+ F&B', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: AppColors.brandAccent),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Checkout & Pay
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canControl ? onCheckoutSession : null,
              icon: const Icon(Icons.payment, size: 14),
              label: const Text(
                'CHECKOUT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tableOccupied,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canControl ? onStartSession : null,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text(
                'START SESSION',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tableAvailable,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }
  }
}
