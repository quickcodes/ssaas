import '../entities/audit_log_event.dart';

abstract class IAuditRepository {
  Stream<List<AuditLogEvent>> watchAuditLogs(String branchId);
  Future<List<AuditLogEvent>> getAuditLogs(String branchId);
  Future<void> logEvent(AuditLogEvent event);
}
