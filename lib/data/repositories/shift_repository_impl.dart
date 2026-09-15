import '../../domain/entities/shift_record.dart';
import '../../domain/repositories/i_shift_repository.dart';
import '../datasources/local_data_store.dart';

class ShiftRepositoryImpl implements IShiftRepository {
  final LocalDataStore _ds;
  ShiftRepositoryImpl(this._ds);

  @override
  Stream<ShiftRecord?> watchCurrentShift(String branchId) => _ds.watchCurrentShift(branchId);

  @override
  Future<ShiftRecord?> getCurrentShift(String branchId) async => _ds.getCurrentShift(branchId);

  @override
  Future<void> startShift(ShiftRecord shift) async {
    _ds.startShift(shift);
  }

  @override
  Future<void> recordCashTransaction(String branchId, {double sessionCash = 0.0, double fnbCash = 0.0, double upi = 0.0, double card = 0.0}) async {
    _ds.recordShiftCash(branchId, sessionCash: sessionCash, fnbCash: fnbCash, upi: upi, card: card);
  }

  @override
  Future<ShiftRecord> closeShiftHandover({
    required String shiftId,
    required double countedPhysicalCash,
    required String closingNotes,
  }) async {
    return _ds.closeShiftHandover(
      shiftId: shiftId,
      countedPhysicalCash: countedPhysicalCash,
      closingNotes: closingNotes,
    );
  }

  @override
  Future<List<ShiftRecord>> getShiftHistory(String branchId) async => _ds.getShiftHistory(branchId);
}
