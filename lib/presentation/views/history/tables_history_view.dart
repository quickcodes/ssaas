import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/fade_slide_transition.dart';
import 'settle_due_payment_screen.dart';
import 'share_history_report_dialog.dart';

class TablesHistoryView extends StatefulWidget {
  const TablesHistoryView({super.key});

  @override
  State<TablesHistoryView> createState() => _TablesHistoryViewState();
}

class _TablesHistoryViewState extends State<TablesHistoryView> {
  String _filterStatus = 'All'; // 'All', 'Received', 'Due'
  String _searchQuery = '';

  void _showShareReportDialog(
    BuildContext context,
    List<TableHistoryRecord> allHistory,
    String companyName,
  ) {
    showDialog(
      context: context,
      builder: (_) => ShareHistoryReportDialog(
        companyName: companyName,
        allRecords: allHistory,
      ),
    );
  }

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
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
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
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.cardBorderStroke),
                const SizedBox(height: 14),

                // Customer & Closed By
                _buildDetailRow('Closing Person', record.customerName),
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
                  'Payment Status',
                  record.isReceived
                      ? 'Received (${record.paymentMethod ?? "Cash"})'
                      : (record.isPartiallyPaid
                            ? 'Due (₹${record.dueAmount.toStringAsFixed(2)} Pending)'
                            : 'Due (Payment Pending)'),
                  valueColor: record.isReceived
                      ? AppColors.tableAvailable
                      : AppColors.tableOccupied,
                ),
                if (record.paidAmount > 0)
                  _buildDetailRow(
                    'Amount Received',
                    '₹${record.paidAmount.toStringAsFixed(2)}${record.paymentMethod != null ? " (${record.paymentMethod})" : ""}',
                    valueColor: AppColors.tableAvailable,
                  ),
                if (record.isDue)
                  _buildDetailRow(
                    'Remaining Due',
                    '₹${record.dueAmount.toStringAsFixed(2)}',
                    valueColor: AppColors.tableOccupied,
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
                    border: Border.all(
                      color: AppColors.brandAccent.withAlpha(100),
                    ),
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
                if (record.isDue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tableOccupied.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.tableOccupied.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pending_actions,
                          color: AppColors.tableOccupied,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Due: ₹${record.dueAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.tableOccupied,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.isPartiallyPaid
                                    ? 'Customer has paid ₹${record.paidAmount.toStringAsFixed(2)} so far. Remaining balance is ₹${record.dueAmount.toStringAsFixed(2)}.'
                                    : 'Full payment of ₹${record.totalAmount.toStringAsFixed(2)} is pending for this match.',
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
                ],
                const SizedBox(height: 16),

                // Payment Transactions History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PAYMENT TRANSACTIONS',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (record.transactions.isNotEmpty)
                      Text(
                        '${record.transactions.length} payment${record.transactions.length > 1 ? "s" : ""}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (record.transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.secondaryText,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No payment transactions recorded yet.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      children: record.transactions.asMap().entries.map((
                        entry,
                      ) {
                        final idx = entry.key;
                        final tx = entry.value;
                        final isLast = idx == record.transactions.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.tableAvailable.withAlpha(
                                        25,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward,
                                      size: 14,
                                      color: AppColors.tableAvailable,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '+₹${tx.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: AppColors.tableAvailable,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandAccent
                                                    .withAlpha(40),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                tx.paymentMethod.toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppColors
                                                      .brandAccentLight,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${DateFormat("dd MMM yyyy, hh:mm a").format(tx.receivedAt)} • by ${tx.receivedBy}',
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
                            if (!isLast)
                              const Divider(
                                color: AppColors.cardBorderStroke,
                                height: 1,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: AppColors.secondaryText,
                          side: const BorderSide(
                            color: AppColors.cardBorderStroke,
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    if (record.isDue) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _showRecordPaymentDialog(context, record);
                          },
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: const Text(
                            'RECEIVE PAYMENT',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecordPaymentDialog(
    BuildContext context,
    TableHistoryRecord record,
  ) {
    AppNavigation.pushSmooth(context, SettleDuePaymentScreen(record: record));
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
    final activeCompany = context.watch<AuthBloc>().state.activeCompany;
    if (activeCompany == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final companyId = activeCompany.id;
    final companyName = activeCompany.name;

    return StreamBuilder<List<TableHistoryRecord>>(
      stream: sl<FirestoreService>().watchTablesHistory(companyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allHistory = snapshot.data!;
        final filtered = allHistory.where((r) {
          final matchesStatus =
              _filterStatus == 'All' ||
              (_filterStatus == 'Received' && r.isReceived) ||
              (_filterStatus == 'Due' && r.isDue);

          final matchesSearch =
              _searchQuery.isEmpty ||
              r.customerName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              r.tableName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.closedByName.toLowerCase().contains(_searchQuery.toLowerCase());

          return matchesStatus && matchesSearch;
        }).toList();

        final totalMatches = allHistory.length;
        final totalReceived = allHistory.fold<double>(
          0.0,
          (sum, r) => sum + r.paidAmount,
        );
        final totalDue = allHistory.fold<double>(
          0.0,
          (sum, r) => sum + r.dueAmount,
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row with Share Report Button
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    const Column(
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
                    ElevatedButton.icon(
                      onPressed: () => _showShareReportDialog(
                        context,
                        allHistory,
                        companyName,
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text(
                        'Report',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Bar: Matches, Received, Due
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by customer, table, or staff name...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter & Search Controls
                // Row(
                //   children: [
                //     _buildStatusFilterChip('All', 'All Matches'),
                //     const SizedBox(width: 8),
                //     _buildStatusFilterChip(
                //       'Received',
                //       'Received',
                //       color: AppColors.tableAvailable,
                //     ),
                //     const SizedBox(width: 8),
                //     _buildStatusFilterChip(
                //       'Due',
                //       'Due',
                //       color: AppColors.tableOccupied,
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 16),

                // List of Records
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateCard(
                          icon: Icons.history,
                          title: allHistory.isEmpty
                              ? 'No Closed Matches Yet'
                              : 'No Matching Records',
                          subtitle: allHistory.isEmpty
                              ? 'Once running tables are checked out and bills are settled, detailed match history records will appear here.'
                              : 'No matches found matching your current search or filter criteria.',
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final record = filtered[index];
                            final isMobile = Responsive.isMobile(context);

                            return FadeSlideTransitionWidget(
                              index: index,
                              child: InkWell(
                                onTap: () {
                                  AppHaptics.light();
                                  _showMatchDetailsModal(context, record);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 14 : 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: record.isDue
                                          ? AppColors.tableOccupied.withAlpha(
                                              90,
                                            )
                                          : AppColors.cardBorderStroke,
                                      width: record.isDue ? 1.4 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(30),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: isMobile
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: record.isReceived
                                                        ? AppColors
                                                              .tableAvailable
                                                              .withAlpha(25)
                                                        : AppColors
                                                              .tableOccupied
                                                              .withAlpha(25),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    record.isReceived
                                                        ? Icons
                                                              .check_circle_outline
                                                        : Icons.pending_actions,
                                                    color: record.isReceived
                                                        ? AppColors
                                                              .tableAvailable
                                                        : AppColors
                                                              .tableOccupied,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    record.tableName,
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.primaryText,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: record.isReceived
                                                        ? AppColors
                                                              .tableAvailable
                                                              .withAlpha(25)
                                                        : AppColors
                                                              .tableOccupied
                                                              .withAlpha(25),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: record.isReceived
                                                          ? AppColors
                                                                .tableAvailable
                                                                .withAlpha(120)
                                                          : AppColors
                                                                .tableOccupied
                                                                .withAlpha(120),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    record.isReceived
                                                        ? 'RECEIVED'
                                                        : (record.isPartiallyPaid
                                                              ? 'DUE: ₹${record.dueAmount.toStringAsFixed(0)}'
                                                              : 'DUE'),
                                                    style: TextStyle(
                                                      color: record.isReceived
                                                          ? AppColors
                                                                .tableAvailable
                                                          : AppColors
                                                                .tableOccupied,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Customer: ${record.customerName}',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .primaryText,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${DateFormat('dd MMM, hh:mm a').format(record.closedAt)}  •  ${record.durationMinutes}m',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .secondaryText,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      record.isReceived
                                                          ? '₹${record.totalAmount.toStringAsFixed(0)}'
                                                          : '₹${record.dueAmount.toStringAsFixed(0)} Due',
                                                      style: TextStyle(
                                                        color: record.isReceived
                                                            ? AppColors
                                                                  .tableAvailable
                                                            : AppColors
                                                                  .tableOccupied,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    if (record.isPartiallyPaid)
                                                      Text(
                                                        'Paid ₹${record.paidAmount.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .secondaryText,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.chevron_right,
                                                  color:
                                                      AppColors.secondaryText,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            // Status icon badge
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: record.isReceived
                                                    ? AppColors.tableAvailable
                                                          .withAlpha(25)
                                                    : AppColors.tableOccupied
                                                          .withAlpha(25),
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
                                                  Wrap(
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: [
                                                      Text(
                                                        record.tableName,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .primaryText,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              record.isReceived
                                                              ? AppColors
                                                                    .tableAvailable
                                                                    .withAlpha(
                                                                      30,
                                                                    )
                                                              : AppColors
                                                                    .tableOccupied
                                                                    .withAlpha(
                                                                      30,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          record.isReceived
                                                              ? 'RECEIVED'
                                                              : (record.isPartiallyPaid
                                                                    ? 'DUE (₹${record.dueAmount.toStringAsFixed(0)})'
                                                                    : 'DUE'),
                                                          style: TextStyle(
                                                            color:
                                                                record
                                                                    .isReceived
                                                                ? AppColors
                                                                      .tableAvailable
                                                                : AppColors
                                                                      .tableOccupied,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'Closed On: ${record.customerName}  •  Staff: ${record.closedByName}',
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .secondaryText,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                    DateFormat(
                                                      'dd MMM, hh:mm a',
                                                    ).format(record.closedAt),
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.primaryText,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${record.durationMinutes} mins played',
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .secondaryText,
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
                                                if (record.isReceived) ...[
                                                  Text(
                                                    '₹${record.totalAmount.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .tableAvailable,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (record.paymentMethod !=
                                                      null)
                                                    Text(
                                                      record.paymentMethod!,
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .secondaryText,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                ] else ...[
                                                  Text(
                                                    '₹${record.dueAmount.toStringAsFixed(0)} Due',
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .tableOccupied,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    record.isPartiallyPaid
                                                        ? 'Paid ₹${record.paidAmount.toStringAsFixed(0)}'
                                                        : 'Total ₹${record.totalAmount.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .secondaryText,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
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

  // ignore: unused_element
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
            color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String title, String value, Color color, IconData icon) {
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
