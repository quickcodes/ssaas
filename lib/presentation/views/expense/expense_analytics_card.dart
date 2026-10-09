import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ExpenseAnalyticsCard extends StatelessWidget {
  final double totalAmount;
  final Map<String, double> categoryBreakdown;
  final String periodLabel;

  const ExpenseAnalyticsCard({
    super.key,
    required this.totalAmount,
    required this.categoryBreakdown,
    required this.periodLabel,
  });

  static const _chartColors = [
    AppColors.brandAccent,
    AppColors.tableAvailable,
    AppColors.tableMaintenance,
    AppColors.tableOccupied,
    AppColors.tableReserved,
    AppColors.brandAccentLight,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL SPENT • ${periodLabel.toUpperCase()}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8)),
          const SizedBox(height: 4),
          Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primaryText, fontSize: 28, fontWeight: FontWeight.w800)),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 3,
                sections: List.generate(entries.length, (index) {
                  final entry = entries[index];
                  return PieChartSectionData(
                    value: entry.value,
                    color: _chartColors[index % _chartColors.length],
                    radius: 48,
                    showTitle: false,
                  );
                }),
              )),
            ),
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              final percentage = totalAmount == 0 ? 0 : entry.value / totalAmount * 100;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _chartColors[index % _chartColors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600))),
                  Text('₹${entry.value.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primaryText)),
                  const SizedBox(width: 8),
                  Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ]),
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text('No expenses in this period yet.', style: TextStyle(color: AppColors.secondaryText)),
            ),
        ],
      ),
    );
  }
}
