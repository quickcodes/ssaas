import '../../domain/entities/audit_log_event.dart';
import '../../domain/repositories/i_audit_repository.dart';
import '../datasources/local_data_store.dart';

class AuditRepositoryImpl implements IAuditRepository {
  final LocalDataStore _ds;
  AuditRepositoryImpl(this._ds);

  @override
  Stream<List<AuditLogEvent>> watchAuditLogs(String branchId) => _ds.watchAuditLogs(branchId);

  @override
  Future<List<AuditLogEvent>> getAuditLogs(String branchId) async => _ds.getAuditLogs(branchId);

  @override
  Future<void> logEvent(AuditLogEvent event) async {
    _ds.logAudit(event);
  }
}
