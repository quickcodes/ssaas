import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../domain/entities/club_reminder.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import '../../widgets/bouncing_tap.dart';
import 'reminder_details_dialog.dart';

class ClubRemindersDialog extends StatefulWidget {
  final Company activeCompany;
  final UserAccount currentUser;

  const ClubRemindersDialog({
    super.key,
    required this.activeCompany,
    required this.currentUser,
  });

  @override
  State<ClubRemindersDialog> createState() => _ClubRemindersDialogState();
}

class _ClubRemindersDialogState extends State<ClubRemindersDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
  bool _isAddingNew = true;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    AppHaptics.selection();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brandAccent,
            onPrimary: Colors.white,
            surface: AppColors.cardSurface,
            onSurface: AppColors.primaryText,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brandAccent,
            onPrimary: Colors.white,
            surface: AppColors.cardSurface,
            onSurface: AppColors.primaryText,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _setPresetTime(Duration fromNow) {
    AppHaptics.light();
    setState(() {
      _selectedDateTime = DateTime.now().add(fromNow);
    });
  }

  void _submitReminder() {
    if (!_formKey.currentState!.validate()) return;
    AppHaptics.medium();

    final reminder = ClubReminder(
      id: '',
      companyId: widget.activeCompany.id,
      description: _descController.text.trim(),
      remindAt: _selectedDateTime,
      createdAt: DateTime.now(),
      createdBy: widget.currentUser.name,
      isDismissed: false,
    );

    context.read<FloorMatrixBloc>().add(
          AddReminderEvent(
            companyId: widget.activeCompany.id,
            reminder: reminder,
          ),
        );

    _descController.clear();
    setState(() {
      _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
      _isAddingNew = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder added! It will appear on home 1 hour prior.'),
        backgroundColor: AppColors.tableAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 580,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withAlpha(35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFB300).withAlpha(120),
                      ),
                    ),
                    child: const Icon(
                      Icons.alarm_on_rounded,
                      color: Color(0xFFFFB300),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Club Reminders & Bookings',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Alerts appear on Home 1 hour before scheduled time',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorderStroke),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toggle Add New vs View List
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isAddingNew = true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isAddingNew
                                    ? AppColors.brandAccent.withAlpha(35)
                                    : AppColors.inputSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isAddingNew
                                      ? AppColors.brandAccent
                                      : AppColors.cardBorderStroke,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_alarm_rounded,
                                    size: 16,
                                    color: _isAddingNew
                                        ? AppColors.brandAccentLight
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Create Reminder',
                                    style: TextStyle(
                                      color: _isAddingNew
                                          ? AppColors.primaryText
                                          : AppColors.secondaryText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isAddingNew = false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isAddingNew
                                    ? const Color(0xFFFFB300).withAlpha(30)
                                    : AppColors.inputSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !_isAddingNew
                                      ? const Color(0xFFFFB300)
                                      : AppColors.cardBorderStroke,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.format_list_bulleted_rounded,
                                    size: 16,
                                    color: !_isAddingNew
                                        ? const Color(0xFFFFB300)
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'All Reminders',
                                    style: TextStyle(
                                      color: !_isAddingNew
                                          ? AppColors.primaryText
                                          : AppColors.secondaryText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (_isAddingNew) ...[
                      // Create Reminder Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'REMINDER DESCRIPTION (1-2 LINES)',
                              style: TextStyle(
                                color: AppColors.brandAccentLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descController,
                              maxLines: 2,
                              maxLength: 140,
                              decoration: const InputDecoration(
                                hintText:
                                    'e.g. Table 2 reserved for Rahul at 7:00 PM\nor Cue maintenance scheduled at 5 PM',
                                alignLabelWithHint: true,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter a brief reminder description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Scheduled Time Picker
                            const Text(
                              'WHEN SHOULD THIS OCCUR?',
                              style: TextStyle(
                                color: AppColors.brandAccentLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _pickDateTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.cardBorderStroke,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFFFFB300),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Scheduled Date & Time',
                                            style: TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('EEE, dd MMM yyyy • hh:mm a')
                                                .format(_selectedDateTime),
                                            style: const TextStyle(
                                              color: AppColors.primaryText,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'Change',
                                      style: TextStyle(
                                        color: AppColors.brandAccentLight,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Quick Presets
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildPresetChip('In 1 hr', const Duration(hours: 1)),
                                _buildPresetChip('In 2 hrs', const Duration(hours: 2)),
                                _buildPresetChip('In 3 hrs', const Duration(hours: 3)),
                                _buildPresetChip('Tomorrow', const Duration(days: 1)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            BouncingTap(
                              onTap: _submitReminder,
                              child: ElevatedButton.icon(
                                onPressed: _submitReminder,
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('SAVE REMINDER'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB300),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Reminders List from Bloc
                      BlocBuilder<FloorMatrixBloc, FloorMatrixState>(
                        builder: (context, matrixState) {
                          final reminders = matrixState.reminders;
                          if (reminders.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(28),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.alarm_off_outlined,
                                    size: 40,
                                    color: AppColors.secondaryText,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No reminders configured',
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: reminders.map((r) {
                              final isDueSoon = r.isDueSoon(matrixState.currentTickerTime);
                              final formattedTime = DateFormat('dd MMM • hh:mm a')
                                  .format(r.remindAt);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.inputSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDueSoon
                                        ? const Color(0xFFFFB300).withAlpha(120)
                                        : AppColors.cardBorderStroke,
                                    width: isDueSoon ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    onTap: () {
                                      AppHaptics.light();
                                      ReminderDetailsDialog.show(
                                        context,
                                        reminder: r,
                                        activeCompany: widget.activeCompany,
                                        currentUser: widget.currentUser,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            isDueSoon
                                                ? Icons.alarm_on_rounded
                                                : Icons.schedule_rounded,
                                            size: 20,
                                            color: isDueSoon
                                                ? const Color(0xFFFFB300)
                                                : AppColors.secondaryText,
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
                                                      formattedTime,
                                                      style: TextStyle(
                                                        color: isDueSoon
                                                            ? const Color(0xFFFFB300)
                                                            : AppColors.primaryText,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (isDueSoon)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1.5,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFFB300)
                                                              .withAlpha(35),
                                                          borderRadius:
                                                              BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'ACTIVE ON HOME',
                                                          style: TextStyle(
                                                            color: Color(0xFFFFB300),
                                                            fontSize: 8.5,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                    if (r.isDismissed)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1.5,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.tableOccupied
                                                              .withAlpha(25),
                                                          borderRadius:
                                                              BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'DISMISSED',
                                                          style: TextStyle(
                                                            color: AppColors.tableOccupied,
                                                            fontSize: 8.5,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  r.description,
                                                  style: const TextStyle(
                                                    color: AppColors.primaryText,
                                                    fontSize: 13,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.secondaryText,
                                            ),
                                            tooltip: 'Delete Reminder',
                                            onPressed: () {
                                              AppHaptics.light();
                                              context
                                                  .read<FloorMatrixBloc>()
                                                  .add(DeleteReminderEvent(
                                                    companyId:
                                                        widget.activeCompany.id,
                                                    reminderId: r.id,
                                                  ));
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, Duration offset) {
    return InkWell(
      onTap: () => _setPresetTime(offset),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.inputSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorderStroke),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
