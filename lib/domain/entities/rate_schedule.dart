import 'package:equatable/equatable.dart';

/// A daily time range with a table-specific hourly price.
/// A range may cross midnight (for example, 22:00–02:00).
class RateSchedule extends Equatable {
  final String id;
  final int startMinuteOfDay;
  final int endMinuteOfDay;
  final double hourlyRate;
  final String label;

  const RateSchedule({
    required this.id,
    required this.startMinuteOfDay,
    required this.endMinuteOfDay,
    required this.hourlyRate,
    this.label = 'Peak rate',
  });

  bool appliesAt(DateTime time) {
    final minute = time.hour * 60 + time.minute;
    if (startMinuteOfDay == endMinuteOfDay) return true;
    if (startMinuteOfDay < endMinuteOfDay) {
      return minute >= startMinuteOfDay && minute < endMinuteOfDay;
    }
    return minute >= startMinuteOfDay || minute < endMinuteOfDay;
  }

  @override
  List<Object?> get props => [
    id,
    startMinuteOfDay,
    endMinuteOfDay,
    hourlyRate,
    label,
  ];
}
