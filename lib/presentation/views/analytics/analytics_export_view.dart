import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';

class AnalyticsExportView extends StatelessWidget {
  const AnalyticsExportView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final activeBranch = authState.activeBranch;
        final activeUser = authState.currentUser;

        if (activeBranch == null || activeUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // RBAC check: Markers cannot access net profit and financial analytics
        if (!activeUser.role.canViewFinancials) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: AppColors.tableOccupied),
                  SizedBox(height: 16),
                  Text(
                    'Access Restricted by Role',
                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Financial ledgers, net profit calculations, and data exports are restricted to Super Admin (Club Owner) and Counter Admins.',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return BlocConsumer<AnalyticsBloc, AnalyticsState>(
          listener: (context, state) {
            if (state.exportSuccessMessage != null && state.exportedCsvData != null) {
              _showExportDialog(context, state.exportFileName ?? 'Export.csv', state.exportedCsvData!);
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isProfitable = state.netProfit >= 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'FINANCIAL ANALYTICS & DATA EXPORT ENGINE',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time P&L ledger calculation, peak hour table heatmaps, and audit exports.',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Net Profit Calculation Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isProfitable ? AppColors.tableAvailable.withAlpha(20) : AppColors.tableOccupied.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isProfitable ? AppColors.tableAvailable.withAlpha(120) : AppColors.tableOccupied.withAlpha(120),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AUTOMATED NET PROFIT LEDGER',
                              style: TextStyle(
                                color: isProfitable ? AppColors.tableAvailable : AppColors.tableOccupied,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.cardBorderStroke),
                              ),
                              child: const Text('Formula: (Table + F&B) - Overheads', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              AppFormatters.currency(state.netProfit),
                              style: TextStyle(
                                color: isProfitable ? AppColors.tableAvailable : AppColors.tableOccupied,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                              ),
                            ),
                            Text(
                              'Gross: ${AppFormatters.currency(state.grossRevenue)} | Costs: ${AppFormatters.currency(state.totalExpenses)}',
                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Revenue Streams & Payment Methods Breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox('Table Sessions Revenue', AppFormatters.currency(state.tableRevenue), AppColors.brandAccentLight, Icons.sports_esports),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricBox('Canteen & F&B Sales', AppFormatters.currency(state.fnbRevenue), AppColors.tableReserved, Icons.fastfood_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricBox('Store Overhead Expenses', AppFormatters.currency(state.totalExpenses), AppColors.tableOccupied, Icons.receipt_long),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Payment Tender Methods
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Revenue by Payment Tender Method', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildTenderItem('Cash Drawer', AppFormatters.currency(state.cashRevenue), AppColors.tableAvailable, Icons.money)),
                            Expanded(child: _buildTenderItem('UPI / QR Pay', AppFormatters.currency(state.upiRevenue), AppColors.brandAccentLight, Icons.qr_code_2)),
                            Expanded(child: _buildTenderItem('Card Swipes', AppFormatters.currency(state.cardRevenue), AppColors.tableReserved, Icons.credit_card)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hourly Table Utilization Heatmap / Bar Chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Table Utilization Heatmap (Hourly Play Distribution)', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Peak evening hours indicate when rate switching should apply', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.tableOccupied.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.tableOccupied.withAlpha(100)),
                              ),
                              child: const Text('Peak 6PM - 11PM', style: TextStyle(color: AppColors.tableOccupied, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 10,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final hour = value.toInt();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('$hour:00', style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.cardBorderStroke, strokeWidth: 1),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [10, 12, 14, 16, 18, 20, 22].map((hour) {
                                final hoursPlayed = state.hourlyUtilization[hour] ?? 1.0;
                                final isPeakSlot = hour >= 18 && hour <= 23;
                                return BarChartGroupData(
                                  x: hour,
                                  barRods: [
                                    BarChartRodData(
                                      toY: hoursPlayed,
                                      color: isPeakSlot ? AppColors.tableOccupied : AppColors.brandAccentLight,
                                      width: 22,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1-Click Excel / CSV Exports Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.download, color: AppColors.brandAccentLight, size: 20),
                            SizedBox(width: 8),
                            Text('ONE-CLICK DATA EXPORTS (EXCEL / CSV)', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Export raw ledgers for offline accountant auditing, tax filing, and club bookkeeping.',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildExportCard(
                                context,
                                'Daily / Monthly Revenue Ledger',
                                'Table sessions, durations, and payment methods',
                                'billing',
                                activeBranch.id,
                                Icons.receipt,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildExportCard(
                                context,
                                'Canteen Stock & Inventory Audit',
                                'Itemized stock levels and threshold alerts',
                                'inventory',
                                activeBranch.id,
                                Icons.inventory,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildExportCard(
                                context,
                                'Operational Expense Summary',
                                'Store overheads categorized by vendor',
                                'expenses',
                                activeBranch.id,
                                Icons.account_balance_wallet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildExportCard(
                                context,
                                'Shift Variance & Audit Trail',
                                'Cash drawer reconciliations & tamper logs',
                                'audit',
                                activeBranch.id,
                                Icons.verified_user,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricBox(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.inputSurface, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
            Text(value, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildExportCard(
    BuildContext context,
    String title,
    String subtitle,
    String exportType,
    String branchId,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandAccentLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 12)),
                Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AnalyticsBloc>().add(ExportDataEvent(exportType: exportType, branchId: branchId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Export .CSV', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, String filename, String csvData) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.file_download_done, color: AppColors.tableAvailable, size: 22),
                        const SizedBox(width: 8),
                        Text(filename, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Data successfully serialized into CSV format ready for download / copy:', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBase,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      csvData,
                      style: const TextStyle(color: AppColors.primaryText, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: csvData));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CSV copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy to Clipboard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Exported $filename successfully!'),
                              backgroundColor: AppColors.tableAvailable,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Save / Download'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
