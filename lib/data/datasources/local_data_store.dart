import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/audit_log_event.dart';
import '../../domain/entities/canteen_item.dart';
import '../../domain/entities/club_branch.dart';
import '../../domain/entities/club_table.dart';
import '../../domain/entities/equipment_item.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/entities/shift_record.dart';
import '../../domain/entities/tab_order_item.dart';
import '../../domain/entities/table_session.dart';
import '../../domain/entities/user_account.dart';

class LocalDataStore {
  static final LocalDataStore _instance = LocalDataStore._internal();
  factory LocalDataStore() => _instance;

  final _uuid = const Uuid();

  // In-memory data collections
  final List<ClubBranch> _branches = [];
  final List<ClubTable> _tables = [];
  final List<TableSession> _sessions = [];
  final List<CanteenItem> _canteenItems = [];
  final List<TabOrderItem> _orderItems = [];
  final List<EquipmentItem> _equipmentItems = [];
  final List<ShiftRecord> _shifts = [];
  final List<ExpenseRecord> _expenses = [];
  final List<AuditLogEvent> _auditLogs = [];
  final List<UserAccount> _users = [];
  UserAccount? _currentUser;

  // Reactive StreamControllers
  final _tablesController = StreamController<List<ClubTable>>.broadcast();
  final _sessionsController = StreamController<List<TableSession>>.broadcast();
  final _canteenController = StreamController<List<CanteenItem>>.broadcast();
  final _equipmentController =
      StreamController<List<EquipmentItem>>.broadcast();
  final _shiftController = StreamController<ShiftRecord?>.broadcast();
  final _expensesController = StreamController<List<ExpenseRecord>>.broadcast();
  final _auditLogsController =
      StreamController<List<AuditLogEvent>>.broadcast();
  final _userController = StreamController<UserAccount?>.broadcast();

  LocalDataStore._internal();

  // The store deliberately starts empty. Production persistence is populated by onboarding and sync.
  // --- Reactive Getters & Broadcasts ---

  Stream<List<ClubTable>> watchTables(String branchId) {
    // Emit current state immediately then return stream
    Future.microtask(() => _notifyTables(branchId));
    return _tablesController.stream;
  }

  void _notifyTables(String branchId) {
    if (!_tablesController.isClosed) {
      _tablesController.add(
        _tables.where((t) => t.branchId == branchId).toList(),
      );
    }
  }

  Stream<List<TableSession>> watchActiveSessions(String branchId) {
    Future.microtask(() => _notifySessions(branchId));
    return _sessionsController.stream;
  }

  void _notifySessions(String branchId) {
    if (!_sessionsController.isClosed) {
      _sessionsController.add(
        _sessions.where((s) => s.branchId == branchId && !s.isPaid).toList(),
      );
    }
  }

  Stream<List<CanteenItem>> watchCanteenItems(String branchId) {
    Future.microtask(() => _notifyCanteen(branchId));
    return _canteenController.stream;
  }

  void _notifyCanteen(String branchId) {
    if (!_canteenController.isClosed) {
      _canteenController.add(
        _canteenItems.where((c) => c.branchId == branchId).toList(),
      );
    }
  }

  Stream<List<EquipmentItem>> watchEquipmentItems(String branchId) {
    Future.microtask(() => _notifyEquipment(branchId));
    return _equipmentController.stream;
  }

  void _notifyEquipment(String branchId) {
    if (!_equipmentController.isClosed) {
      _equipmentController.add(
        _equipmentItems.where((e) => e.branchId == branchId).toList(),
      );
    }
  }

  Stream<ShiftRecord?> watchCurrentShift(String branchId) {
    Future.microtask(() => _notifyShift(branchId));
    return _shiftController.stream;
  }

  void _notifyShift(String branchId) {
    if (!_shiftController.isClosed) {
      final active = _shifts
          .where((s) => s.branchId == branchId && !s.isClosed)
          .toList();
      _shiftController.add(active.isNotEmpty ? active.last : null);
    }
  }

  Stream<List<ExpenseRecord>> watchExpenses(String branchId) {
    Future.microtask(() => _notifyExpenses(branchId));
    return _expensesController.stream;
  }

  void _notifyExpenses(String branchId) {
    if (!_expensesController.isClosed) {
      _expensesController.add(
        _expenses.where((e) => e.branchId == branchId).toList(),
      );
    }
  }

  Stream<List<AuditLogEvent>> watchAuditLogs(String branchId) {
    Future.microtask(() => _notifyAuditLogs(branchId));
    return _auditLogsController.stream;
  }

  void _notifyAuditLogs(String branchId) {
    if (!_auditLogsController.isClosed) {
      final logs = _auditLogs.where((l) => l.branchId == branchId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _auditLogsController.add(logs);
    }
  }

  Stream<UserAccount?> watchCurrentUser() {
    Future.microtask(() => _notifyUser());
    return _userController.stream;
  }

  void _notifyUser() {
    if (!_userController.isClosed) {
      _userController.add(_currentUser);
    }
  }

  // --- CRUD Operations ---

  List<ClubBranch> getBranches() => List.unmodifiable(_branches);

  ClubBranch? getBranchById(String id) {
    try {
      return _branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  void saveBranch(ClubBranch branch) {
    final index = _branches.indexWhere((existing) => existing.id == branch.id);
    if (index == -1) {
      _branches.add(branch);
    } else {
      _branches[index] = branch;
    }
  }

  void saveTable(ClubTable table) {
    final index = _tables.indexWhere((existing) => existing.id == table.id);
    if (index == -1) {
      _tables.add(table);
    } else {
      _tables[index] = table;
    }
    _notifyTables(table.branchId);
  }

  List<ClubTable> getTables(String branchId) =>
      _tables.where((t) => t.branchId == branchId).toList();

  ClubTable? getTableById(String tableId) {
    try {
      return _tables.firstWhere((t) => t.id == tableId);
    } catch (_) {
      return null;
    }
  }

  void updateTableStatus(
    String tableId,
    TableStatus status, {
    String? sessionId,
  }) {
    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      final old = _tables[idx];
      _tables[idx] = old.copyWith(
        status: status,
        currentSessionId: sessionId,
        clearCurrentSessionId: sessionId == null,
      );
      _notifyTables(old.branchId);
    }
  }

  void updateTableClothHours(String tableId, double hours) {
    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      final old = _tables[idx];
      final newHours = old.cumulativeClothHours + hours;
      _tables[idx] = old.copyWith(cumulativeClothHours: newHours);
      _notifyTables(old.branchId);
    }
  }

  void incrementTableFrames(String tableId) {
    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      final old = _tables[idx];
      _tables[idx] = old.copyWith(totalFramesPlayed: old.totalFramesPlayed + 1);
      _notifyTables(old.branchId);
    }
  }

  List<TableSession> getActiveSessions(String branchId) =>
      _sessions.where((s) => s.branchId == branchId && !s.isPaid).toList();

  TableSession? getActiveSessionForTable(String tableId) {
    try {
      return _sessions.firstWhere((s) => s.tableId == tableId && !s.isPaid);
    } catch (_) {
      return null;
    }
  }

  TableSession? getSessionById(String sessionId) {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  List<TableSession> getSessionsHistory(
    String branchId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _sessions.where((s) {
      if (s.branchId != branchId) return false;
      if (startDate != null && s.startTime.isBefore(startDate)) return false;
      if (endDate != null && s.startTime.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  void startSession(TableSession session) {
    _sessions.add(session);
    updateTableStatus(
      session.tableId,
      TableStatus.occupied,
      sessionId: session.id,
    );
    _notifySessions(session.branchId);

    // Audit log
    logAudit(
      AuditLogEvent(
        id: _uuid.v4(),
        branchId: session.branchId,
        operatorId: session.operatorId,
        operatorName: session.operatorName,
        action: 'Session Started',
        details:
            'Table "${session.tableName}" started for player "${session.playerName}" (${session.billingMode.displayName})',
        timestamp: DateTime.now(),
        severity: AuditSeverity.info,
      ),
    );
  }

  void pauseSession(String sessionId) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      if (!s.isPaused) {
        _sessions[idx] = s.copyWith(
          isPaused: true,
          lastPauseTime: DateTime.now(),
        );
        _notifySessions(s.branchId);

        logAudit(
          AuditLogEvent(
            id: _uuid.v4(),
            branchId: s.branchId,
            operatorId: s.operatorId,
            operatorName: s.operatorName,
            action: 'Timer Paused',
            details: 'Session paused for table "${s.tableName}"',
            timestamp: DateTime.now(),
            severity: AuditSeverity.info,
          ),
        );
      }
    }
  }

  void resumeSession(String sessionId) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      if (s.isPaused && s.lastPauseTime != null) {
        final extra = DateTime.now().difference(s.lastPauseTime!).inSeconds;
        _sessions[idx] = s.copyWith(
          isPaused: false,
          lastPauseTime: null,
          pausedSeconds: s.pausedSeconds + extra,
        );
        _notifySessions(s.branchId);

        logAudit(
          AuditLogEvent(
            id: _uuid.v4(),
            branchId: s.branchId,
            operatorId: s.operatorId,
            operatorName: s.operatorName,
            action: 'Timer Resumed',
            details:
                'Session resumed for table "${s.tableName}" (Paused for ${extra ~/ 60} mins)',
            timestamp: DateTime.now(),
            severity: AuditSeverity.info,
          ),
        );
      }
    }
  }

  void updateSessionAmounts(
    String sessionId, {
    double? fnbAmount,
    double? discountAmount,
  }) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      _sessions[idx] = s.copyWith(
        fnbAmount: fnbAmount ?? s.fnbAmount,
        discountAmount: discountAmount ?? s.discountAmount,
      );
      _notifySessions(s.branchId);
    }
  }

  void completeSession(
    String sessionId,
    PaymentMethod paymentMethod,
    double finalTableAmount,
    double finalTotalAmount,
  ) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      final endTime = DateTime.now();
      final billableSeconds = s.playedSecondsAt(endTime);

      _sessions[idx] = s.copyWith(
        endTime: endTime,
        isPaid: true,
        paymentMethod: paymentMethod,
        tableAmount: finalTableAmount,
        totalAmount: finalTotalAmount,
      );

      // Free up table
      updateTableStatus(s.tableId, TableStatus.available, sessionId: null);
      // Increment cumulative hours and frames on table
      updateTableClothHours(s.tableId, billableSeconds / 3600.0);
      incrementTableFrames(s.tableId);

      // Record in current shift
      if (paymentMethod == PaymentMethod.cash) {
        recordShiftCash(
          s.branchId,
          sessionCash: finalTableAmount,
          fnbCash: s.fnbAmount,
        );
      } else if (paymentMethod == PaymentMethod.upi) {
        recordShiftCash(s.branchId, upi: finalTotalAmount);
      } else if (paymentMethod == PaymentMethod.card) {
        recordShiftCash(s.branchId, card: finalTotalAmount);
      }

      // Update equipment wear
      recordEquipmentWear(s.tableId, billableSeconds / 3600.0);

      _notifySessions(s.branchId);

      logAudit(
        AuditLogEvent(
          id: _uuid.v4(),
          branchId: s.branchId,
          operatorId: _currentUser?.id ?? s.operatorId,
          operatorName: _currentUser?.name ?? s.operatorName,
          action: 'Payment Received',
          details:
              'Table "${s.tableName}" checked out. Total: ₹${finalTotalAmount.toStringAsFixed(2)} via ${paymentMethod.displayName}. Player: ${s.playerName}',
          timestamp: DateTime.now(),
          severity: AuditSeverity.info,
        ),
      );
    }
  }

  void cancelOrDeleteSession(
    String sessionId,
    String reason,
    String operatorId,
  ) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = _sessions[idx];
      _sessions.removeAt(idx);
      updateTableStatus(s.tableId, TableStatus.available, sessionId: null);
      _notifySessions(s.branchId);

      // Tamper-proof audit alert!
      logAudit(
        AuditLogEvent(
          id: _uuid.v4(),
          branchId: s.branchId,
          operatorId: operatorId,
          operatorName: _currentUser?.name ?? 'Admin',
          action: 'BILL DELETED / SESSION CANCELLED',
          details:
              'Session on table "${s.tableName}" was deleted without full payment! Reason: "$reason". Table Amount: ₹${s.tableAmount.toStringAsFixed(2)}',
          timestamp: DateTime.now(),
          severity: AuditSeverity.criticalAlert,
          isTamperFlag: true,
        ),
      );
    }
  }

  // Canteen
  List<CanteenItem> getCanteenItems(String branchId) =>
      _canteenItems.where((c) => c.branchId == branchId).toList();

  void saveCanteenItem(CanteenItem item) {
    final index = _canteenItems.indexWhere(
      (existing) => existing.id == item.id,
    );
    if (index == -1) {
      _canteenItems.add(item);
    } else {
      _canteenItems[index] = item;
    }
    _notifyCanteen(item.branchId);
  }

  void deductCanteenStock(String itemId, int quantity) {
    final idx = _canteenItems.indexWhere((c) => c.id == itemId);
    if (idx != -1) {
      final item = _canteenItems[idx];
      final updated = item.copyWith(
        stockQuantity: (item.stockQuantity - quantity).clamp(0, 99999),
      );
      _canteenItems[idx] = updated;
      _notifyCanteen(item.branchId);

      if (updated.isLowStock) {
        logAudit(
          AuditLogEvent(
            id: _uuid.v4(),
            branchId: item.branchId,
            operatorId: _currentUser?.id ?? 'system',
            operatorName: _currentUser?.name ?? 'System',
            action: 'Low Stock Alert',
            details:
                'Item "${item.name}" stock fell to ${updated.stockQuantity} ${updated.unit} (Threshold: ${item.minThreshold}).',
            timestamp: DateTime.now(),
            severity: AuditSeverity.warning,
          ),
        );
      }
    }
  }

  void restockCanteenItem(String itemId, int quantity) {
    final idx = _canteenItems.indexWhere((c) => c.id == itemId);
    if (idx != -1) {
      final item = _canteenItems[idx];
      _canteenItems[idx] = item.copyWith(
        stockQuantity: item.stockQuantity + quantity,
      );
      _notifyCanteen(item.branchId);
    }
  }

  void addTabOrderItem(TabOrderItem item) {
    _orderItems.add(item);
    deductCanteenStock(item.itemId, item.quantity);

    // If attached to a table session, update session fnbAmount
    if (item.sessionId != null) {
      final sIdx = _sessions.indexWhere((s) => s.id == item.sessionId);
      if (sIdx != -1) {
        final s = _sessions[sIdx];
        _sessions[sIdx] = s.copyWith(fnbAmount: s.fnbAmount + item.totalAmount);
        _notifySessions(s.branchId);
      }
    }

    logAudit(
      AuditLogEvent(
        id: _uuid.v4(),
        branchId: item.branchId,
        operatorId: item.operatorId,
        operatorName: item.operatorName,
        action: item.sessionId != null
            ? 'F&B Added to Table'
            : 'Direct Counter POS Sale',
        details:
            '${item.quantity}x ${item.itemName} sold for ₹${item.totalAmount.toStringAsFixed(2)}',
        timestamp: DateTime.now(),
        severity: AuditSeverity.info,
      ),
    );
  }

  List<TabOrderItem> getSessionTabItems(String sessionId) =>
      _orderItems.where((o) => o.sessionId == sessionId).toList();

  List<TabOrderItem> getAllSalesHistory(String branchId) =>
      _orderItems.where((o) => o.branchId == branchId).toList();

  // Equipment
  List<EquipmentItem> getEquipmentItems(String branchId) =>
      _equipmentItems.where((e) => e.branchId == branchId).toList();

  void saveEquipmentItem(EquipmentItem item) {
    final index = _equipmentItems.indexWhere(
      (existing) => existing.id == item.id,
    );
    if (index == -1) {
      _equipmentItems.add(item);
    } else {
      _equipmentItems[index] = item;
    }
    _notifyEquipment(item.branchId);
  }

  void recordEquipmentWear(String tableId, double hours) {
    for (int i = 0; i < _equipmentItems.length; i++) {
      final eq = _equipmentItems[i];
      if (eq.tableId == tableId && eq.type == EquipmentType.tableClothFelt) {
        final newHours = eq.currentMetricValue + hours;
        EquipmentAlertStatus alert = eq.alertStatus;
        String alertMsg = eq.alertMessage;

        if (newHours >= 50.0 && eq.thresholdValue == 50.0) {
          alert = EquipmentAlertStatus.warning;
          alertMsg =
              'Ironing cycle overdue! ${newHours.toStringAsFixed(1)} / 50.0 playing hours.';
        } else if (newHours >= 1000.0) {
          alert = EquipmentAlertStatus.critical;
          alertMsg =
              'Cloth felt re-clothing urgently required! Exceeded 1,000 playing hours.';
        }

        _equipmentItems[i] = eq.copyWith(
          currentMetricValue: newHours,
          alertStatus: alert,
          alertMessage: alertMsg,
        );
      } else if (eq.type == EquipmentType.cueTip) {
        final newHours = eq.currentMetricValue + hours;
        final wearRatio = newHours / eq.maxLifespan;
        EquipmentAlertStatus alert = wearRatio >= 0.85
            ? EquipmentAlertStatus.warning
            : EquipmentAlertStatus.normal;
        _equipmentItems[i] = eq.copyWith(
          currentMetricValue: newHours,
          alertStatus: alert,
          alertMessage:
              'Cue tips wear at ${(wearRatio * 100).toStringAsFixed(0)}% (${newHours.toStringAsFixed(1)}/${eq.maxLifespan.toStringAsFixed(0)} hrs).',
        );
      }
    }
    _notifyEquipment('branch-1');
  }

  void logEquipmentMaintenanceDone(String equipmentId, {String? notes}) {
    final idx = _equipmentItems.indexWhere((e) => e.id == equipmentId);
    if (idx != -1) {
      final eq = _equipmentItems[idx];
      // Reset metric based on type
      double resetValue = 0.0;
      if (eq.type == EquipmentType.chalkBlock) {
        resetValue = eq.maxLifespan;
      }

      _equipmentItems[idx] = eq.copyWith(
        currentMetricValue: resetValue,
        lastMaintenanceDate: DateTime.now(),
        alertStatus: EquipmentAlertStatus.normal,
        alertMessage:
            'Maintained on ${DateTime.now().toLocal().toString().substring(0, 16)}. In optimal condition.',
      );
      _notifyEquipment(eq.branchId);

      logAudit(
        AuditLogEvent(
          id: _uuid.v4(),
          branchId: eq.branchId,
          operatorId: _currentUser?.id ?? 'system',
          operatorName: _currentUser?.name ?? 'Manager',
          action: 'Equipment Maintenance Logged',
          details:
              'Maintenance recorded for "${eq.name}". Notes: ${notes ?? "Cycle reset successfully"}',
          timestamp: DateTime.now(),
          severity: AuditSeverity.info,
        ),
      );
    }
  }

  // Shifts
  ShiftRecord? getCurrentShift(String branchId) {
    final active = _shifts
        .where((s) => s.branchId == branchId && !s.isClosed)
        .toList();
    return active.isNotEmpty ? active.last : null;
  }

  void startShift(ShiftRecord shift) {
    _shifts.add(shift);
    _notifyShift(shift.branchId);

    logAudit(
      AuditLogEvent(
        id: _uuid.v4(),
        branchId: shift.branchId,
        operatorId: shift.operatorId,
        operatorName: shift.operatorName,
        action: 'Shift Duty Commenced',
        details:
            'Shift started with opening drawer cash of ₹${shift.openingCashDrawer.toStringAsFixed(2)}',
        timestamp: DateTime.now(),
        severity: AuditSeverity.info,
      ),
    );
  }

  void recordShiftCash(
    String branchId, {
    double sessionCash = 0.0,
    double fnbCash = 0.0,
    double upi = 0.0,
    double card = 0.0,
  }) {
    final current = getCurrentShift(branchId);
    if (current != null) {
      final idx = _shifts.indexWhere((s) => s.id == current.id);
      if (idx != -1) {
        _shifts[idx] = current.copyWith(
          totalCashSessionRevenue:
              current.totalCashSessionRevenue + sessionCash,
          totalCashFnbRevenue: current.totalCashFnbRevenue + fnbCash,
          totalUpiRevenue: current.totalUpiRevenue + upi,
          totalCardRevenue: current.totalCardRevenue + card,
        );
        _notifyShift(branchId);
      }
    }
  }

  ShiftRecord closeShiftHandover({
    required String shiftId,
    required double countedPhysicalCash,
    required String closingNotes,
  }) {
    final idx = _shifts.indexWhere((s) => s.id == shiftId);
    if (idx != -1) {
      final s = _shifts[idx];
      final expected = s.expectedCash;
      final variance = countedPhysicalCash - expected;
      final isTamperMismatch = variance.abs() > 0.01;

      final closed = s.copyWith(
        shiftEndTime: DateTime.now(),
        physicalCashCounted: countedPhysicalCash,
        varianceAmount: variance,
        isClosed: true,
        closingNotes: closingNotes,
      );

      _shifts[idx] = closed;
      _notifyShift(s.branchId);

      // Tamper-proof audit trail for variance
      logAudit(
        AuditLogEvent(
          id: _uuid.v4(),
          branchId: s.branchId,
          operatorId: s.operatorId,
          operatorName: s.operatorName,
          action: isTamperMismatch
              ? 'SHIFT CASH MISMATCH FLAGGED'
              : 'Shift Handover Completed',
          details: isTamperMismatch
              ? 'CASH VARIANCE ALERT: Expected cash ₹${expected.toStringAsFixed(2)}, but counted ₹${countedPhysicalCash.toStringAsFixed(2)}. Variance: ${variance >= 0 ? "+" : ""}${variance.toStringAsFixed(2)}! Notes: "$closingNotes"'
              : 'Shift closed smoothly. Cash drawer matched exactly: ₹${expected.toStringAsFixed(2)}',
          timestamp: DateTime.now(),
          severity: isTamperMismatch
              ? AuditSeverity.criticalAlert
              : AuditSeverity.info,
          isTamperFlag: isTamperMismatch,
        ),
      );

      return closed;
    }
    throw Exception('Shift not found: $shiftId');
  }

  List<ShiftRecord> getShiftHistory(String branchId) =>
      _shifts.where((s) => s.branchId == branchId).toList();

  // Expenses
  List<ExpenseRecord> getExpenses(String branchId) =>
      _expenses.where((e) => e.branchId == branchId).toList();

  void logExpense(ExpenseRecord expense) {
    _expenses.add(expense);
    _notifyExpenses(expense.branchId);

    logAudit(
      AuditLogEvent(
        id: _uuid.v4(),
        branchId: expense.branchId,
        operatorId: expense.loggedByOperatorId,
        operatorName: expense.loggedByOperatorName,
        action: 'Operational Expense Logged',
        details:
            'Expense of ₹${expense.amount.toStringAsFixed(2)} logged for "${expense.description}" (${expense.category.displayName}) to vendor "${expense.vendorName}"',
        timestamp: DateTime.now(),
        severity: AuditSeverity.info,
      ),
    );
  }

  void deleteExpense(String expenseId) {
    final idx = _expenses.indexWhere((e) => e.id == expenseId);
    if (idx != -1) {
      final exp = _expenses[idx];
      _expenses.removeAt(idx);
      _notifyExpenses(exp.branchId);

      logAudit(
        AuditLogEvent(
          id: _uuid.v4(),
          branchId: exp.branchId,
          operatorId: _currentUser?.id ?? 'admin',
          operatorName: _currentUser?.name ?? 'Super Admin',
          action: 'EXPENSE DELETED',
          details:
              'Expense of ₹${exp.amount.toStringAsFixed(2)} for "${exp.description}" was deleted from ledger.',
          timestamp: DateTime.now(),
          severity: AuditSeverity.warning,
          isTamperFlag: true,
        ),
      );
    }
  }

  // Audit
  void logAudit(AuditLogEvent event) {
    _auditLogs.add(event);
    _notifyAuditLogs(event.branchId);
  }

  List<AuditLogEvent> getAuditLogs(String branchId) =>
      _auditLogs.where((l) => l.branchId == branchId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  // Users & Auth
  UserAccount? getCurrentUser() => _currentUser;
  List<UserAccount> getAvailableUsers() => List.unmodifiable(_users);

  void switchUserRole(UserRole role) {
    final matched = _users.firstWhere(
      (u) => u.role == role,
      orElse: () => _users.first,
    );
    _currentUser = matched;
    _notifyUser();
  }

  void switchBranch(String branchId) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(branchId: branchId);
      _notifyUser();
      _notifyTables(branchId);
      _notifySessions(branchId);
      _notifyCanteen(branchId);
      _notifyEquipment(branchId);
      _notifyShift(branchId);
      _notifyExpenses(branchId);
      _notifyAuditLogs(branchId);
    }
  }

  void setCurrentUser(UserAccount user) {
    _currentUser = user;
    _notifyUser();
  }

  void saveUser(UserAccount user) {
    final index = _users.indexWhere((existing) => existing.id == user.id);
    if (index == -1) {
      _users.add(user);
    } else {
      _users[index] = user;
    }
  }
}
