import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/repositories/i_club_repository.dart';

// Events
abstract class FloorMatrixEvent extends Equatable {
  const FloorMatrixEvent();
  @override
  List<Object?> get props => [];
}

class LoadFloorMatrixEvent extends FloorMatrixEvent {
  final String branchId;
  const LoadFloorMatrixEvent(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class _TablesUpdatedEvent extends FloorMatrixEvent {
  final List<ClubTable> tables;
  const _TablesUpdatedEvent(this.tables);
  @override
  List<Object?> get props => [tables];
}

class _SessionsUpdatedEvent extends FloorMatrixEvent {
  final List<TableSession> sessions;
  const _SessionsUpdatedEvent(this.sessions);
  @override
  List<Object?> get props => [sessions];
}

class TimerTickEvent extends FloorMatrixEvent {
  final DateTime now;
  const TimerTickEvent(this.now);
  @override
  List<Object?> get props => [now];
}

class TableSelectedEvent extends FloorMatrixEvent {
  final ClubTable? table;
  const TableSelectedEvent(this.table);
  @override
  List<Object?> get props => [table];
}

class FilterStatusChangedEvent extends FloorMatrixEvent {
  final TableStatus? status;
  const FilterStatusChangedEvent(this.status);
  @override
  List<Object?> get props => [status];
}

class StartTableSessionEvent extends FloorMatrixEvent {
  final TableSession session;
  const StartTableSessionEvent(this.session);
  @override
  List<Object?> get props => [session];
}

class PauseTableSessionEvent extends FloorMatrixEvent {
  final String sessionId;
  const PauseTableSessionEvent(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class ResumeTableSessionEvent extends FloorMatrixEvent {
  final String sessionId;
  const ResumeTableSessionEvent(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class CompleteTableSessionEvent extends FloorMatrixEvent {
  final String sessionId;
  final PaymentMethod paymentMethod;
  final double finalTableAmount;
  final double finalTotalAmount;

  const CompleteTableSessionEvent({
    required this.sessionId,
    required this.paymentMethod,
    required this.finalTableAmount,
    required this.finalTotalAmount,
  });

  @override
  List<Object?> get props => [
    sessionId,
    paymentMethod,
    finalTableAmount,
    finalTotalAmount,
  ];
}

class CancelTableSessionEvent extends FloorMatrixEvent {
  final String sessionId;
  final String reason;
  final String operatorId;

  const CancelTableSessionEvent({
    required this.sessionId,
    required this.reason,
    required this.operatorId,
  });

  @override
  List<Object?> get props => [sessionId, reason, operatorId];
}

class UpdateTableStatusDirectEvent extends FloorMatrixEvent {
  final String tableId;
  final TableStatus status;
  const UpdateTableStatusDirectEvent(this.tableId, this.status);
  @override
  List<Object?> get props => [tableId, status];
}

class SaveTableConfigurationEvent extends FloorMatrixEvent {
  final ClubTable table;
  const SaveTableConfigurationEvent(this.table);
  @override
  List<Object?> get props => [table];
}

// State
class FloorMatrixState extends Equatable {
  final List<ClubTable> tables;
  final List<TableSession> activeSessions;
  final ClubTable? selectedTable;
  final TableStatus? filterStatus;
  final DateTime currentTickerTime;
  final bool isLoading;
  final String? errorMessage;

  const FloorMatrixState({
    this.tables = const [],
    this.activeSessions = const [],
    this.selectedTable,
    this.filterStatus,
    required this.currentTickerTime,
    this.isLoading = false,
    this.errorMessage,
  });

  List<ClubTable> get filteredTables {
    if (filterStatus == null) return tables;
    return tables.where((t) => t.status == filterStatus).toList();
  }

  TableSession? getSessionForTable(String tableId) {
    try {
      return activeSessions.firstWhere((s) => s.tableId == tableId);
    } catch (_) {
      return null;
    }
  }

  FloorMatrixState copyWith({
    List<ClubTable>? tables,
    List<TableSession>? activeSessions,
    ClubTable? selectedTable,
    TableStatus? filterStatus,
    DateTime? currentTickerTime,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedTable = false,
    bool clearFilter = false,
  }) {
    return FloorMatrixState(
      tables: tables ?? this.tables,
      activeSessions: activeSessions ?? this.activeSessions,
      selectedTable: clearSelectedTable
          ? null
          : (selectedTable ?? this.selectedTable),
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      currentTickerTime: currentTickerTime ?? this.currentTickerTime,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    tables,
    activeSessions,
    selectedTable,
    filterStatus,
    currentTickerTime,
    isLoading,
    errorMessage,
  ];
}

// BLoC
class FloorMatrixBloc extends Bloc<FloorMatrixEvent, FloorMatrixState> {
  final IClubRepository _clubRepo;
  StreamSubscription<List<ClubTable>>? _tablesSub;
  StreamSubscription<List<TableSession>>? _sessionsSub;
  Timer? _tickerTimer;

  FloorMatrixBloc({required IClubRepository clubRepo})
    : _clubRepo = clubRepo,
      super(
        FloorMatrixState(currentTickerTime: DateTime.now(), isLoading: true),
      ) {
    on<LoadFloorMatrixEvent>(_onLoadFloorMatrix);
    on<_TablesUpdatedEvent>(_onTablesUpdated);
    on<_SessionsUpdatedEvent>(_onSessionsUpdated);
    on<TimerTickEvent>(_onTimerTick);
    on<TableSelectedEvent>(_onTableSelected);
    on<FilterStatusChangedEvent>(_onFilterStatusChanged);
    on<StartTableSessionEvent>(_onStartTableSession);
    on<PauseTableSessionEvent>(_onPauseTableSession);
    on<ResumeTableSessionEvent>(_onResumeTableSession);
    on<CompleteTableSessionEvent>(_onCompleteTableSession);
    on<CancelTableSessionEvent>(_onCancelTableSession);
    on<UpdateTableStatusDirectEvent>(_onUpdateTableStatusDirect);
    on<SaveTableConfigurationEvent>(_onSaveTableConfiguration);

    // Periodic 1-second timer tick for live dynamic clocks
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(TimerTickEvent(DateTime.now()));
    });
  }

  Future<void> _onLoadFloorMatrix(
    LoadFloorMatrixEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    await _tablesSub?.cancel();
    await _sessionsSub?.cancel();

    _tablesSub = _clubRepo.watchTables(event.branchId).listen((tables) {
      add(_TablesUpdatedEvent(tables));
    });

    _sessionsSub = _clubRepo.watchActiveSessions(event.branchId).listen((
      sessions,
    ) {
      add(_SessionsUpdatedEvent(sessions));
    });

    final tables = await _clubRepo.getTables(event.branchId);
    emit(state.copyWith(tables: tables, isLoading: false));
  }

  void _onTablesUpdated(
    _TablesUpdatedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(state.copyWith(tables: event.tables));
  }

  void _onSessionsUpdated(
    _SessionsUpdatedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(state.copyWith(activeSessions: event.sessions));
  }

  void _onTimerTick(TimerTickEvent event, Emitter<FloorMatrixState> emit) {
    emit(state.copyWith(currentTickerTime: event.now));
  }

  void _onTableSelected(
    TableSelectedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(state.copyWith(selectedTable: event.table));
  }

  void _onFilterStatusChanged(
    FilterStatusChangedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(
      state.copyWith(
        filterStatus: event.status,
        clearFilter: event.status == null,
      ),
    );
  }

  Future<void> _onStartTableSession(
    StartTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    await _clubRepo.startSession(event.session);
  }

  Future<void> _onPauseTableSession(
    PauseTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    await _clubRepo.pauseSession(event.sessionId);
  }

  Future<void> _onResumeTableSession(
    ResumeTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    await _clubRepo.resumeSession(event.sessionId);
  }

  Future<void> _onCompleteTableSession(
    CompleteTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    await _clubRepo.completeSession(
      event.sessionId,
      event.paymentMethod,
      event.finalTableAmount,
      event.finalTotalAmount,
    );
  }

  Future<void> _onCancelTableSession(
    CancelTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    await _clubRepo.cancelOrDeleteSession(
      event.sessionId,
      event.reason,
      event.operatorId,
    );
  }

  Future<void> _onUpdateTableStatusDirect(
    UpdateTableStatusDirectEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    await _clubRepo.updateTableStatus(event.tableId, event.status);
  }

  Future<void> _onSaveTableConfiguration(
    SaveTableConfigurationEvent event,
    Emitter<FloorMatrixState> emit,
  ) => _clubRepo.saveTable(event.table);

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    _tablesSub?.cancel();
    _sessionsSub?.cancel();
    return super.close();
  }
}
