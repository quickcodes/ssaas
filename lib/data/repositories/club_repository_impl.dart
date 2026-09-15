import '../../domain/entities/club_branch.dart';
import '../../domain/entities/club_table.dart';
import '../../domain/entities/table_session.dart';
import '../../domain/repositories/i_club_repository.dart';
import '../datasources/local_data_store.dart';

class ClubRepositoryImpl implements IClubRepository {
  final LocalDataStore _ds;
  ClubRepositoryImpl(this._ds);

  @override
  Future<List<ClubBranch>> getBranches() async => _ds.getBranches();

  @override
  Future<ClubBranch?> getBranchById(String branchId) async =>
      _ds.getBranchById(branchId);

  @override
  Future<void> saveBranch(ClubBranch branch) async => _ds.saveBranch(branch);

  @override
  Future<void> saveTable(ClubTable table) async => _ds.saveTable(table);

  @override
  Stream<List<ClubTable>> watchTables(String branchId) =>
      _ds.watchTables(branchId);

  @override
  Future<List<ClubTable>> getTables(String branchId) async =>
      _ds.getTables(branchId);

  @override
  Future<ClubTable?> getTableById(String tableId) async =>
      _ds.getTableById(tableId);

  @override
  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? sessionId,
  }) async {
    _ds.updateTableStatus(tableId, status, sessionId: sessionId);
  }

  @override
  Future<void> updateTableClothHours(String tableId, double hoursToAdd) async {
    _ds.updateTableClothHours(tableId, hoursToAdd);
  }

  @override
  Future<void> incrementTableFrames(String tableId) async {
    _ds.incrementTableFrames(tableId);
  }

  @override
  Stream<List<TableSession>> watchActiveSessions(String branchId) =>
      _ds.watchActiveSessions(branchId);

  @override
  Future<TableSession?> getActiveSessionForTable(String tableId) async =>
      _ds.getActiveSessionForTable(tableId);

  @override
  Future<TableSession?> getSessionById(String sessionId) async =>
      _ds.getSessionById(sessionId);

  @override
  Future<List<TableSession>> getSessionsHistory(
    String branchId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async =>
      _ds.getSessionsHistory(branchId, startDate: startDate, endDate: endDate);

  @override
  Future<void> startSession(TableSession session) async {
    _ds.startSession(session);
  }

  @override
  Future<void> pauseSession(String sessionId) async {
    _ds.pauseSession(sessionId);
  }

  @override
  Future<void> resumeSession(String sessionId) async {
    _ds.resumeSession(sessionId);
  }

  @override
  Future<void> updateSessionAmounts(
    String sessionId, {
    double? fnbAmount,
    double? discountAmount,
  }) async {
    _ds.updateSessionAmounts(
      sessionId,
      fnbAmount: fnbAmount,
      discountAmount: discountAmount,
    );
  }

  @override
  Future<void> completeSession(
    String sessionId,
    PaymentMethod paymentMethod,
    double finalTableAmount,
    double finalTotalAmount,
  ) async {
    _ds.completeSession(
      sessionId,
      paymentMethod,
      finalTableAmount,
      finalTotalAmount,
    );
  }

  @override
  Future<void> cancelOrDeleteSession(
    String sessionId,
    String reason,
    String operatorId,
  ) async {
    _ds.cancelOrDeleteSession(sessionId, reason, operatorId);
  }
}
