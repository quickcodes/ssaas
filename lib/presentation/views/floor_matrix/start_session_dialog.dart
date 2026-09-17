import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';

class StartSessionDialog extends StatefulWidget {
  final ClubTable table;
  final UserAccount activeOperator;

  const StartSessionDialog({
    super.key,
    required this.table,
    required this.activeOperator,
  });

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  final _minutesAgoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int? _selectedPresetMinutes = 0; // 0 = Now
  bool _isCustomTime = false;
  DateTime? _customDateTime;

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    _minutesAgoController.dispose();
    super.dispose();
  }

  DateTime get _effectiveStartTime {
    if (_isCustomTime && _customDateTime != null) {
      return _customDateTime!;
    }
    if (_selectedPresetMinutes != null && _selectedPresetMinutes! > 0) {
      return DateTime.now().subtract(Duration(minutes: _selectedPresetMinutes!));
    }
    return DateTime.now();
  }

  bool get _isRetroactive {
    return DateTime.now().difference(_effectiveStartTime).inSeconds >= 60;
  }

  double _calculateInitialCharge(DateTime startTime) {
    final now = DateTime.now();
    if (!now.isAfter(startTime)) return 0.0;
    final dummySession = TableSession(
      id: '',
      companyId: widget.table.companyId,
      tableId: widget.table.id,
      tableName: widget.table.name,
      customerName: '',
      startedById: widget.activeOperator.id,
      startedByName: widget.activeOperator.name,
      startTime: startTime,
      generalPrice: widget.table.generalPrice,
      customPricings: widget.table.customPricings,
    );
    return dummySession.computeTableChargeAt(now);
  }

  Future<void> _pickCustomTime() async {
    final now = DateTime.now();
    final initial = TimeOfDay.fromDateTime(
      _customDateTime ?? now.subtract(const Duration(minutes: 15)),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (pickerCtx, child) {
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
      final nowTime = DateTime.now();
      var candidate = DateTime(
        nowTime.year,
        nowTime.month,
        nowTime.day,
        picked.hour,
        picked.minute,
      );

      // Clamping or validating against future times
      if (candidate.isAfter(nowTime)) {
        if (candidate.difference(nowTime).inMinutes <= 1) {
          candidate = nowTime;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot pick a future start time.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _isCustomTime = true;
        _selectedPresetMinutes = null;
        _customDateTime = candidate;
        final mins = nowTime.difference(candidate).inMinutes;
        _minutesAgoController.text = mins > 0 ? mins.toString() : '0';
      });
    }
  }

  void _onMinutesAgoChanged(String value) {
    final mins = int.tryParse(value.trim());
    if (mins != null && mins >= 0 && mins <= 1440) {
      setState(() {
        _isCustomTime = true;
        _selectedPresetMinutes = null;
        _customDateTime = DateTime.now().subtract(Duration(minutes: mins));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentRate = widget.table.effectiveRateAt(now);

    final presets = [
      {'label': 'Now', 'minutes': 0},
      {'label': '-5 min', 'minutes': 5},
      {'label': '-10 min', 'minutes': 10},
      {'label': '-15 min', 'minutes': 15},
      {'label': '-30 min', 'minutes': 30},
      {'label': '-45 min', 'minutes': 45},
      {'label': '-1 hr', 'minutes': 60},
    ];

    final effectiveStart = _effectiveStartTime;
    final isRetroactive = _isRetroactive;
    final elapsedSec = isRetroactive ? now.difference(effectiveStart).inSeconds : 0;
    final elapsedMins = elapsedSec ~/ 60;
    final accruedCharge = isRetroactive ? _calculateInitialCharge(effectiveStart) : 0.0;

    final isMobile = Responsive.isMobile(context);

    final content = Container(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: isMobile
            ? MediaQuery.sizeOf(context).height * 0.88
            : MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 26,
          vertical: isMobile ? 16 : 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile)
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'START SNOOKER SESSION',
                          style: TextStyle(
                            color: AppColors.tableAvailable,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.table.name,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.cardBorderStroke),
                const SizedBox(height: 14),

                // Operator & Live Rate Info Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface,
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
                            Icons.badge_outlined,
                            size: 18,
                            color: AppColors.brandAccentLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Operator: ${widget.activeOperator.name}',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Current: ₹${currentRate.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Customer Name Input
                TextFormField(
                  controller: _customerController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    hintText: 'Enter customer or player name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Customer name is required to start table'
                      : null,
                ),
                const SizedBox(height: 18),

                // Start Time Selection Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface.withAlpha(140),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRetroactive
                          ? AppColors.warning.withAlpha(150)
                          : AppColors.cardBorderStroke,
                      width: isRetroactive ? 1.4 : 1.0,
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
                              Icon(
                                isRetroactive
                                    ? Icons.history
                                    : Icons.timer_outlined,
                                size: 16,
                                color: isRetroactive
                                    ? AppColors.warning
                                    : AppColors.brandAccentLight,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Session Start Time',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (isRetroactive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.warning.withAlpha(120),
                                ),
                              ),
                              child: Text(
                                'PREVIOUS TIME (${elapsedMins}m ago)',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Presets wrap
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...presets.map((p) {
                            final isSelected = !_isCustomTime &&
                                _selectedPresetMinutes == p['minutes'];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPresetMinutes = p['minutes'] as int;
                                  _isCustomTime = false;
                                  _customDateTime = null;
                                  _minutesAgoController.clear();
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (p['minutes'] == 0
                                          ? AppColors.tableAvailable.withAlpha(40)
                                          : AppColors.warning.withAlpha(40))
                                      : AppColors.cardSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? (p['minutes'] == 0
                                            ? AppColors.tableAvailable
                                            : AppColors.warning)
                                        : AppColors.cardBorderStroke,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  p['label'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (p['minutes'] == 0
                                            ? AppColors.tableAvailable
                                            : AppColors.warning)
                                        : AppColors.secondaryText,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Custom Time Chip
                          InkWell(
                            onTap: () {
                              if (!_isCustomTime) {
                                setState(() {
                                  _isCustomTime = true;
                                  _selectedPresetMinutes = null;
                                  _customDateTime ??= DateTime.now()
                                      .subtract(const Duration(minutes: 15));
                                  _minutesAgoController.text = DateTime.now()
                                      .difference(_customDateTime!)
                                      .inMinutes
                                      .toString();
                                });
                              }
                              _pickCustomTime();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isCustomTime
                                    ? AppColors.brandAccent.withAlpha(40)
                                    : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isCustomTime
                                      ? AppColors.brandAccentLight
                                      : AppColors.cardBorderStroke,
                                  width: _isCustomTime ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_calendar_outlined,
                                    size: 13,
                                    color: _isCustomTime
                                        ? AppColors.brandAccentLight
                                        : AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Custom Time...',
                                    style: TextStyle(
                                      color: _isCustomTime
                                          ? AppColors.brandAccentLight
                                          : AppColors.secondaryText,
                                      fontSize: 11,
                                      fontWeight: _isCustomTime
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // If Custom is selected: Clock picker button + Minutes Ago input
                      if (_isCustomTime) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                onPressed: _pickCustomTime,
                                icon: const Icon(Icons.access_time, size: 16),
                                label: Text(
                                  _customDateTime != null
                                      ? AppFormatters.timeOnly(_customDateTime!)
                                      : 'Pick Time',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brandAccentLight,
                                  side: const BorderSide(
                                    color: AppColors.brandAccent,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _minutesAgoController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                onChanged: _onMinutesAgoChanged,
                                decoration: const InputDecoration(
                                  labelText: 'Mins Ago',
                                  suffixText: 'm',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(color: AppColors.cardBorderStroke, height: 1),
                      const SizedBox(height: 10),

                      // Live details summary banner
                      if (isRetroactive) ...[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Start: ${AppFormatters.timeOnly(effectiveStart)}',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Initial Clock: ${AppFormatters.formatDuration(elapsedSec)}',
                                  style: const TextStyle(
                                    color: AppColors.tableAvailable,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Accrued Charge',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.currency(accruedCharge),
                                  style: const TextStyle(
                                    color: AppColors.brandAccentLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.tableAvailable,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Starting immediately at ${AppFormatters.timeOnly(now)}',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Optional Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: isRetroactive
                        ? 'e.g. Table started $elapsedMins mins ago, forgot to start'
                        : 'e.g. Table reservation or special request',
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 16),

                // Pricing Summary Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'General rate is ₹${widget.table.generalPrice.toStringAsFixed(0)}/hr with ${widget.table.customPricings.length} custom peak/weekday schedules configured.',
                          style: const TextStyle(
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
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;

                          final chosenStart = _effectiveStartTime;
                          final retroactive = _isRetroactive;
                          String effectiveNotes = _notesController.text.trim();

                          if (retroactive) {
                            final retroTag =
                                '[Started at ${AppFormatters.timeOnly(chosenStart)}]';
                            if (effectiveNotes.isEmpty) {
                              effectiveNotes = retroTag;
                            } else if (!effectiveNotes.contains(retroTag)) {
                              effectiveNotes = '$effectiveNotes $retroTag';
                            }
                          }

                          final session = TableSession(
                            id: const Uuid().v4(),
                            companyId: widget.table.companyId,
                            tableId: widget.table.id,
                            tableName: widget.table.name,
                            customerName: _customerController.text.trim(),
                            startedById: widget.activeOperator.id,
                            startedByName: widget.activeOperator.name,
                            startTime: chosenStart,
                            generalPrice: widget.table.generalPrice,
                            customPricings: widget.table.customPricings,
                            notes: effectiveNotes,
                          );

                          Navigator.of(context).pop(session);
                        },
                        icon: Icon(
                          isRetroactive ? Icons.history : Icons.play_arrow,
                        ),
                        label: Text(
                          isRetroactive
                              ? 'START AT ${AppFormatters.timeOnly(effectiveStart)}'
                              : 'START TABLE CLOCK',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRetroactive
                              ? AppColors.warning
                              : AppColors.tableAvailable,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

    if (isMobile) {
      return content;
    } else {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: content,
      );
    }
  }
}

