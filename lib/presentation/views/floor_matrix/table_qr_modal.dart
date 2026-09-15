import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/club_branch.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';

class TableQrCustomerHubModal extends StatelessWidget {
  final ClubTable table;
  final TableSession? session;
  final ClubBranch branch;
  final DateTime now;

  const TableQrCustomerHubModal({
    super.key,
    required this.table,
    this.session,
    required this.branch,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = session != null && !session!.isPaid;
    final playedSecs = hasActiveSession ? session!.playedSecondsAt(now) : 0;
    final tableFee = hasActiveSession ? session!.computeTableChargeAt(now) : 0.0;
    final grandTotal = hasActiveSession ? session!.computeGrandTotalAt(now) : 0.0;

    // Simulated QR deep link
    final qrData = 'https://cueclub.app/table/${table.id}?branch=${branch.id}';

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderStroke, width: 1.5),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandAccent.withAlpha(50),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.brandAccent),
                          ),
                          child: const Text(
                            'TABLE QR INFORMATION HUB',
                            style: TextStyle(
                              color: AppColors.brandAccentLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          table.name,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          branch.name,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR Code and Instructions
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandAccent.withAlpha(40),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 160.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Scan with phone camera to view live table billing & specs',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Table Specifications Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderStroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_baseball, color: AppColors.brandAccentLight, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Verified Table Specifications',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      table.specsDescription,
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Rate Schedule Matrix
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderStroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule, color: AppColors.tableReserved, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Club Pricing Schedule',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRateBadge(
                            title: 'Standard Hours',
                            timing: 'All Day (Off-Peak)',
                            rate: '₹${table.standardRatePerHour.toStringAsFixed(0)} / hr',
                            color: AppColors.tableAvailable,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildRateBadge(
                            title: 'Peak Evening Slots',
                            timing: '${branch.peakStartHour}:00 - ${branch.peakEndHour}:00 PM',
                            rate: '₹${table.peakRatePerHour.toStringAsFixed(0)} / hr',
                            color: AppColors.tableOccupied,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Live Session Bill Status
              if (hasActiveSession)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tableOccupied.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.tableOccupied.withAlpha(120), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.tableOccupied,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVE ACTIVE SESSION',
                                style: TextStyle(
                                  color: AppColors.tableOccupied,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            AppFormatters.formatDuration(playedSecs),
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.cardBorderStroke),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Player / Group', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                          Text(session!.playerName, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Table Fee (Dynamic)', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                          Text(AppFormatters.currency(tableFee), style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      if (session!.fnbAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('F&B / Canteen Tab', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                            Text(AppFormatters.currency(session!.fnbAmount), style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Divider(color: AppColors.cardBorderStroke),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Total Bill', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(
                            AppFormatters.currency(grandTotal),
                            style: const TextStyle(
                              color: AppColors.tableAvailable,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tableAvailable.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.tableAvailable.withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.tableAvailable, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Table is Open & Available for Play',
                        style: TextStyle(
                          color: AppColors.tableAvailable,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close QR Hub'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateBadge({
    required String title,
    required String timing,
    required String rate,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(timing, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
          const SizedBox(height: 4),
          Text(rate, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
