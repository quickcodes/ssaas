import '../entities/shift_record.dart';

abstract class IShiftRepository {
  Stream<ShiftRecord?> watchCurrentShift(String branchId);
  Future<ShiftRecord?> getCurrentShift(String branchId);
  Future<void> startShift(ShiftRecord shift);
  Future<void> recordCashTransaction(String branchId, {double sessionCash = 0.0, double fnbCash = 0.0, double upi = 0.0, double card = 0.0});
  Future<ShiftRecord> closeShiftHandover({
    required String shiftId,
    required double countedPhysicalCash,
    required String closingNotes,
  });
  Future<List<ShiftRecord>> getShiftHistory(String branchId);
}
