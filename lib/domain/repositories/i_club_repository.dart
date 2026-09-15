import '../entities/club_branch.dart';
import '../entities/club_table.dart';
import '../entities/table_session.dart';

abstract class IClubRepository {
  Future<List<ClubBranch>> getBranches();
  Future<ClubBranch?> getBranchById(String branchId);
  Future<void> saveBranch(ClubBranch branch);
  Future<void> saveTable(ClubTable table);

  Stream<List<ClubTable>> watchTables(String branchId);
  Future<List<ClubTable>> getTables(String branchId);
  Future<ClubTable?> getTableById(String tableId);
  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? sessionId,
  });
  Future<void> updateTableClothHours(String tableId, double hoursToAdd);
  Future<void> incrementTableFrames(String tableId);

  Stream<List<TableSession>> watchActiveSessions(String branchId);
  Future<TableSession?> getActiveSessionForTable(String tableId);
  Future<TableSession?> getSessionById(String sessionId);
  Future<List<TableSession>> getSessionsHistory(
    String branchId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> startSession(TableSession session);
  Future<void> pauseSession(String sessionId);
  Future<void> resumeSession(String sessionId);
  Future<void> updateSessionAmounts(
    String sessionId, {
    double? fnbAmount,
    double? discountAmount,
  });
  Future<void> completeSession(
    String sessionId,
    PaymentMethod paymentMethod,
    double finalTableAmount,
    double finalTotalAmount,
  );
  Future<void> cancelOrDeleteSession(
    String sessionId,
    String reason,
    String operatorId,
  );
}
