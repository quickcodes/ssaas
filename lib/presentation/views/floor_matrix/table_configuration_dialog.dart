import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/rate_schedule.dart';

class TableConfigurationDialog extends StatefulWidget {
  final ClubTable table;
  const TableConfigurationDialog({super.key, required this.table});

  @override
  State<TableConfigurationDialog> createState() =>
      _TableConfigurationDialogState();
}

class _TableConfigurationDialogState extends State<TableConfigurationDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.table.name,
  );
  late final TextEditingController _generalPrice = TextEditingController(
    text: widget.table.generalPrice.toStringAsFixed(0),
  );
  late final TextEditingController _specs = TextEditingController(
    text: widget.table.specsDescription,
  );
  late final List<RateSchedule> _customPricings =
      List.of(widget.table.customPricings);

  @override
  void dispose() {
    _name.dispose();
    _generalPrice.dispose();
    _specs.dispose();
    super.dispose();
  }

  String _formatMinute(int minute) =>
      TimeOfDay(hour: minute ~/ 60, minute: minute % 60).format(context);

  Future<void> _addCustomPricing() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'SELECT START TIME',
    );
    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 0),
      helpText: 'SELECT END TIME',
    );
    if (end == null || !mounted) return;

    final rateCtrl = TextEditingController(text: '150');
    final labelCtrl = TextEditingController(text: 'Peak Hours');
    List<int> selectedWeekdays = [1, 2, 3, 4, 5, 6, 7]; // Default all days

    final result = await showDialog<RateSchedule>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          title: const Text(
            'Add Custom Pricing Schedule',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pricing Label',
                      hintText: 'e.g. Evening Peak, Weekend Rate',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hourly Rate (₹)',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'APPLICABLE WEEK DAYS',
                    style: TextStyle(
                      color: AppColors.brandAccentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final dayNum = index + 1;
                      final dayLabel = RateSchedule.weekdayLabels[index];
                      final isSelected = selectedWeekdays.contains(dayNum);

                      return FilterChip(
                        label: Text(dayLabel),
                        selected: isSelected,
                        selectedColor: AppColors.brandAccent.withAlpha(50),
                        checkmarkColor: AppColors.brandAccentLight,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primaryText
                              : AppColors.secondaryText,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.inputSurface,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.brandAccent
                              : AppColors.cardBorderStroke,
                        ),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedWeekdays.add(dayNum);
                            } else {
                              selectedWeekdays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final rate = double.tryParse(rateCtrl.text.trim());
                if (rate == null || rate <= 0 || selectedWeekdays.isEmpty) {
                  return;
                }
                Navigator.pop(
                  dialogCtx,
                  RateSchedule(
                    id: const Uuid().v4(),
                    label: labelCtrl.text.trim().isEmpty
                        ? 'Custom Rate'
                        : labelCtrl.text.trim(),
                    startMinuteOfDay: start.hour * 60 + start.minute,
                    endMinuteOfDay: end.hour * 60 + end.minute,
                    hourlyRate: rate,
                    weekdays: selectedWeekdays,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
              ),
              child: const Text('Add Pricing'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _customPricings.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      title: Row(
        children: [
          const Icon(Icons.tune, color: AppColors.brandAccentLight),
          const SizedBox(width: 10),
          Text(
            'Configure Table & Dynamic Rates',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Table Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _generalPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'General Hourly Price (Default) *',
                  helperText:
                      'Used whenever no custom time/day schedule applies',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _specs,
                decoration: const InputDecoration(
                  labelText: 'Specs / Description',
                  hintText: 'e.g. 12ft Tournament Slate Table, Strachan Cloth',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CUSTOM PRICINGS (TIME & DAYS)',
                    style: TextStyle(
                      color: AppColors.brandAccentLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addCustomPricing,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Custom Pricing'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Add different prices based on time of day and specific weekdays (Mon..Sun).',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (_customPricings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: const Text(
                    'No custom pricings configured. General price will always apply.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ..._customPricings.map((slot) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    slot.label,
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandAccent.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '₹${slot.hourlyRate.toStringAsFixed(0)} / hr',
                                      style: const TextStyle(
                                        color: AppColors.brandAccentLight,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatMinute(slot.startMinuteOfDay)} – ${_formatMinute(slot.endMinuteOfDay)}  •  ${slot.weekdayDisplay}',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.tableOccupied,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _customPricings.remove(slot));
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final general = double.tryParse(_generalPrice.text.trim());
            if (_name.text.trim().isEmpty || general == null || general <= 0) {
              return;
            }
            Navigator.pop(
              context,
              widget.table.copyWith(
                name: _name.text.trim(),
                generalPrice: general,
                specsDescription: _specs.text.trim(),
                customPricings: _customPricings,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandAccent,
          ),
          child: const Text('SAVE TABLE'),
        ),
      ],
    );
  }
}
