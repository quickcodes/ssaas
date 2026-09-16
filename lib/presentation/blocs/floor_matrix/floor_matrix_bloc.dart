import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_billing_item.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../../domain/entities/table_session.dart';

// -------------------------------------------------------------
// EVENTS
// -------------------------------------------------------------

abstract class FloorMatrixEvent extends Equatable {
  const FloorMatrixEvent();
  @override
  List<Object?> get props => [];
}

class LoadFloorMatrixEvent extends FloorMatrixEvent {
  final String companyId;
  const LoadFloorMatrixEvent(this.companyId);
  @override
  List<Object?> get props => [companyId];
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

class CreateTableEvent extends FloorMatrixEvent {
  final ClubTable table;
  const CreateTableEvent(this.table);
  @override
  List<Object?> get props => [table];
}

class SaveTableConfigurationEvent extends FloorMatrixEvent {
  final ClubTable table;
  const SaveTableConfigurationEvent(this.table);
  @override
  List<Object?> get props => [table];
}

class StartTableSessionEvent extends FloorMatrixEvent {
  final TableSession session;
  const StartTableSessionEvent(this.session);
  @override
  List<Object?> get props => [session];
}

class PauseTableSessionEvent extends FloorMatrixEvent {
  final String companyId;
  final String sessionId;
  const PauseTableSessionEvent(this.companyId, this.sessionId);
  @override
  List<Object?> get props => [companyId, sessionId];
}

class ResumeTableSessionEvent extends FloorMatrixEvent {
  final String companyId;
  final String sessionId;
  const ResumeTableSessionEvent(this.companyId, this.sessionId);
  @override
  List<Object?> get props => [companyId, sessionId];
}

class AddBillingItemEvent extends FloorMatrixEvent {
  final String companyId;
  final String sessionId;
  final TableBillingItem item;
  const AddBillingItemEvent({
    required this.companyId,
    required this.sessionId,
    required this.item,
  });
  @override
  List<Object?> get props => [companyId, sessionId, item];
}

class CloseTableSessionEvent extends FloorMatrixEvent {
  final String companyId;
  final String sessionId;
  final TableHistoryRecord historyRecord;

  const CloseTableSessionEvent({
    required this.companyId,
    required this.sessionId,
    required this.historyRecord,
  });

  @override
  List<Object?> get props => [companyId, sessionId, historyRecord];
}

class UpdateTableStatusDirectEvent extends FloorMatrixEvent {
  final String companyId;
  final String tableId;
  final TableStatus status;
  const UpdateTableStatusDirectEvent(this.companyId, this.tableId, this.status);
  @override
  List<Object?> get props => [companyId, tableId, status];
}

// -------------------------------------------------------------
// STATE
// -------------------------------------------------------------

class FloorMatrixState extends Equatable {
  final List<ClubTable> tables;
  final List<TableSession> activeSessions;
  final ClubTable? selectedTable;
  final TableStatus? filterStatus;
  final DateTime currentTickerTime;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const FloorMatrixState({
    this.tables = const [],
    this.activeSessions = const [],
    this.selectedTable,
    this.filterStatus,
    required this.currentTickerTime,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
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
    String? successMessage,
    bool clearSelectedTable = false,
    bool clearFilter = false,
    bool clearMessages = false,
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
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
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
        successMessage,
      ];
}

// -------------------------------------------------------------
// BLOC
// -------------------------------------------------------------

class FloorMatrixBloc extends Bloc<FloorMatrixEvent, FloorMatrixState> {
  final FirestoreService _firestoreService;
  StreamSubscription<List<ClubTable>>? _tablesSub;
  StreamSubscription<List<TableSession>>? _sessionsSub;
  Timer? _tickerTimer;

  FloorMatrixBloc({required FirestoreService firestoreService})
      : _firestoreService = firestoreService,
        super(
          FloorMatrixState(
            currentTickerTime: DateTime.now(),
            isLoading: true,
          ),
        ) {
    on<LoadFloorMatrixEvent>(_onLoadFloorMatrix);
    on<_TablesUpdatedEvent>(_onTablesUpdated);
    on<_SessionsUpdatedEvent>(_onSessionsUpdated);
    on<TimerTickEvent>(_onTimerTick);
    on<TableSelectedEvent>(_onTableSelected);
    on<FilterStatusChangedEvent>(_onFilterStatusChanged);
    on<CreateTableEvent>(_onCreateTable);
    on<SaveTableConfigurationEvent>(_onSaveTableConfiguration);
    on<StartTableSessionEvent>(_onStartTableSession);
    on<PauseTableSessionEvent>(_onPauseTableSession);
    on<ResumeTableSessionEvent>(_onResumeTableSession);
    on<AddBillingItemEvent>(_onAddBillingItem);
    on<CloseTableSessionEvent>(_onCloseTableSession);
    on<UpdateTableStatusDirectEvent>(_onUpdateTableStatusDirect);

    // Periodic 1-second timer tick for live dynamic clocks
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(TimerTickEvent(DateTime.now()));
    });
  }

  Future<void> _onLoadFloorMatrix(
    LoadFloorMatrixEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _tablesSub?.cancel();
    await _sessionsSub?.cancel();

    _tablesSub = _firestoreService.watchTables(event.companyId).listen((tables) {
      add(_TablesUpdatedEvent(tables));
    });

    _sessionsSub =
        _firestoreService.watchRunningTables(event.companyId).listen((sessions) {
      add(_SessionsUpdatedEvent(sessions));
    });

    try {
      final tables = await _firestoreService.getTables(event.companyId);
      emit(state.copyWith(tables: tables, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onTablesUpdated(
    _TablesUpdatedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(state.copyWith(tables: event.tables, isLoading: false));
  }

  void _onSessionsUpdated(
    _SessionsUpdatedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(state.copyWith(activeSessions: event.sessions));
  }

  void _onTimerTick(
    TimerTickEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
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
    emit(state.copyWith(filterStatus: event.status, clearFilter: event.status == null));
  }

  Future<void> _onCreateTable(
    CreateTableEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.saveTable(event.table);
      emit(state.copyWith(successMessage: 'Table "${event.table.name}" created.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveTableConfiguration(
    SaveTableConfigurationEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.saveTable(event.table);
      emit(state.copyWith(successMessage: 'Rates for "${event.table.name}" updated.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onStartTableSession(
    StartTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.startSession(event.session);
      emit(
        state.copyWith(
          successMessage:
              'Table "${event.session.tableName}" started for ${event.session.customerName}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onPauseTableSession(
    PauseTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.pauseSession(event.companyId, event.sessionId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onResumeTableSession(
    ResumeTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.resumeSession(event.companyId, event.sessionId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onAddBillingItem(
    AddBillingItemEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.addItemToRunningSession(
        event.companyId,
        event.sessionId,
        event.item,
      );
      // If linked to food canteen item, decrement stock
      if (event.item.stockItemId != null && !event.item.isCustom) {
        await _firestoreService.decrementFoodStock(
          event.companyId,
          event.item.stockItemId!,
          event.item.quantity,
        );
      }
      emit(
        state.copyWith(
          successMessage: 'Added ${event.item.name} to table bill.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onCloseTableSession(
    CloseTableSessionEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.closeSession(
        companyId: event.companyId,
        sessionId: event.sessionId,
        historyRecord: event.historyRecord,
      );
      emit(
        state.copyWith(
          successMessage:
              'Table "${event.historyRecord.tableName}" closed. Status: ${event.historyRecord.paymentStatus}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateTableStatusDirect(
    UpdateTableStatusDirectEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.updateTableStatus(
        event.companyId,
        event.tableId,
        event.status,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _tablesSub?.cancel();
    _sessionsSub?.cancel();
    _tickerTimer?.cancel();
    return super.close();
  }
}
