import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/payment_transaction.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';

class CheckoutSessionDialog extends StatefulWidget {
  final TableSession session;
  final DateTime now;
  final UserAccount activeOperator;
  final double dueBufferAmount;

  const CheckoutSessionDialog({
    super.key,
    required this.session,
    required this.now,
    required this.activeOperator,
    this.dueBufferAmount = Constants.dueBufferAmount,
  });

  @override
  State<CheckoutSessionDialog> createState() => _CheckoutSessionDialogState();
}

class _CheckoutSessionDialogState extends State<CheckoutSessionDialog> {
  double get _dueBuffer => widget.dueBufferAmount;
  final _closingPersonCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _closingNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _partialAmountCtrl = TextEditingController();
  final _splitCashAmountCtrl = TextEditingController();
  final _splitOnlineAmountCtrl = TextEditingController();
  final _minutesAgoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _settlementMode = 'Full'; // 'Full', 'Split', 'Partial', 'Due'
  String _paymentMethod = 'Cash'; // 'Cash', 'UPI', 'Card'
  String _splitOnlineMethod = 'UPI'; // 'UPI', 'Card'

  int? _selectedPresetMinutes = 0; // 0 = Now
  bool _isCustomTime = false;
  DateTime? _customDateTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _closingPersonCtrl.text = widget.session.customerName;
    _customerPhoneCtrl.text = widget.session.customerPhone;
    _closingNameCtrl.text = widget.activeOperator.name;
  }

  @override
  void dispose() {
    _closingPersonCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _closingNameCtrl.dispose();
    _notesCtrl.dispose();
    _partialAmountCtrl.dispose();
    _splitCashAmountCtrl.dispose();
    _splitOnlineAmountCtrl.dispose();
    _minutesAgoController.dispose();
    super.dispose();
  }

  DateTime get _effectiveCloseTime {
    final now = DateTime.now();
    if (_isCustomTime && _customDateTime != null) {
      return _customDateTime!;
    }
    if (_selectedPresetMinutes != null && _selectedPresetMinutes! > 0) {
      return now.subtract(Duration(minutes: _selectedPresetMinutes!));
    }
    return now;
  }

  bool get _isRetroactive {
    return DateTime.now().difference(_effectiveCloseTime).inSeconds >= 60;
  }

  Future<void> _pickCustomTime() async {
    final now = DateTime.now();
    final initial = TimeOfDay.fromDateTime(
      _customDateTime ?? now.subtract(const Duration(minutes: 5)),
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

      // Future time validation
      if (candidate.isAfter(nowTime)) {
        if (candidate.difference(nowTime).inMinutes <= 1) {
          candidate = nowTime;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot pick a future close time.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      // Starting table time validation
      if (!candidate.isAfter(widget.session.startTime)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Close time cannot be earlier than table start time (${AppFormatters.timeOnly(widget.session.startTime)}).',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
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
    if (mins == null) return;
    final now = DateTime.now();
    final elapsedSinceStart = now
        .difference(widget.session.startTime)
        .inMinutes;
    if (mins >= elapsedSinceStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table has been running for ${elapsedSinceStart}m. Minutes ago must be less than $elapsedSinceStart.',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (mins >= 0 && mins <= 1440) {
      setState(() {
        _isCustomTime = true;
        _selectedPresetMinutes = null;
        _customDateTime = now.subtract(Duration(minutes: mins));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveClose = _effectiveCloseTime;
    final playedSeconds = widget.session.playedSecondsAt(effectiveClose);
    final durationMinutes = (playedSeconds / 60).ceil();
    final tableCharge = widget.session.computeTableChargeAt(effectiveClose);
    final itemsCharge = widget.session.itemsAmount;
    final grandTotal = tableCharge + itemsCharge;

    final now = DateTime.now();
    final totalRunningMins = now.difference(widget.session.startTime).inMinutes;
    final isRetroactive = _isRetroactive;
    final elapsedRetroMins = isRetroactive
        ? now.difference(effectiveClose).inMinutes
        : 0;

    final presets = [
      {'label': 'Now', 'minutes': 0},
      {'label': '-5 min', 'minutes': 5},
      {'label': '-10 min', 'minutes': 10},
      {'label': '-15 min', 'minutes': 15},
      {'label': '-30 min', 'minutes': 30},
      {'label': '-45 min', 'minutes': 45},
      {'label': '-1 hr', 'minutes': 60},
    ];

    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CLOSE TABLE & SETTLE BILL',
              style: TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              widget.session.tableName,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandAccent.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.brandAccentLight,
                ),
                const SizedBox(width: 4),
                Text(
                  AppFormatters.formatDuration(playedSeconds),
                  style: const TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorderStroke),
                ),
                padding: EdgeInsets.all(isMobile ? 18 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                // Match details summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.session.customerName,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Duration Played',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatDuration(playedSeconds),
                            style: const TextStyle(
                              color: AppColors.tableAvailable,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.session.isPaused && widget.session.lastPauseTime != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withAlpha(120)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pause_circle_filled,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TABLE CLOCK IS CURRENTLY PAUSED',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Paused at ${AppFormatters.timeOnly(widget.session.lastPauseTime!)}. Active play time is frozen at ${AppFormatters.formatDuration(playedSeconds)}.',
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

                // Table Close Time Selection Card
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
                                    : Icons.timer_off_outlined,
                                size: 16,
                                color: isRetroactive
                                    ? AppColors.warning
                                    : AppColors.brandAccentLight,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Table Close Time',
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
                                'CLOSED AT PREVIOUS TIME (${elapsedRetroMins}m ago)',
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
                            final pMins = p['minutes'] as int;
                            final isAvailable =
                                pMins == 0 || pMins < totalRunningMins;
                            final isSelected =
                                !_isCustomTime &&
                                _selectedPresetMinutes == pMins;

                            return Opacity(
                              opacity: isAvailable ? 1.0 : 0.38,
                              child: InkWell(
                                onTap: () {
                                  if (!isAvailable) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Table only started ${totalRunningMins}m ago (${AppFormatters.timeOnly(widget.session.startTime)}). Cannot close before start time.',
                                        ),
                                        backgroundColor: AppColors.warning,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _selectedPresetMinutes = pMins;
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
                                        ? (pMins == 0
                                              ? AppColors.tableAvailable
                                                    .withAlpha(40)
                                              : AppColors.warning.withAlpha(40))
                                        : AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? (pMins == 0
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
                                          ? (pMins == 0
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
                                  _customDateTime ??= DateTime.now().subtract(
                                    const Duration(minutes: 5),
                                  );
                                  if (!_customDateTime!.isAfter(
                                    widget.session.startTime,
                                  )) {
                                    _customDateTime = widget.session.startTime
                                        .add(const Duration(minutes: 1));
                                  }
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
                                  FilteringTextInputFormatter.digitsOnly,
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

                      // Retroactive info note
                      if (isRetroactive) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 15,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Table will be closed at ${AppFormatters.timeOnly(effectiveClose)} ($elapsedRetroMins mins ago). Table rental and total bill have been recalculated for this duration.',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Price Breakdown Itemization
                const Text(
                  'PRICE BREAKDOWN',
                  style: TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // Table time charge
                _buildBreakdownRow(
                  title: 'Table Rental Fee',
                  subtitle:
                      'Dynamic rate • $durationMinutes mins (${(playedSeconds / 3600.0).toStringAsFixed(1)} hrs)',
                  amount: '₹${tableCharge.toStringAsFixed(2)}',
                  isHighlight: false,
                ),

                // Snacks / Canteen & Custom items
                if (widget.session.items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      children: widget.session.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.quantity}x ${item.name}${item.isCustom ? " (Custom)" : ""}',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '₹${item.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                // Total Amount Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.brandAccent.withAlpha(120),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bill Amount',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '₹${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.brandAccentLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Closing Person Name Field (On which person the table got closed)
                TextFormField(
                  controller: _closingPersonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Closing Person Name *',
                    hintText:
                        'Enter player/customer name on whom the table is closing',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Closing person name is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Customer Phone Field (Optional)
                TextFormField(
                  controller: _customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) =>
                      null,
                  decoration: const InputDecoration(
                    labelText: 'Customer Number (Optional)',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) {
                    if (val != null &&
                        val.trim().isNotEmpty &&
                        val.trim().length != 10) {
                      return 'Customer number must be 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Closing Staff Name Field (Staff closing this table)
                TextFormField(
                  controller: _closingNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Closed By (Staff / Marker) *',
                    hintText: 'Enter staff/marker name closing this match',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Staff name is required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Payment Status: Full Received vs Partial vs Full Due
                const Text(
                  'PAYMENT SETTLEMENT',
                  style: TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    _buildSettlementOption(
                      mode: 'Full',
                      icon: Icons.check_circle_outline,
                      title: 'Full Paid',
                      subtitle: '₹${grandTotal.toStringAsFixed(0)}',
                      activeColor: AppColors.tableAvailable,
                    ),
                    const SizedBox(width: 8),
                    _buildSettlementOption(
                      mode: 'Split',
                      icon: Icons.call_split,
                      title: 'Split Pay',
                      subtitle: 'Cash + UPI',
                      activeColor: AppColors.brandAccentLight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSettlementOption(
                      mode: 'Partial',
                      icon: Icons.timelapse,
                      title: 'Partial Paid',
                      subtitle: 'Part payment',
                      activeColor: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildSettlementOption(
                      mode: 'Due',
                      icon: Icons.pending_actions,
                      title: 'Full Due',
                      subtitle: '₹0 now',
                      activeColor: AppColors.tableOccupied,
                    ),
                  ],
                ),

                // If Split, show Cash & Online amounts + Online method selector + live summary
                if (_settlementMode == 'Split') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandAccent.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.call_split,
                              size: 16,
                              color: AppColors.brandAccentLight,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SPLIT PAYMENT (CASH + ONLINE/UPI)',
                              style: TextStyle(
                                color: AppColors.brandAccentLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _splitCashAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Cash Amount (₹) *',
                            prefixText: '₹ ',
                            suffixIcon: TextButton(
                              onPressed: () {
                                setState(() {
                                  _splitCashAmountCtrl.text =
                                      grandTotal.toStringAsFixed(0);
                                  _splitOnlineAmountCtrl.text = '0';
                                });
                              },
                              child: const Text(
                                'All Cash',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.brandAccentLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _splitOnlineAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Online / UPI Amount (₹) *',
                            prefixText: '₹ ',
                            suffixIcon: TextButton(
                              onPressed: () {
                                final cash =
                                    double.tryParse(
                                      _splitCashAmountCtrl.text.trim(),
                                    ) ??
                                    0.0;
                                final rem = (grandTotal - cash).clamp(
                                  0.0,
                                  grandTotal,
                                );
                                setState(() {
                                  _splitOnlineAmountCtrl.text =
                                      rem.toStringAsFixed(0);
                                });
                              },
                              child: const Text(
                                'Fill Rest',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.brandAccentLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'ONLINE METHOD:',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildSplitMethodChip('UPI', Icons.qr_code),
                            const SizedBox(width: 8),
                            _buildSplitMethodChip('Card', Icons.credit_card),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSplitSummaryCard(grandTotal),
                      ],
                    ),
                  ),
                ],

                // If Partial, show amount input with validation & real-time calculation
                if (_settlementMode == 'Partial') ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _partialAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Amount Received Now (₹) *',
                      prefixText: '₹ ',
                      helperText:
                          'Max payable now: ₹${(grandTotal - 0.01).clamp(0.0, grandTotal).toStringAsFixed(2)}',
                      errorText: () {
                        final text = _partialAmountCtrl.text.trim();
                        if (text.isEmpty) return 'Please enter partial amount';
                        final val = double.tryParse(text);
                        if (val == null || val <= 0) {
                          return 'Amount must be greater than ₹0';
                        }
                        if (val >= grandTotal) {
                          return 'Amount cannot equal or exceed total (select Full Paid)';
                        }
                        return null;
                      }(),
                    ),
                  ),
                  if (double.tryParse(_partialAmountCtrl.text.trim()) != null &&
                      (double.tryParse(_partialAmountCtrl.text.trim())! > 0) &&
                      (double.tryParse(_partialAmountCtrl.text.trim())! <
                          grandTotal)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Received: ₹${double.parse(_partialAmountCtrl.text.trim()).toStringAsFixed(2)} • Remaining DUE: ₹${(grandTotal - double.parse(_partialAmountCtrl.text.trim())).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Payment Method (if money received now, for Single-method Full/Partial)
                if (_settlementMode != 'Due' && _settlementMode != 'Split') ...[
                  const SizedBox(height: 14),
                  const Text(
                    'PAYMENT METHOD FOR RECEIVED AMOUNT',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMethodChip('Cash', Icons.money),
                      const SizedBox(width: 8),
                      _buildMethodChip('UPI', Icons.qr_code),
                      const SizedBox(width: 8),
                      _buildMethodChip('Card', Icons.credit_card),
                    ],
                  ),
                ],

                const SizedBox(height: 26),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                          if (_isSubmitting) return;
                          if (!_formKey.currentState!.validate()) return;

                          if (!effectiveClose.isAfter(
                            widget.session.startTime,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Invalid close time. Table close time must be after table start time (${AppFormatters.timeOnly(widget.session.startTime)}).',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          if (effectiveClose.isAfter(
                            DateTime.now().add(const Duration(minutes: 1)),
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cannot close table at a future time.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          double paidAmount = 0.0;
                          final transactions = <PaymentTransaction>[];
                          String status = 'Due';
                          String? method;

                          if (_settlementMode == 'Full') {
                            paidAmount = grandTotal;
                            status = 'Received';
                            method = _paymentMethod;
                            transactions.add(
                              PaymentTransaction(
                                id: const Uuid().v4(),
                                amount: grandTotal,
                                paymentMethod: _paymentMethod,
                                receivedAt: effectiveClose,
                                receivedBy: _closingNameCtrl.text.trim(),
                                notes: 'Initial full settlement at checkout',
                              ),
                            );
                          } else if (_settlementMode == 'Split') {
                            final cashEntered =
                                double.tryParse(
                                  _splitCashAmountCtrl.text.trim(),
                                ) ??
                                0.0;
                            final onlineEntered =
                                double.tryParse(
                                  _splitOnlineAmountCtrl.text.trim(),
                                ) ??
                                0.0;
                            final totalSplit = cashEntered + onlineEntered;

                            if (totalSplit <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a valid Cash or Online amount greater than ₹0.',
                                  ),
                                  backgroundColor: AppColors.tableOccupied,
                                ),
                              );
                              return;
                            }

                            if (totalSplit > grandTotal + 0.01) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Total split paid (₹${totalSplit.toStringAsFixed(2)}) cannot exceed total bill (₹${grandTotal.toStringAsFixed(2)}).',
                                  ),
                                  backgroundColor: AppColors.tableOccupied,
                                ),
                              );
                              return;
                            }

                            paidAmount = totalSplit;
                            final remSplit =
                                (grandTotal - totalSplit).clamp(0.0, grandTotal);
                            final isFullSettled = remSplit < _dueBuffer;
                            status = isFullSettled ? 'Received' : 'Due';
                            method = 'Split (Cash + $_splitOnlineMethod)';

                            // 2 transaction entries with their relevant amounts
                            if (cashEntered > 0) {
                              transactions.add(
                                PaymentTransaction(
                                  id: const Uuid().v4(),
                                  amount: cashEntered,
                                  paymentMethod: 'Cash',
                                  receivedAt: effectiveClose,
                                  receivedBy: _closingNameCtrl.text.trim(),
                                  notes: 'Split payment - Cash portion',
                                ),
                              );
                            }

                            if (onlineEntered > 0) {
                              transactions.add(
                                PaymentTransaction(
                                  id: const Uuid().v4(),
                                  amount: onlineEntered,
                                  paymentMethod: _splitOnlineMethod,
                                  receivedAt: effectiveClose,
                                  receivedBy: _closingNameCtrl.text.trim(),
                                  notes:
                                      'Split payment - $_splitOnlineMethod portion',
                                ),
                              );
                            }
                          } else if (_settlementMode == 'Partial') {
                            final entered = double.tryParse(
                              _partialAmountCtrl.text.trim(),
                            );
                            if (entered == null || entered <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a partial amount greater than ₹0.',
                                  ),
                                  backgroundColor: AppColors.tableOccupied,
                                ),
                              );
                              return;
                            }
                            if (entered >= grandTotal) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Partial amount cannot equal or exceed total bill. Select Full Paid.',
                                  ),
                                  backgroundColor: AppColors.tableOccupied,
                                ),
                              );
                              return;
                            }
                            paidAmount = entered;
                            final remPartial =
                                (grandTotal - entered).clamp(0.0, grandTotal);
                            final isPartialSettled = remPartial < _dueBuffer;
                            status = isPartialSettled ? 'Received' : 'Due';
                            method = _paymentMethod;
                            transactions.add(
                              PaymentTransaction(
                                id: const Uuid().v4(),
                                amount: entered,
                                paymentMethod: _paymentMethod,
                                receivedAt: effectiveClose,
                                receivedBy: _closingNameCtrl.text.trim(),
                                notes: isPartialSettled
                                    ? 'Settled at checkout (due < ₹${_dueBuffer.toStringAsFixed(0)} waived)'
                                    : 'Initial partial payment at checkout',
                              ),
                            );
                          } else {
                            // Full Due
                            paidAmount = 0.0;
                            final isSettled = grandTotal < _dueBuffer;
                            status = isSettled ? 'Received' : 'Due';
                            method = null;
                          }

                          final historyRecord = TableHistoryRecord(
                            id: const Uuid().v4(),
                            companyId: widget.session.companyId,
                            tableId: widget.session.tableId,
                            tableName: widget.session.tableName,
                            customerName: _closingPersonCtrl.text.trim(),
                            customerPhone: _customerPhoneCtrl.text.trim(),
                            startedByName: widget.session.startedByName,
                            closedByName: _closingNameCtrl.text.trim(),
                            startedAt: widget.session.startTime,
                            closedAt: (widget.session.isPaused &&
                                    widget.session.lastPauseTime != null &&
                                    !_isCustomTime &&
                                    (_selectedPresetMinutes == 0 ||
                                        _selectedPresetMinutes == null))
                                ? widget.session.lastPauseTime!
                                : effectiveClose,
                            durationMinutes: durationMinutes,
                            tableAmount: tableCharge,
                            itemsAmount: itemsCharge,
                            totalAmount: grandTotal,
                            paidAmount: paidAmount,
                            paymentStatus: status,
                            paymentMethod: method,
                            items: widget.session.items,
                            transactions: transactions,
                            dueBufferAmount: _dueBuffer,
                            createdAt: DateTime.now(),
                          );

                          setState(() => _isSubmitting = true);
                          Navigator.of(context).pop(historyRecord);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _settlementMode == 'Full'
                              ? AppColors.tableAvailable
                              : (_settlementMode == 'Split'
                                  ? (() {
                                      final c = double.tryParse(
                                            _splitCashAmountCtrl.text.trim(),
                                          ) ??
                                          0.0;
                                      final o = double.tryParse(
                                            _splitOnlineAmountCtrl.text.trim(),
                                          ) ??
                                          0.0;
                                      final total = c + o;
                                      final due = (grandTotal - total).clamp(
                                        0.0,
                                        grandTotal,
                                      );
                                      return (due < _dueBuffer && total > 0)
                                          ? AppColors.tableAvailable
                                          : AppColors.brandAccentLight;
                                    }())
                                  : (_settlementMode == 'Partial'
                                      ? (() {
                                          final p = double.tryParse(
                                                _partialAmountCtrl.text.trim(),
                                              ) ??
                                              0.0;
                                          final due = (grandTotal - p).clamp(
                                            0.0,
                                            grandTotal,
                                          );
                                          return (due < _dueBuffer && p > 0)
                                              ? AppColors.tableAvailable
                                              : Colors.orange;
                                        }())
                                      : (grandTotal < _dueBuffer
                                          ? AppColors.tableAvailable
                                          : AppColors.tableOccupied))),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _settlementMode == 'Full'
                              ? 'RECEIVED ₹${grandTotal.toStringAsFixed(0)}'
                              : (_settlementMode == 'Split'
                                  ? () {
                                      final c =
                                          double.tryParse(
                                            _splitCashAmountCtrl.text.trim(),
                                          ) ??
                                          0.0;
                                      final o =
                                          double.tryParse(
                                            _splitOnlineAmountCtrl.text.trim(),
                                          ) ??
                                          0.0;
                                      final total = c + o;
                                      final due = (grandTotal - total).clamp(
                                        0.0,
                                        grandTotal,
                                      );
                                      if (due < _dueBuffer) {
                                        return 'RECEIVED ₹${total.toStringAsFixed(0)} (SPLIT SETTLED)';
                                      }
                                      return 'PAY ₹${total.toStringAsFixed(0)} (₹${due.toStringAsFixed(0)} DUE)';
                                    }()
                                  : (_settlementMode == 'Partial'
                                      ? () {
                                          final p =
                                              double.tryParse(
                                                _partialAmountCtrl.text.trim(),
                                              ) ??
                                              0.0;
                                          final due = (grandTotal - p).clamp(
                                            0.0,
                                            grandTotal,
                                          );
                                          if (due < _dueBuffer) {
                                            return 'RECEIVED ₹${p.toStringAsFixed(0)} (SETTLED)';
                                          }
                                          return 'PAY ₹${p.toStringAsFixed(0)} (₹${due.toStringAsFixed(0)} DUE)';
                                        }()
                                      : (grandTotal < _dueBuffer
                                          ? 'RECEIVED (WAIVED < ₹${_dueBuffer.toStringAsFixed(0)})'
                                          : 'DUE ₹${grandTotal.toStringAsFixed(0)}'))),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
),
);
  }


  Widget _buildSettlementOption({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color activeColor,
  }) {
    final isSelected = _settlementMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _settlementMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withAlpha(35)
                : AppColors.inputSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.cardBorderStroke,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : AppColors.secondaryText,
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? activeColor : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String subtitle,
    required String amount,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = method),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandAccent.withAlpha(40)
                : AppColors.inputSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandAccent
                  : AppColors.cardBorderStroke,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.brandAccentLight
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                method,
                style: TextStyle(
                  color: isSelected
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
    );
  }

  Widget _buildSplitMethodChip(String method, IconData icon) {
    final isSelected = _splitOnlineMethod == method;
    return InkWell(
      onTap: () => setState(() => _splitOnlineMethod = method),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandAccent.withAlpha(40)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.brandAccent
                : AppColors.cardBorderStroke,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.brandAccentLight
                  : AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              method,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitSummaryCard(double grandTotal) {
    final cash = double.tryParse(_splitCashAmountCtrl.text.trim()) ?? 0.0;
    final online = double.tryParse(_splitOnlineAmountCtrl.text.trim()) ?? 0.0;
    final totalCollected = cash + online;
    final remainingDue = (grandTotal - totalCollected).clamp(0.0, grandTotal);
    final isOverpaid = totalCollected > grandTotal + 0.01;
    final isFullySettled = remainingDue < _dueBuffer && totalCollected > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverpaid
            ? AppColors.error.withAlpha(20)
            : (isFullySettled
                ? AppColors.success.withAlpha(20)
                : AppColors.cardSurface),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverpaid
              ? AppColors.error.withAlpha(90)
              : (isFullySettled
                  ? AppColors.success.withAlpha(90)
                  : AppColors.cardBorderStroke),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paid via Cash:',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
              Text(
                '₹${cash.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid via $_splitOnlineMethod:',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              Text(
                '₹${online.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorderStroke, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverpaid
                    ? 'OVERPAID BY:'
                    : (isFullySettled
                        ? 'TOTAL COLLECTED (SETTLED):'
                        : 'TOTAL COLLECTED:'),
                style: TextStyle(
                  color: isOverpaid
                      ? AppColors.error
                      : (isFullySettled
                          ? AppColors.success
                          : AppColors.primaryText),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                '₹${totalCollected.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isOverpaid
                      ? AppColors.error
                      : (isFullySettled
                          ? AppColors.success
                          : AppColors.primaryText),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (!isFullySettled && !isOverpaid) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remaining DUE:',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '₹${remainingDue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else if (isFullySettled && remainingDue > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due Waived (< ₹${_dueBuffer.toStringAsFixed(0)}):',
                  style: const TextStyle(
                    color: AppColors.tableAvailable,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '₹${remainingDue.toStringAsFixed(2)} waived (Received)',
                  style: const TextStyle(
                    color: AppColors.tableAvailable,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

typedef CheckoutSessionScreen = CheckoutSessionDialog;
