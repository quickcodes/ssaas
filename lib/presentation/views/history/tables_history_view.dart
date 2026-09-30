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
import '../../../core/utils/history_report_exporter.dart';
import 'history_filter_dialog.dart';
import 'settle_due_payment_screen.dart';
import 'share_history_report_dialog.dart';
import '../../widgets/table_rental_breakdown_card.dart';

class TablesHistoryView extends StatefulWidget {
  const TablesHistoryView({super.key});

  @override
  State<TablesHistoryView> createState() => _TablesHistoryViewState();
}

class _TablesHistoryViewState extends State<TablesHistoryView> {
  String _filterStatus = 'All'; // 'All', 'Received', 'Due'
  String _searchQuery = '';
  HistoryReportPreset _selectedDatePreset = HistoryReportPreset.today;
  DateTimeRange? _customDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showShareReportDialog(
    BuildContext context,
    List<TableHistoryRecord> allHistory,
    String companyName,
    String companyId,
  ) {
    showDialog(
      context: context,
      builder: (_) => ShareHistoryReportDialog(
        companyName: companyName,
        companyId: companyId,
        allRecords: allHistory,
        initialPreset: _selectedDatePreset,
        initialCustomDateRange: _customDateRange,
      ),
    );
  }

  Future<void> _openFilterDialog(List<TableHistoryRecord> allHistory) async {
    AppHaptics.light();
    final result = await showDialog<HistoryFilterOption>(
      context: context,
      builder: (ctx) => HistoryFilterDialog(
        initialPreset: _selectedDatePreset,
        initialCustomRange: _customDateRange,
        initialStatus: _filterStatus,
        allRecords: allHistory,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDatePreset = result.preset;
        _customDateRange = result.customRange;
        _filterStatus = result.status;
      });
    }
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
                if (record.customerPhone.isNotEmpty)
                  _buildDetailRow('Customer Number', record.customerPhone),
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

                // Itemization & Table Rental Calculation
                TableRentalBreakdownCard(
                  breakdown: record.effectiveRentBreakdown,
                  isCompact: true,
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

    final activeRange = _selectedDatePreset == HistoryReportPreset.allTime
        ? null
        : HistoryReportDateRange.fromPreset(
            _selectedDatePreset,
            customRange: _customDateRange,
          );

    return StreamBuilder<List<TableHistoryRecord>>(
      stream: sl<FirestoreService>().watchTablesHistory(
        companyId,
        startDate: activeRange?.start,
        endDate: activeRange?.end,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allHistory = snapshot.data!;

        // 1. Date Period Filtering
        final List<TableHistoryRecord> periodRecords;
        if (_selectedDatePreset == HistoryReportPreset.allTime) {
          periodRecords = allHistory;
        } else {
          final range = HistoryReportDateRange.fromPreset(
            _selectedDatePreset,
            customRange: _customDateRange,
          );
          periodRecords = HistoryReportExporter.filterByDateRange(
            allHistory,
            range.start,
            range.end,
          );
        }

        // 2. Metrics Bar computed for the active period
        final totalMatches = periodRecords.length;
        final totalReceived = periodRecords.fold<double>(
          0.0,
          (sum, r) => sum + r.paidAmount,
        );
        final totalDue = periodRecords.fold<double>(
          0.0,
          (sum, r) => sum + r.dueAmount,
        );

        // 3. Search and Status Filtering
        final filtered = periodRecords.where((r) {
          final matchesStatus =
              _filterStatus == 'All' ||
              (_filterStatus == 'Received' && r.isReceived) ||
              (_filterStatus == 'Due' && r.isDue);

          final matchesSearch =
              _searchQuery.isEmpty ||
              r.customerName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              r.customerPhone.contains(_searchQuery) ||
              r.tableName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.closedByName.toLowerCase().contains(_searchQuery.toLowerCase());

          return matchesStatus && matchesSearch;
        }).toList();

        final isFilterActive =
            _selectedDatePreset != HistoryReportPreset.today ||
            _filterStatus != 'All';

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
                        companyId,
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

                // Search Bar & Filter Button Row
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText:
                                'Search by customer, table, or staff name...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildFilterButton(allHistory),
                    ],
                  ),
                ),

                // Active Filter Banner (shown when date preset or status filter is active)
                if (isFilterActive) ...[
                  const SizedBox(height: 10),
                  _buildActiveFilterBanner(),
                ],
                const SizedBox(height: 16),

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
                              : (isFilterActive
                                  ? 'No matches recorded for ${_selectedDatePreset != HistoryReportPreset.allTime ? _selectedDatePreset.label : "the selected criteria"}. Try selecting another period or resetting filters.'
                                  : 'No matches found matching your current search criteria.'),
                          actionLabel: (allHistory.isNotEmpty &&
                                  (isFilterActive || _searchQuery.isNotEmpty))
                              ? 'Reset Filters'
                              : null,
                          onAction: (allHistory.isNotEmpty &&
                                  (isFilterActive || _searchQuery.isNotEmpty))
                              ? () {
                                  AppHaptics.light();
                                  setState(() {
                                    _selectedDatePreset =
                                        HistoryReportPreset.today;
                                    _customDateRange = null;
                                    _filterStatus = 'All';
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                }
                              : null,
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
                                                        record.customerPhone.isNotEmpty
                                                            ? 'Customer: ${record.customerName} (${record.customerPhone})'
                                                            : 'Customer: ${record.customerName}',
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

  Widget _buildFilterButton(List<TableHistoryRecord> allHistory) {
    final isFilterActive =
        _selectedDatePreset != HistoryReportPreset.today ||
        _filterStatus != 'All';
    final isMobile = Responsive.isMobile(context);

    return Tooltip(
      message: 'Filter History',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFilterDialog(allHistory),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: isFilterActive
                  ? AppColors.brandAccent.withAlpha(35)
                  : AppColors.inputSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFilterActive
                    ? AppColors.brandAccentLight
                    : AppColors.cardBorderStroke,
                width: isFilterActive ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: isFilterActive
                      ? AppColors.brandAccentLight
                      : AppColors.secondaryText,
                ),
                if (isFilterActive)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.brandAccentLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterBanner() {
    final activeRange = HistoryReportDateRange.fromPreset(
      _selectedDatePreset,
      customRange: _customDateRange,
    );

    final parts = <String>[];
    if (_selectedDatePreset != HistoryReportPreset.allTime) {
      parts.add(activeRange.label);
    }
    if (_filterStatus != 'All') {
      parts.add('Status: $_filterStatus');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandAccent.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.brandAccent.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.date_range_rounded,
            size: 15,
            color: AppColors.brandAccentLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtered by: ${parts.join(" • ")}${_selectedDatePreset != HistoryReportPreset.allTime ? " (${DateFormat('dd MMM').format(activeRange.start)} - ${DateFormat('dd MMM yyyy').format(activeRange.end)})" : ""}',
              style: const TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              AppHaptics.light();
              setState(() {
                _selectedDatePreset = HistoryReportPreset.today;
                _customDateRange = null;
                _filterStatus = 'All';
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
