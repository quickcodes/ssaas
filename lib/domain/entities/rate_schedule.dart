import 'package:equatable/equatable.dart';

/// A rate period that specifies an hourly price for given time window and weekdays.
class RateSchedule extends Equatable {
  final String id;
  final int startMinuteOfDay;
  final int endMinuteOfDay;
  final double hourlyRate;
  final String label;
  final List<int> weekdays; // 1 = Monday, ..., 7 = Sunday

  const RateSchedule({
    required this.id,
    required this.startMinuteOfDay,
    required this.endMinuteOfDay,
    required this.hourlyRate,
    this.label = 'Custom Rate',
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
  });

  static const List<String> weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String get weekdayDisplay {
    if (weekdays.length == 7) return 'All Days';
    if (weekdays.isEmpty) return 'No Days';
    final sorted = List<int>.from(weekdays)..sort();
    return sorted.map((d) => weekdayLabels[d - 1]).join(', ');
  }

  bool appliesAt(DateTime time) {
    if (weekdays.isNotEmpty && !weekdays.contains(time.weekday)) {
      return false;
    }
    final minute = time.hour * 60 + time.minute;
    if (startMinuteOfDay == endMinuteOfDay) return true;
    if (startMinuteOfDay < endMinuteOfDay) {
      return minute >= startMinuteOfDay && minute < endMinuteOfDay;
    }
    return minute >= startMinuteOfDay || minute < endMinuteOfDay;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startMinuteOfDay': startMinuteOfDay,
      'endMinuteOfDay': endMinuteOfDay,
      'hourlyRate': hourlyRate,
      'label': label,
      'weekdays': weekdays,
    };
  }

  factory RateSchedule.fromMap(Map<String, dynamic> map) {
    return RateSchedule(
      id: map['id'] as String? ?? '',
      startMinuteOfDay: (map['startMinuteOfDay'] as num?)?.toInt() ?? 0,
      endMinuteOfDay: (map['endMinuteOfDay'] as num?)?.toInt() ?? 0,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] as String? ?? 'Custom Rate',
      weekdays: (map['weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
    );
  }

  RateSchedule copyWith({
    String? id,
    int? startMinuteOfDay,
    int? endMinuteOfDay,
    double? hourlyRate,
    String? label,
    List<int>? weekdays,
  }) {
    return RateSchedule(
      id: id ?? this.id,
      startMinuteOfDay: startMinuteOfDay ?? this.startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay ?? this.endMinuteOfDay,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      label: label ?? this.label,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startMinuteOfDay,
        endMinuteOfDay,
        hourlyRate,
        label,
        weekdays,
      ];
}
