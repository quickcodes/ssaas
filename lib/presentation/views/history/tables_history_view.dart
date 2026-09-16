import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../blocs/auth/auth_bloc.dart';

class TablesHistoryView extends StatefulWidget {
  const TablesHistoryView({super.key});

  @override
  State<TablesHistoryView> createState() => _TablesHistoryViewState();
}

class _TablesHistoryViewState extends State<TablesHistoryView> {
  String _filterStatus = 'All'; // 'All', 'Received', 'Due'
  String _searchQuery = '';

  void _showMatchDetailsModal(BuildContext context, TableHistoryRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(26),
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
                      const Text(
                        'MATCH RECORD DETAILS',
                        style: TextStyle(
                          color: AppColors.brandAccentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.tableName,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.cardBorderStroke),
              const SizedBox(height: 14),

              // Customer & Closed By
              _buildDetailRow('Customer Name', record.customerName),
              _buildDetailRow('Closed By (Staff)', record.closedByName),
              _buildDetailRow('Started By', record.startedByName),
              _buildDetailRow(
                'Start Time',
                DateFormat('dd MMM yyyy, hh:mm a').format(record.startedAt),
              ),
              _buildDetailRow(
                'End Time',
                DateFormat('dd MMM yyyy, hh:mm a').format(record.closedAt),
              ),
              _buildDetailRow(
                'Duration',
                '${record.durationMinutes} mins (${(record.durationMinutes / 60.0).toStringAsFixed(1)} hrs)',
              ),
              _buildDetailRow(
                'Payment Settlement',
                record.isReceived
                    ? 'Received (${record.paymentMethod ?? "Cash"})'
                    : 'Due (Payment Pending)',
                valueColor: record.isReceived
                    ? AppColors.tableAvailable
                    : AppColors.tableOccupied,
              ),
              const SizedBox(height: 14),

              // Itemization
              const Text(
                'CHARGES ITEMIZATION',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Table Rental Charge',
                '₹${record.tableAmount.toStringAsFixed(2)}',
              ),

              if (record.items.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: record.items.map((i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${i.quantity}x ${i.name}${i.isCustom ? " (Custom)" : ""}',
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '₹${i.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Grand Total Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brandAccent.withAlpha(100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Match Amount',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '₹${record.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.brandAccentLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.inputSurface,
                  foregroundColor: AppColors.primaryText,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyId = context.watch<AuthBloc>().state.activeCompany?.id;
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<TableHistoryRecord>>(
      stream: sl<FirestoreService>().watchTablesHistory(companyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allHistory = snapshot.data!;
        final filtered = allHistory.where((r) {
          final matchesStatus = _filterStatus == 'All' ||
              (_filterStatus == 'Received' && r.isReceived) ||
              (_filterStatus == 'Due' && r.isDue);

          final matchesSearch = _searchQuery.isEmpty ||
              r.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.tableName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.closedByName.toLowerCase().contains(_searchQuery.toLowerCase());

          return matchesStatus && matchesSearch;
        }).toList();

        final totalMatches = allHistory.length;
        final totalReceived = allHistory
            .where((r) => r.isReceived)
            .fold<double>(0.0, (sum, r) => sum + r.totalAmount);
        final totalDue = allHistory
            .where((r) => r.isDue)
            .fold<double>(0.0, (sum, r) => sum + r.totalAmount);

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREVIOUS CLOSED TABLES',
                          style: TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tables Match History',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Bar: Matches, Received, Due
                Row(
                  children: [
                    _buildPill(
                      'Total Matches',
                      totalMatches.toString(),
                      AppColors.brandAccentLight,
                      Icons.history,
                    ),
                    const SizedBox(width: 12),
                    _buildPill(
                      'Total Received',
                      '₹${totalReceived.toStringAsFixed(0)}',
                      AppColors.tableAvailable,
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 12),
                    _buildPill(
                      'Total Due Amount',
                      '₹${totalDue.toStringAsFixed(0)}',
                      totalDue > 0
                          ? AppColors.tableOccupied
                          : AppColors.secondaryText,
                      Icons.pending_actions,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter & Search Controls
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Search by customer, table, or staff name...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusFilterChip('All', 'All Matches'),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(
                      'Received',
                      'Received',
                      color: AppColors.tableAvailable,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip(
                      'Due',
                      'Due',
                      color: AppColors.tableOccupied,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // List of Records
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            allHistory.isEmpty
                                ? 'No closed table matches recorded yet.'
                                : 'No records match your filter criteria.',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final record = filtered[index];

                            return InkWell(
                              onTap: () =>
                                  _showMatchDetailsModal(context, record),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: record.isDue
                                        ? AppColors.tableOccupied.withAlpha(80)
                                        : AppColors.cardBorderStroke,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Status icon badge
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: record.isReceived
                                            ? AppColors.tableAvailable
                                                .withAlpha(30)
                                            : AppColors.tableOccupied
                                                .withAlpha(30),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        record.isReceived
                                            ? Icons.check_circle_outline
                                            : Icons.pending_actions,
                                        color: record.isReceived
                                            ? AppColors.tableAvailable
                                            : AppColors.tableOccupied,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Table & Customer Info
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                record.tableName,
                                                style: const TextStyle(
                                                  color: AppColors.primaryText,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: record.isReceived
                                                      ? AppColors.tableAvailable
                                                          .withAlpha(30)
                                                      : AppColors.tableOccupied
                                                          .withAlpha(30),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  record.isReceived
                                                      ? 'RECEIVED'
                                                      : 'DUE',
                                                  style: TextStyle(
                                                    color: record.isReceived
                                                        ? AppColors.tableAvailable
                                                        : AppColors
                                                            .tableOccupied,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Customer: ${record.customerName}  •  Closed By: ${record.closedByName}',
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Timing & Duration
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('dd MMM, hh:mm a')
                                                .format(record.closedAt),
                                            style: const TextStyle(
                                              color: AppColors.primaryText,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${record.durationMinutes} mins played',
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Amount
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${record.totalAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: record.isReceived
                                                ? AppColors.tableAvailable
                                                : AppColors.tableOccupied,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                          ),
                                        ),
                                        if (record.isReceived &&
                                            record.paymentMethod != null)
                                          Text(
                                            record.paymentMethod!,
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.secondaryText,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterChip(String status, String label, {Color? color}) {
    final isSelected = _filterStatus == status;
    final chipColor = color ?? AppColors.brandAccentLight;
    return InkWell(
      onTap: () => setState(() => _filterStatus = status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withAlpha(35) : AppColors.inputSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.cardBorderStroke,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primaryText
                : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPill(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
