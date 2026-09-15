import 'package:equatable/equatable.dart';

class ShiftRecord extends Equatable {
  final String id;
  final String branchId;
  final String operatorId;
  final String operatorName;
  final DateTime shiftStartTime;
  final DateTime? shiftEndTime;
  final double openingCashDrawer;
  final double totalCashSessionRevenue;
  final double totalCashFnbRevenue;
  final double totalUpiRevenue;
  final double totalCardRevenue;
  final double? physicalCashCounted;
  final double? varianceAmount; // physicalCashCounted - expectedCash
  final bool isClosed;
  final String closingNotes;

  const ShiftRecord({
    required this.id,
    required this.branchId,
    required this.operatorId,
    required this.operatorName,
    required this.shiftStartTime,
    this.shiftEndTime,
    required this.openingCashDrawer,
    this.totalCashSessionRevenue = 0.0,
    this.totalCashFnbRevenue = 0.0,
    this.totalUpiRevenue = 0.0,
    this.totalCardRevenue = 0.0,
    this.physicalCashCounted,
    this.varianceAmount,
    this.isClosed = false,
    this.closingNotes = '',
  });

  double get expectedCash => openingCashDrawer + totalCashSessionRevenue + totalCashFnbRevenue;
  double get totalRevenue => totalCashSessionRevenue + totalCashFnbRevenue + totalUpiRevenue + totalCardRevenue;

  ShiftRecord copyWith({
    String? id,
    String? branchId,
    String? operatorId,
    String? operatorName,
    DateTime? shiftStartTime,
    DateTime? shiftEndTime,
    double? openingCashDrawer,
    double? totalCashSessionRevenue,
    double? totalCashFnbRevenue,
    double? totalUpiRevenue,
    double? totalCardRevenue,
    double? physicalCashCounted,
    double? varianceAmount,
    bool? isClosed,
    String? closingNotes,
  }) {
    return ShiftRecord(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      openingCashDrawer: openingCashDrawer ?? this.openingCashDrawer,
      totalCashSessionRevenue: totalCashSessionRevenue ?? this.totalCashSessionRevenue,
      totalCashFnbRevenue: totalCashFnbRevenue ?? this.totalCashFnbRevenue,
      totalUpiRevenue: totalUpiRevenue ?? this.totalUpiRevenue,
      totalCardRevenue: totalCardRevenue ?? this.totalCardRevenue,
      physicalCashCounted: physicalCashCounted ?? this.physicalCashCounted,
      varianceAmount: varianceAmount ?? this.varianceAmount,
      isClosed: isClosed ?? this.isClosed,
      closingNotes: closingNotes ?? this.closingNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        operatorId,
        operatorName,
        shiftStartTime,
        shiftEndTime,
        openingCashDrawer,
        totalCashSessionRevenue,
        totalCashFnbRevenue,
        totalUpiRevenue,
        totalCardRevenue,
        physicalCashCounted,
        varianceAmount,
        isClosed,
        closingNotes,
      ];
}
