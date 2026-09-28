import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../domain/entities/club_reminder.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';

class ReminderDetailsDialog extends StatelessWidget {
  final ClubReminder reminder;
  final Company activeCompany;
  final UserAccount currentUser;

  const ReminderDetailsDialog({
    super.key,
    required this.reminder,
    required this.activeCompany,
    required this.currentUser,
  });

  static Future<void> show(
    BuildContext context, {
    required ClubReminder reminder,
    required Company activeCompany,
    required UserAccount currentUser,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReminderDetailsDialog(
        reminder: reminder,
        activeCompany: activeCompany,
        currentUser: currentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = reminder.remindAt.difference(now);

    final String countdownText;
    final Color badgeColor;
    if (diff.isNegative) {
      final pastMinutes = diff.inMinutes.abs();
      if (pastMinutes < 60) {
        countdownText = 'Started $pastMinutes mins ago';
      } else {
        countdownText = 'Started ${diff.inHours.abs()}h ago';
      }
      badgeColor = const Color(0xFFFFB300);
    } else {
      final remainingMinutes = diff.inMinutes;
      if (remainingMinutes == 0) {
        countdownText = 'Starting now!';
        badgeColor = AppColors.brandAccent;
      } else if (remainingMinutes < 60) {
        countdownText = 'Starting in $remainingMinutes mins';
        badgeColor = const Color(0xFFFFB300);
      } else {
        final hours = diff.inHours;
        final mins = remainingMinutes % 60;
        countdownText = 'In ${hours}h ${mins}m';
        badgeColor = AppColors.brandAccentLight;
      }
    }

    final dateFormatted = DateFormat('EEEE, MMM d, yyyy').format(reminder.remindAt);
    final timeFormatted = DateFormat('hh:mm a').format(reminder.remindAt);
    final createdFormatted = DateFormat('MMM d, yyyy • hh:mm a').format(reminder.createdAt);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 520,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFB300).withAlpha(120),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(140),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFFFFB300).withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withAlpha(18),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cardBorderStroke.withAlpha(120),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withAlpha(35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFB300).withAlpha(150),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFFFB300),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REMINDER & BOOKING DETAILS',
                          style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: badgeColor.withAlpha(100),
                                ),
                              ),
                              child: Text(
                                countdownText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (reminder.isDismissed) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tableOccupied.withAlpha(25),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'DISMISSED',
                                  style: TextStyle(
                                    color: AppColors.tableOccupied,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    tooltip: 'Close',
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description Card
                    const Text(
                      'DESCRIPTION / NOTE',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.cardBorderStroke,
                        ),
                      ),
                      child: SelectableText(
                        reminder.description,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Schedule & Details Grid Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface.withAlpha(120),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.cardBorderStroke,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: dateFormatted,
                          ),
                          const Divider(height: 18, color: AppColors.cardBorderStroke),
                          _buildDetailRow(
                            icon: Icons.access_time_rounded,
                            label: 'Scheduled Time',
                            value: timeFormatted,
                            highlightValue: true,
                          ),
                          if (reminder.createdBy.isNotEmpty) ...[
                            const Divider(height: 18, color: AppColors.cardBorderStroke),
                            _buildDetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Created By',
                              value: reminder.createdBy,
                            ),
                          ],
                          const Divider(height: 18, color: AppColors.cardBorderStroke),
                          _buildDetailRow(
                            icon: Icons.history_rounded,
                            label: 'Created On',
                            value: createdFormatted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dialog Footer / Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                border: Border(
                  top: BorderSide(
                    color: AppColors.cardBorderStroke.withAlpha(100),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (currentUser.isAdmin) ...[
                    // Delete Button
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: AppColors.tableOccupied,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          color: AppColors.tableOccupied,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!reminder.isDismissed) ...[
                    // Dismiss / Mark Done Button
                    OutlinedButton.icon(
                      onPressed: () {
                        AppHaptics.medium();
                        context.read<FloorMatrixBloc>().add(
                              DismissReminderEvent(
                                companyId: activeCompany.id,
                                reminderId: reminder.id,
                              ),
                            );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.done_all_rounded,
                        size: 16,
                        color: AppColors.tableAvailable,
                      ),
                      label: const Text(
                        'Mark as Done',
                        style: TextStyle(
                          color: AppColors.tableAvailable,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.tableAvailable,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  // Close Button
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlightValue = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: highlightValue
                  ? const Color(0xFFFFB300)
                  : AppColors.primaryText,
              fontSize: 13,
              fontWeight: highlightValue ? FontWeight.w700 : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    AppHaptics.medium();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.tableOccupied),
            SizedBox(width: 8),
            Text('Delete Reminder?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently remove this reminder?',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tableOccupied,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // pop confirm
              context.read<FloorMatrixBloc>().add(
                    DeleteReminderEvent(
                      companyId: activeCompany.id,
                      reminderId: reminder.id,
                    ),
                  );
              Navigator.of(context).pop(); // pop details dialog
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
