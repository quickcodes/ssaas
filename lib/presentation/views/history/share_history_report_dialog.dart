import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/history_report_exporter.dart';
import '../../../domain/entities/table_history_record.dart';

class ShareHistoryReportDialog extends StatefulWidget {
  final String companyName;
  final List<TableHistoryRecord> allRecords;
  final HistoryReportPreset? initialPreset;
  final DateTimeRange? initialCustomDateRange;

  const ShareHistoryReportDialog({
    super.key,
    required this.companyName,
    required this.allRecords,
    this.initialPreset,
    this.initialCustomDateRange,
  });

  @override
  State<ShareHistoryReportDialog> createState() =>
      _ShareHistoryReportDialogState();
}

class _ShareHistoryReportDialogState extends State<ShareHistoryReportDialog> {
  late HistoryReportPreset _selectedPreset;
  DateTimeRange? _customDateRange;
  bool _isSharing = false;
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset ?? HistoryReportPreset.thisMonth;
    _customDateRange = widget.initialCustomDateRange;
  }

  HistoryReportDateRange get _activeDateRange {
    return HistoryReportDateRange.fromPreset(
      _selectedPreset,
      customRange: _customDateRange,
    );
  }

  List<TableHistoryRecord> get _filteredRecords {
    final range = _activeDateRange;
    return HistoryReportExporter.filterByDateRange(
      widget.allRecords,
      range.start,
      range.end,
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandAccent,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
              onSurface: AppColors.primaryText,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPreset = HistoryReportPreset.custom;
      });
    }
  }

  Future<void> _handleShare() async {
    final records = _filteredRecords;
    if (records.isEmpty) return;

    setState(() => _isSharing = true);

    try {
      // Find button RenderBox for anchor origin on iPad/macOS
      Rect? origin;
      final renderBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        origin = position & renderBox.size;
      }

      await HistoryReportExporter.shareReport(
        context: context,
        companyName: widget.companyName,
        dateRange: _activeDateRange,
        records: records,
        sharePositionOrigin: origin,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _activeDateRange;
    final records = _filteredRecords;

    final totalTableAmt = records.fold<double>(
      0.0,
      (sum, r) => sum + r.tableAmount,
    );
    final totalItemsAmt = records.fold<double>(
      0.0,
      (sum, r) => sum + r.itemsAmount,
    );
    final totalGrandAmt = records.fold<double>(
      0.0,
      (sum, r) => sum + r.totalAmount,
    );
    final totalPaidAmt = records.fold<double>(
      0.0,
      (sum, r) => sum + r.paidAmount,
    );
    final totalDueAmt = records.fold<double>(
      0.0,
      (sum, r) => sum + r.dueAmount,
    );
    final totalMinutes = records.fold<int>(
      0,
      (sum, r) => sum + r.durationMinutes,
    );

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandAccent.withAlpha(35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.table_chart_rounded,
                            color: AppColors.brandAccentLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SHARE SPREADSHEET REPORT',
                                style: TextStyle(
                                  color: AppColors.brandAccentLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Match History Export',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.cardBorderStroke),
              const SizedBox(height: 16),

              // Preset Selection Section
              const Text(
                'SELECT REPORT PERIOD',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // Filter Presets Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HistoryReportPreset.values.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return InkWell(
                    onTap: () {
                      if (preset == HistoryReportPreset.custom) {
                        _pickCustomRange();
                      } else {
                        setState(() => _selectedPreset = preset);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandAccent.withAlpha(40)
                            : AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandAccentLight
                              : AppColors.cardBorderStroke,
                          width: isSelected ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (preset == HistoryReportPreset.custom) ...[
                            Icon(
                              Icons.date_range,
                              size: 14,
                              color: isSelected
                                  ? AppColors.brandAccentLight
                                  : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            preset.label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Selected Period Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface.withAlpha(150),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorderStroke),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: AppColors.brandAccentLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          range.label,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Report Statistics Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: records.isNotEmpty
                        ? AppColors.brandAccent.withAlpha(80)
                        : AppColors.cardBorderStroke,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              size: 16,
                              color: AppColors.brandAccentLight,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Report Summary Preview',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: records.isNotEmpty
                                ? AppColors.tableAvailable.withAlpha(30)
                                : AppColors.cardBorderStroke.withAlpha(50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${records.length} Matches Found',
                            style: TextStyle(
                              color: records.isNotEmpty
                                  ? AppColors.tableAvailable
                                  : AppColors.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.cardBorderStroke, height: 1),
                    const SizedBox(height: 12),

                    // Metrics Grid (Responsive Wrap)
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _buildStatPill(
                          'Total Revenue',
                          AppFormatters.currency(totalGrandAmt),
                          AppColors.primaryText,
                        ),
                        _buildStatPill(
                          'Paid / Received',
                          AppFormatters.currency(totalPaidAmt),
                          AppColors.tableAvailable,
                        ),
                        _buildStatPill(
                          'Due / Pending',
                          AppFormatters.currency(totalDueAmt),
                          totalDueAmt > 0
                              ? AppColors.tableOccupied
                              : AppColors.secondaryText,
                        ),
                        _buildStatPill(
                          'Table Charges',
                          AppFormatters.currency(totalTableAmt),
                          AppColors.secondaryText,
                        ),
                        _buildStatPill(
                          'Canteen Charges',
                          AppFormatters.currency(totalItemsAmt),
                          AppColors.secondaryText,
                        ),
                        _buildStatPill(
                          'Playing Hours',
                          '${(totalMinutes / 60.0).toStringAsFixed(1)} hrs',
                          AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // File & Format Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Generates an Excel & Google Sheets-ready .CSV spreadsheet with audit logs, customer names, ordered items, and payment transactions.',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      key: _shareButtonKey,
                      onPressed: (_isSharing || records.isEmpty)
                          ? null
                          : _handleShare,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share),
                      label: Text(
                        _isSharing ? 'PREPARING...' : 'SHARE',
                        // : 'SHARE (${records.length}) Records',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.brandAccent
                            .withAlpha(80),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color valueColor) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
