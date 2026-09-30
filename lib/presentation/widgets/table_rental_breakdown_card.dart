import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/rental_calculation_breakdown.dart';

/// A card displaying the itemized calculation breakdown of table rent,
/// including standard rate, custom tier pricing (if any), durations, and pause deductions.
class TableRentalBreakdownCard extends StatelessWidget {
  final RentalCalculationBreakdown breakdown;
  final bool isCompact;

  const TableRentalBreakdownCard({
    super.key,
    required this.breakdown,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustom = breakdown.hasCustomRates &&
        breakdown.segments.any((s) => s.isCustomRate);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputSurface.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCustom
              ? Colors.orangeAccent.withAlpha(90)
              : AppColors.cardBorderStroke,
          width: hasCustom ? 1.2 : 1.0,
        ),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Wrap to avoid narrow modal overflows
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: hasCustom
                        ? Colors.orangeAccent
                        : AppColors.brandAccentLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TABLE RENT BREAKDOWN',
                    style: TextStyle(
                      color: hasCustom
                          ? Colors.orangeAccent
                          : AppColors.brandAccentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasCustom
                      ? Colors.orange.withAlpha(35)
                      : AppColors.brandAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasCustom
                        ? Colors.orangeAccent.withAlpha(120)
                        : AppColors.brandAccentLight.withAlpha(90),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasCustom) ...[
                      const Icon(
                        Icons.bolt,
                        size: 11,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      hasCustom ? 'CUSTOM RATE ACTIVE' : 'STANDARD RATE',
                      style: TextStyle(
                        color: hasCustom
                            ? Colors.orangeAccent
                            : AppColors.brandAccentLight,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Standard Hourly Rate & Active Duration Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.cardSurface.withAlpha(180),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Base Rate: ',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${breakdown.baseHourlyRate.toStringAsFixed(2)}/hr',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Billed Time: ',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${breakdown.durationMinutes} mins',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Segments list (rate tiers applied)
          if (breakdown.segments.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Standard Hourly Rate (₹${breakdown.baseHourlyRate.toStringAsFixed(2)}/hr)',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${breakdown.totalRentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...breakdown.segments.map((segment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: segment.isCustomRate
                      ? Colors.orange.withAlpha(15)
                      : AppColors.cardSurface.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: segment.isCustomRate
                        ? Colors.orangeAccent.withAlpha(60)
                        : AppColors.cardBorderStroke,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                segment.rateName,
                                style: TextStyle(
                                  color: segment.isCustomRate
                                      ? Colors.orangeAccent
                                      : AppColors.primaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (segment.isCustomRate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'CUSTOM TIER',
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${segment.durationMinutes}m (${segment.durationHours.toStringAsFixed(2)}h) × ₹${segment.hourlyRate.toStringAsFixed(2)}/hr'
                            '${segment.timeWindow != null ? " • Slot: ${segment.timeWindow}" : ""}',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${segment.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: segment.isCustomRate
                            ? Colors.orangeAccent
                            : AppColors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Pause deduction notice if table was paused
          if (breakdown.pausedSeconds > 0) ...[
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pause_circle_outline,
                    size: 15,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paused Time: ${breakdown.pausedMinutes} mins (Excluded from rent)',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Text(
                    '₹0.00',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
          const Divider(color: AppColors.cardBorderStroke, height: 1),
          const SizedBox(height: 6),

          // Total Table Rent Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calculated Table Rent',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${breakdown.totalRentAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.tableAvailable,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
