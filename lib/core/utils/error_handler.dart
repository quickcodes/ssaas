import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized error handling and user-friendly error formatting
class AppErrorHandler {
  /// Transforms technical exceptions, network failures, and Firebase codes
  /// into clean, intelligible human-readable error messages.
  static String format(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    final raw = error.toString().trim();
    final lower = raw.toLowerCase();

    // Network / Socket errors
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network_error') ||
        lower.contains('network-request-failed') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('clientexception') ||
        lower.contains('no internet')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout errors
    if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('deadline-exceeded')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Permission / Authorization errors
    if (lower.contains('permission-denied') ||
        lower.contains('permission denied') ||
        lower.contains('unauthorized')) {
      return 'Access denied. You do not have permission to perform this action.';
    }

    // Firebase Unavailable / Quota errors
    if (lower.contains('unavailable') ||
        lower.contains('resource-exhausted') ||
        lower.contains('service-unavailable')) {
      return 'Server is temporarily unavailable. Please try again in a few moments.';
    }

    // Not found
    if (lower.contains('not-found') || lower.contains('not found')) {
      return 'Requested resource was not found. Please refresh and try again.';
    }

    // Cancellation
    if (lower.contains('cancelled') || lower.contains('canceled')) {
      return 'Operation was cancelled.';
    }

    // Strip out Dart "Exception: " prefixes
    String cleaned = raw;
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length);
    }
    if (cleaned.startsWith('Error: ')) {
      cleaned = cleaned.substring('Error: '.length);
    }

    // Strip Firebase bracketed prefixes e.g. [cloud_firestore/not-found]
    final bracketRegex = RegExp(r'^\[.*?\]\s*');
    cleaned = cleaned.replaceFirst(bracketRegex, '');

    return cleaned.isNotEmpty
        ? cleaned
        : 'An unexpected error occurred. Please try again.';
  }

  /// Displays a safe, non-overlapping floating error SnackBar
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    final message = format(error);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.tableOccupied,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
        action: action,
      ),
    );
  }
}
