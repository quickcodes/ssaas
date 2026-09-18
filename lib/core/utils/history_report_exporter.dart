import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/constants.dart';
import '../../domain/entities/table_history_record.dart';

enum HistoryReportPreset {
  thisMonth('This Month (Till Now)'),
  last30Days('Last 30 Days'),
  thisWeek('This Week'),
  last7Days('Last 7 Days'),
  today('Today (Daily)'),
  thisYear('This Year (Yearly)'),
  allTime('All Time'),
  custom('Custom Range...');

  final String label;
  const HistoryReportPreset(this.label);
}

class HistoryReportDateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  const HistoryReportDateRange({
    required this.start,
    required this.end,
    required this.label,
  });

  static HistoryReportDateRange fromPreset(
    HistoryReportPreset preset, {
    DateTimeRange? customRange,
  }) {
    final now = DateTime.now();

    switch (preset) {
      case HistoryReportPreset.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        return HistoryReportDateRange(
          start: start,
          end: now,
          label: 'This Month (Till Now)',
        );

      case HistoryReportPreset.last30Days:
        final start = now.subtract(const Duration(days: 30));
        return HistoryReportDateRange(
          start: start,
          end: now,
          label: 'Last 30 Days',
        );

      case HistoryReportPreset.thisWeek:
        final dayOffset = now.weekday - 1; // Monday = 0
        final start = DateTime(now.year, now.month, now.day - dayOffset, 0, 0, 0);
        return HistoryReportDateRange(
          start: start,
          end: now,
          label: 'This Week',
        );

      case HistoryReportPreset.last7Days:
        final start = now.subtract(const Duration(days: 7));
        return HistoryReportDateRange(
          start: start,
          end: now,
          label: 'Last 7 Days',
        );

      case HistoryReportPreset.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        return HistoryReportDateRange(
          start: start,
          end: now,
          label: 'Today (Daily)',
        );

      case HistoryReportPreset.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0);
        return HistoryReportDateRange(
          start: start,
          end: now,
          label: 'This Year (Yearly)',
        );

      case HistoryReportPreset.allTime:
        final start = DateTime(2020, 1, 1, 0, 0, 0);
        return HistoryReportDateRange(
          start: start,
          end: now,
          label: 'All Time',
        );

      case HistoryReportPreset.custom:
        if (customRange != null) {
          final start = DateTime(
            customRange.start.year,
            customRange.start.month,
            customRange.start.day,
            0,
            0,
            0,
          );
          final end = DateTime(
            customRange.end.year,
            customRange.end.month,
            customRange.end.day,
            23,
            59,
            59,
          );
          return HistoryReportDateRange(
            start: start,
            end: end,
            label:
                '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
          );
        }
        return HistoryReportDateRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
          label: 'Custom Range',
        );
    }
  }
}

class HistoryReportExporter {
  HistoryReportExporter._();

  /// Converts 2D data rows into standard RFC-4180 CSV spreadsheet format.
  static String toCsv(List<List<dynamic>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      final line = row.map((cell) {
        if (cell == null) return '';
        final str = cell.toString();
        if (str.contains(',') ||
            str.contains('"') ||
            str.contains('\n') ||
            str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  /// Filters list of history records within the given date bounds.
  static List<TableHistoryRecord> filterByDateRange(
    List<TableHistoryRecord> records,
    DateTime start,
    DateTime end,
  ) {
    return records.where((r) {
      final t = r.closedAt;
      return !t.isBefore(start) && !t.isAfter(end);
    }).toList()
      ..sort((a, b) => b.closedAt.compareTo(a.closedAt)); // latest first
  }

  /// Generates the complete, detailed spreadsheet content for the filtered records.
  static String generateDetailedCsv({
    required String companyName,
    required HistoryReportDateRange dateRange,
    required List<TableHistoryRecord> records,
  }) {
    final rows = <List<dynamic>>[];

    final totalTableAmt =
        records.fold<double>(0.0, (sum, r) => sum + r.tableAmount);
    final totalItemsAmt =
        records.fold<double>(0.0, (sum, r) => sum + r.itemsAmount);
    final totalGrandAmt =
        records.fold<double>(0.0, (sum, r) => sum + r.totalAmount);
    final totalPaidAmt =
        records.fold<double>(0.0, (sum, r) => sum + r.paidAmount);
    final totalDueAmt =
        records.fold<double>(0.0, (sum, r) => sum + r.dueAmount);
    final totalMinutes =
        records.fold<int>(0, (sum, r) => sum + r.durationMinutes);

    // 1. Spreadsheet Header & Executive Summary
    rows.add(['SNOOKER - MATCH REPORT']);
    rows.add(['Club / Company', companyName]);
    rows.add(['Report Period', dateRange.label]);
    rows.add([
      'Date Range',
      '${DateFormat('dd MMM yyyy, hh:mm a').format(dateRange.start)} to ${DateFormat('dd MMM yyyy, hh:mm a').format(dateRange.end)}'
    ]);
    rows.add(['Generated On', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())]);
    rows.add(['Total Matches Recorded', records.length]);
    rows.add([
      'Total Playing Duration',
      '$totalMinutes mins (${(totalMinutes / 60.0).toStringAsFixed(1)} hours)'
    ]);
    rows.add(['Total Table Revenue (₹)', totalTableAmt.toStringAsFixed(2)]);
    rows.add(['Total Items/Canteen Revenue (₹)', totalItemsAmt.toStringAsFixed(2)]);
    rows.add(['Grand Total Revenue (₹)', totalGrandAmt.toStringAsFixed(2)]);
    rows.add(['Total Paid Received (₹)', totalPaidAmt.toStringAsFixed(2)]);
    rows.add(['Total Due Pending (₹)', totalDueAmt.toStringAsFixed(2)]);
    rows.add([]); // empty row separator

    // 2. Data Column Headers
    rows.add([
      '#',
      'Match Date',
      'Table Name',
      'Closing Person / Customer',
      'Started By Staff',
      'Closed By Staff',
      'Start Time',
      'End Time',
      'Duration (Mins)',
      'Duration (Hours)',
      'Table Fee (₹)',
      'Items Fee (₹)',
      'Grand Total (₹)',
      'Paid Amount (₹)',
      'Due Amount (₹)',
      'Payment Status',
      'Payment Method',
      'Canteen & Stock Items Ordered',
      'Payment Transactions Audit Log',
    ]);

    // 3. Data Rows
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    for (int i = 0; i < records.length; i++) {
      final r = records[i];

      final itemsStr = r.items.isEmpty
          ? 'None'
          : r.items
              .map((it) =>
                  '${it.name} (x${it.quantity} @ ₹${it.price.toStringAsFixed(0)}) = ₹${it.totalAmount.toStringAsFixed(0)}')
              .join('; ');

      final txStr = r.transactions.isEmpty
          ? 'None'
          : r.transactions
              .map((tx) =>
                  '₹${tx.amount.toStringAsFixed(2)} [${tx.paymentMethod}] received by ${tx.receivedBy} on ${dateFormat.format(tx.receivedAt)}')
              .join('; ');

      rows.add([
        i + 1,
        DateFormat('yyyy-MM-dd').format(r.closedAt),
        r.tableName,
        r.customerName,
        r.startedByName,
        r.closedByName,
        dateFormat.format(r.startedAt),
        dateFormat.format(r.closedAt),
        r.durationMinutes,
        (r.durationMinutes / 60.0).toStringAsFixed(2),
        r.tableAmount.toStringAsFixed(2),
        r.itemsAmount.toStringAsFixed(2),
        r.totalAmount.toStringAsFixed(2),
        r.paidAmount.toStringAsFixed(2),
        r.dueAmount.toStringAsFixed(2),
        r.isReceived ? 'Received' : (r.isPartiallyPaid ? 'Partially Paid' : 'Due'),
        r.paymentMethod ??
            (r.transactions.isNotEmpty
                ? r.transactions.map((t) => t.paymentMethod).toSet().join('/')
                : 'N/A'),
        itemsStr,
        txStr,
      ]);
    }

    // 4. Totals Summary Row
    rows.add([]);
    rows.add([
      'TOTALS',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      totalMinutes,
      (totalMinutes / 60.0).toStringAsFixed(2),
      totalTableAmt.toStringAsFixed(2),
      totalItemsAmt.toStringAsFixed(2),
      totalGrandAmt.toStringAsFixed(2),
      totalPaidAmt.toStringAsFixed(2),
      totalDueAmt.toStringAsFixed(2),
      '',
      '',
      '',
      '',
    ]);

    return toCsv(rows);
  }

  /// Exports the CSV file to the system temp directory and opens the system Share sheet.
  static Future<void> shareReport({
    required BuildContext context,
    required String companyName,
    required HistoryReportDateRange dateRange,
    required List<TableHistoryRecord> records,
    Rect? sharePositionOrigin,
  }) async {
    final csvContent = generateDetailedCsv(
      companyName: companyName,
      dateRange: dateRange,
      records: records,
    );

    final tempDir = await getTemporaryDirectory();
    final sanitizedRange =
        dateRange.label.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${companyName}_Match_Report_${sanitizedRange}_$timestamp.csv';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(csvContent);

    final xFile = XFile(
      file.path,
      name: fileName,
      mimeType: 'text/csv',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: '$companyName - Match History Report (${dateRange.label})',
        text:
            'Please find attached the ${Constants.appName} Table Match History Report for $companyName (${dateRange.label}). Contains ${records.length} matches.',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
