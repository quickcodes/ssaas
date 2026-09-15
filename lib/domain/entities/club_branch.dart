import 'package:equatable/equatable.dart';

class ClubBranch extends Equatable {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double defaultStandardHourlyRate;
  final double defaultPeakHourlyRate;
  final int peakStartHour; // e.g. 18 (6:00 PM)
  final int peakEndHour;   // e.g. 23 (11:00 PM)
  final String currencySymbol;

  const ClubBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.defaultStandardHourlyRate,
    required this.defaultPeakHourlyRate,
    this.peakStartHour = 18,
    this.peakEndHour = 23,
    this.currencySymbol = '₹',
  });

  ClubBranch copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    double? defaultStandardHourlyRate,
    double? defaultPeakHourlyRate,
    int? peakStartHour,
    int? peakEndHour,
    String? currencySymbol,
  }) {
    return ClubBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      defaultStandardHourlyRate: defaultStandardHourlyRate ?? this.defaultStandardHourlyRate,
      defaultPeakHourlyRate: defaultPeakHourlyRate ?? this.defaultPeakHourlyRate,
      peakStartHour: peakStartHour ?? this.peakStartHour,
      peakEndHour: peakEndHour ?? this.peakEndHour,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        defaultStandardHourlyRate,
        defaultPeakHourlyRate,
        peakStartHour,
        peakEndHour,
        currencySymbol,
      ];
}
