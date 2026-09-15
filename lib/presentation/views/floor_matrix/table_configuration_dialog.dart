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
  late final TextEditingController _baseRate = TextEditingController(
    text: widget.table.standardRatePerHour.toStringAsFixed(0),
  );
  late final List<RateSchedule> _slots = List.of(widget.table.rateSchedules);

  @override
  void dispose() {
    _name.dispose();
    _baseRate.dispose();
    super.dispose();
  }

  String _time(int minute) =>
      TimeOfDay(hour: minute ~/ 60, minute: minute % 60).format(context);

  Future<void> _addSlot() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 0),
    );
    if (end == null || !mounted) return;
    final rate = TextEditingController(
      text: widget.table.peakRatePerHour.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Hourly rate for this period',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: TextField(
          controller: rate,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '₹ ',
            labelText: 'Hourly rate',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, double.tryParse(rate.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    // The dialog owns the field for the duration of its route. Disposing this
    // controller immediately after pop can race its final widget teardown.
    if (value == null || value <= 0 || !mounted) return;
    setState(
      () => _slots.add(
        RateSchedule(
          id: const Uuid().v4(),
          startMinuteOfDay: start.hour * 60 + start.minute,
          endMinuteOfDay: end.hour * 60 + end.minute,
          hourlyRate: value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.cardSurface,
    title: const Text(
      'Configure table rates',
      style: TextStyle(color: AppColors.primaryText),
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Table name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baseRate,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                labelText: 'Base hourly rate (outside configured periods)',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TIME-BASED RATES',
              style: TextStyle(
                color: AppColors.brandAccentLight,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add as many daily rate periods as needed. A period may cross midnight.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ..._slots.map(
              (slot) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_time(slot.startMinuteOfDay)} – ${_time(slot.endMinuteOfDay)}',
                  style: const TextStyle(color: AppColors.primaryText),
                ),
                subtitle: Text(
                  '₹${slot.hourlyRate.toStringAsFixed(0)} / hour',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.tableOccupied,
                  ),
                  onPressed: () => setState(() => _slots.remove(slot)),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _addSlot,
              icon: const Icon(Icons.schedule),
              label: const Text('Add rate period'),
            ),
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
          final base = double.tryParse(_baseRate.text.trim());
          if (_name.text.trim().isEmpty || base == null || base <= 0) return;
          Navigator.pop(
            context,
            widget.table.copyWith(
              name: _name.text.trim(),
              standardRatePerHour: base,
              rateSchedules: _slots,
            ),
          );
        },
        child: const Text('SAVE RATES'),
      ),
    ],
  );
}
