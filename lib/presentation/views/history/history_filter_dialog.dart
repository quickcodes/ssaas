import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/history_report_exporter.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../domain/entities/table_history_record.dart';

/// Holds the user-selected filter state for tables history.
class HistoryFilterOption {
  final HistoryReportPreset preset;
  final DateTimeRange? customRange;
  final String status; // 'All', 'Received', 'Due'

  const HistoryFilterOption({
    required this.preset,
    this.customRange,
    this.status = 'All',
  });

  bool get isFilterActive =>
      preset != HistoryReportPreset.allTime || status != 'All';
}

/// Modal dialog for filtering match history by date presets (daily, weekly, monthly, etc.)
/// and optionally payment status.
class HistoryFilterDialog extends StatefulWidget {
  final HistoryReportPreset initialPreset;
  final DateTimeRange? initialCustomRange;
  final String initialStatus;
  final List<TableHistoryRecord> allRecords;

  const HistoryFilterDialog({
    super.key,
    required this.initialPreset,
    this.initialCustomRange,
    required this.initialStatus,
    required this.allRecords,
  });

  @override
  State<HistoryFilterDialog> createState() => _HistoryFilterDialogState();
}

class _HistoryFilterDialogState extends State<HistoryFilterDialog> {
  late HistoryReportPreset _selectedPreset;
  DateTimeRange? _customDateRange;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _customDateRange = widget.initialCustomRange;
    _selectedStatus = widget.initialStatus;
  }

  HistoryReportDateRange get _activeDateRange {
    return HistoryReportDateRange.fromPreset(
      _selectedPreset,
      customRange: _customDateRange,
    );
  }

  List<TableHistoryRecord> get _filteredRecords {
    var list = widget.allRecords;
    if (_selectedPreset != HistoryReportPreset.allTime) {
      final range = _activeDateRange;
      list = HistoryReportExporter.filterByDateRange(
        list,
        range.start,
        range.end,
      );
    }
    if (_selectedStatus != 'All') {
      list = list
          .where(
            (r) => _selectedStatus == 'Received' ? r.isReceived : r.isDue,
          )
          .toList();
    }
    return list;
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

  @override
  Widget build(BuildContext context) {
    final range = _activeDateRange;
    final matchingRecords = _filteredRecords;
    final matchesCount = matchingRecords.length;

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
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
                            Icons.tune_rounded,
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
                                'FILTER MATCH HISTORY',
                                style: TextStyle(
                                  color: AppColors.brandAccentLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select Time Period',
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

              // Date Period Section
              const Text(
                'DATE PERIOD PRESETS',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // Presets Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HistoryReportPreset.values.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return InkWell(
                    onTap: () {
                      AppHaptics.selection();
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
              const SizedBox(height: 16),

              // Active Date Range Preview Banner
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
                      _selectedPreset == HistoryReportPreset.allTime
                          ? 'All recorded matches'
                          : '${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Matching Records Count Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: matchesCount > 0
                        ? AppColors.brandAccent.withAlpha(80)
                        : AppColors.cardBorderStroke,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: AppColors.brandAccentLight,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Matching Records',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                        color: matchesCount > 0
                            ? AppColors.tableAvailable.withAlpha(25)
                            : AppColors.cardBorderStroke.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$matchesCount ${matchesCount == 1 ? "match" : "matches"}',
                        style: TextStyle(
                          color: matchesCount > 0
                              ? AppColors.tableAvailable
                              : AppColors.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Status Filter Section
              const Text(
                'PAYMENT STATUS',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip('All', 'All Matches'),
                  _buildStatusChip(
                    'Received',
                    'Received Only',
                    color: AppColors.tableAvailable,
                  ),
                  _buildStatusChip(
                    'Due',
                    'Pending Due Only',
                    color: AppColors.tableOccupied,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Action Buttons: Reset & Apply
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        AppHaptics.light();
                        Navigator.of(context).pop(
                          const HistoryFilterOption(
                            preset: HistoryReportPreset.allTime,
                            customRange: null,
                            status: 'All',
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AppHaptics.medium();
                        Navigator.of(context).pop(
                          HistoryFilterOption(
                            preset: _selectedPreset,
                            customRange: _customDateRange,
                            status: _selectedStatus,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'APPLY FILTER',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        foregroundColor: Colors.white,
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

  Widget _buildStatusChip(String status, String label, {Color? color}) {
    final isSelected = _selectedStatus == status;
    final chipColor = color ?? AppColors.brandAccentLight;
    return InkWell(
      onTap: () {
        AppHaptics.selection();
        setState(() => _selectedStatus = status);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withAlpha(35)
              : AppColors.inputSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.cardBorderStroke,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
