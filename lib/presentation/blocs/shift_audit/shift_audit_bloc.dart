import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/audit_log_event.dart';
import '../../../domain/entities/shift_record.dart';
import '../../../domain/repositories/i_audit_repository.dart';
import '../../../domain/repositories/i_shift_repository.dart';

// Events
abstract class ShiftAuditEvent extends Equatable {
  const ShiftAuditEvent();
  @override
  List<Object?> get props => [];
}

class LoadShiftAuditEvent extends ShiftAuditEvent {
  final String branchId;
  const LoadShiftAuditEvent(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class _CurrentShiftUpdatedEvent extends ShiftAuditEvent {
  final ShiftRecord? shift;
  const _CurrentShiftUpdatedEvent(this.shift);
  @override
  List<Object?> get props => [shift];
}

class _AuditLogsUpdatedEvent extends ShiftAuditEvent {
  final List<AuditLogEvent> logs;
  const _AuditLogsUpdatedEvent(this.logs);
  @override
  List<Object?> get props => [logs];
}

class StartNewShiftEvent extends ShiftAuditEvent {
  final ShiftRecord shift;
  const StartNewShiftEvent(this.shift);
  @override
  List<Object?> get props => [shift];
}

class CloseShiftHandoverEvent extends ShiftAuditEvent {
  final String shiftId;
  final double countedPhysicalCash;
  final String closingNotes;

  const CloseShiftHandoverEvent({
    required this.shiftId,
    required this.countedPhysicalCash,
    required this.closingNotes,
  });

  @override
  List<Object?> get props => [shiftId, countedPhysicalCash, closingNotes];
}

// State
class ShiftAuditState extends Equatable {
  final ShiftRecord? currentShift;
  final List<ShiftRecord> shiftHistory;
  final List<AuditLogEvent> auditLogs;
  final bool isLoading;
  final ShiftRecord? lastAuditedShift;
  final String? alertMessage;

  const ShiftAuditState({
    this.currentShift,
    this.shiftHistory = const [],
    this.auditLogs = const [],
    this.isLoading = false,
    this.lastAuditedShift,
    this.alertMessage,
  });

  List<AuditLogEvent> get flaggedAuditLogs =>
      auditLogs.where((l) => l.isTamperFlag || l.severity != AuditSeverity.info).toList();

  ShiftAuditState copyWith({
    ShiftRecord? currentShift,
    List<ShiftRecord>? shiftHistory,
    List<AuditLogEvent>? auditLogs,
    bool? isLoading,
    ShiftRecord? lastAuditedShift,
    String? alertMessage,
    bool clearCurrentShift = false,
  }) {
    return ShiftAuditState(
      currentShift: clearCurrentShift ? null : (currentShift ?? this.currentShift),
      shiftHistory: shiftHistory ?? this.shiftHistory,
      auditLogs: auditLogs ?? this.auditLogs,
      isLoading: isLoading ?? this.isLoading,
      lastAuditedShift: lastAuditedShift ?? this.lastAuditedShift,
      alertMessage: alertMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentShift,
        shiftHistory,
        auditLogs,
        isLoading,
        lastAuditedShift,
        alertMessage,
      ];
}

// BLoC
class ShiftAuditBloc extends Bloc<ShiftAuditEvent, ShiftAuditState> {
  final IShiftRepository _shiftRepo;
  final IAuditRepository _auditRepo;
  StreamSubscription<ShiftRecord?>? _shiftSub;
  StreamSubscription<List<AuditLogEvent>>? _auditSub;

  ShiftAuditBloc({
    required IShiftRepository shiftRepo,
    required IAuditRepository auditRepo,
  })  : _shiftRepo = shiftRepo,
        _auditRepo = auditRepo,
        super(const ShiftAuditState(isLoading: true)) {
    on<LoadShiftAuditEvent>(_onLoadShiftAudit);
    on<_CurrentShiftUpdatedEvent>(_onCurrentShiftUpdated);
    on<_AuditLogsUpdatedEvent>(_onAuditLogsUpdated);
    on<StartNewShiftEvent>(_onStartNewShift);
    on<CloseShiftHandoverEvent>(_onCloseShiftHandover);
  }

  Future<void> _onLoadShiftAudit(LoadShiftAuditEvent event, Emitter<ShiftAuditState> emit) async {
    await _shiftSub?.cancel();
    await _auditSub?.cancel();

    _shiftSub = _shiftRepo.watchCurrentShift(event.branchId).listen((shift) {
      add(_CurrentShiftUpdatedEvent(shift));
    });

    _auditSub = _auditRepo.watchAuditLogs(event.branchId).listen((logs) {
      add(_AuditLogsUpdatedEvent(logs));
    });

    final currentShift = await _shiftRepo.getCurrentShift(event.branchId);
    final history = await _shiftRepo.getShiftHistory(event.branchId);
    final logs = await _auditRepo.getAuditLogs(event.branchId);

    emit(state.copyWith(
      currentShift: currentShift,
      shiftHistory: history,
      auditLogs: logs,
      isLoading: false,
    ));
  }

  void _onCurrentShiftUpdated(_CurrentShiftUpdatedEvent event, Emitter<ShiftAuditState> emit) {
    emit(state.copyWith(currentShift: event.shift, clearCurrentShift: event.shift == null));
  }

  void _onAuditLogsUpdated(_AuditLogsUpdatedEvent event, Emitter<ShiftAuditState> emit) {
    emit(state.copyWith(auditLogs: event.logs));
  }

  Future<void> _onStartNewShift(StartNewShiftEvent event, Emitter<ShiftAuditState> emit) async {
    await _shiftRepo.startShift(event.shift);
  }

  Future<void> _onCloseShiftHandover(CloseShiftHandoverEvent event, Emitter<ShiftAuditState> emit) async {
    final closed = await _shiftRepo.closeShiftHandover(
      shiftId: event.shiftId,
      countedPhysicalCash: event.countedPhysicalCash,
      closingNotes: event.closingNotes,
    );
    final history = await _shiftRepo.getShiftHistory(closed.branchId);
    final isMismatch = (closed.varianceAmount ?? 0.0).abs() > 0.01;

    emit(state.copyWith(
      clearCurrentShift: true,
      lastAuditedShift: closed,
      shiftHistory: history,
      alertMessage: isMismatch
          ? 'Mandatory Handover Flagged! Cash discrepancy of ₹${closed.varianceAmount!.abs().toStringAsFixed(2)} logged to Owner.'
          : 'Shift closed with zero cash variance. Handover approved.',
    ));
  }

  @override
  Future<void> close() {
    _shiftSub?.cancel();
    _auditSub?.cancel();
    return super.close();
  }
}
