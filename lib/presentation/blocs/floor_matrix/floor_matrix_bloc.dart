import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/club_reminder.dart';
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

class DeleteTableEvent extends FloorMatrixEvent {
  final String companyId;
  final String tableId;
  final String tableName;

  const DeleteTableEvent({
    required this.companyId,
    required this.tableId,
    required this.tableName,
  });

  @override
  List<Object?> get props => [companyId, tableId, tableName];
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

class _RemindersUpdatedEvent extends FloorMatrixEvent {
  final List<ClubReminder> reminders;
  const _RemindersUpdatedEvent(this.reminders);
  @override
  List<Object?> get props => [reminders];
}

class AddReminderEvent extends FloorMatrixEvent {
  final String companyId;
  final ClubReminder reminder;
  const AddReminderEvent({required this.companyId, required this.reminder});
  @override
  List<Object?> get props => [companyId, reminder];
}

class DismissReminderEvent extends FloorMatrixEvent {
  final String companyId;
  final String reminderId;
  const DismissReminderEvent({
    required this.companyId,
    required this.reminderId,
  });
  @override
  List<Object?> get props => [companyId, reminderId];
}

class DeleteReminderEvent extends FloorMatrixEvent {
  final String companyId;
  final String reminderId;
  const DeleteReminderEvent({
    required this.companyId,
    required this.reminderId,
  });
  @override
  List<Object?> get props => [companyId, reminderId];
}

class ClearFloorMatrixMessagesEvent extends FloorMatrixEvent {
  const ClearFloorMatrixMessagesEvent();
}

// -------------------------------------------------------------
// STATE
// -------------------------------------------------------------

class FloorMatrixState extends Equatable {
  final List<ClubTable> tables;
  final List<TableSession> activeSessions;
  final List<ClubReminder> reminders;
  final ClubTable? selectedTable;
  final TableStatus? filterStatus;
  final DateTime currentTickerTime;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const FloorMatrixState({
    this.tables = const [],
    this.activeSessions = const [],
    this.reminders = const [],
    this.selectedTable,
    this.filterStatus,
    required this.currentTickerTime,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Reminders whose remindAt is within 1 hour ahead from now
  /// and not dismissed or expired
  List<ClubReminder> get activeUpcomingReminders {
    final now = currentTickerTime;
    return reminders
        .where((r) => r.isDueSoon(now))
        .toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
  }

  List<ClubTable> get filteredTables {
    final sorted = List<ClubTable>.from(tables)
      ..sort((a, b) => AppFormatters.naturalCompare(a.name, b.name));
    if (filterStatus == null) return sorted;
    return sorted.where((t) => t.status == filterStatus).toList();
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
    List<ClubReminder>? reminders,
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
      reminders: reminders ?? this.reminders,
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
        reminders,
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
  StreamSubscription<List<ClubReminder>>? _remindersSub;
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
    on<_RemindersUpdatedEvent>(_onRemindersUpdated);
    on<TimerTickEvent>(_onTimerTick);
    on<TableSelectedEvent>(_onTableSelected);
    on<FilterStatusChangedEvent>(_onFilterStatusChanged);
    on<CreateTableEvent>(_onCreateTable);
    on<SaveTableConfigurationEvent>(_onSaveTableConfiguration);
    on<DeleteTableEvent>(_onDeleteTable);
    on<StartTableSessionEvent>(_onStartTableSession);
    on<PauseTableSessionEvent>(_onPauseTableSession);
    on<ResumeTableSessionEvent>(_onResumeTableSession);
    on<AddBillingItemEvent>(_onAddBillingItem);
    on<CloseTableSessionEvent>(_onCloseTableSession);
    on<UpdateTableStatusDirectEvent>(_onUpdateTableStatusDirect);
    on<AddReminderEvent>(_onAddReminder);
    on<DismissReminderEvent>(_onDismissReminder);
    on<DeleteReminderEvent>(_onDeleteReminder);
    on<ClearFloorMatrixMessagesEvent>(_onClearMessages);

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
    await _remindersSub?.cancel();

    _tablesSub = _firestoreService.watchTables(event.companyId).listen((tables) {
      add(_TablesUpdatedEvent(tables));
    });

    _sessionsSub =
        _firestoreService.watchRunningTables(event.companyId).listen((sessions) {
      add(_SessionsUpdatedEvent(sessions));
    });

    _remindersSub = _firestoreService
        .watchCompanyReminders(event.companyId)
        .listen((reminders) {
      add(_RemindersUpdatedEvent(reminders));
    });

    try {
      final tables = await _firestoreService.getTables(event.companyId);
      final sortedTables = List<ClubTable>.from(tables)
        ..sort((a, b) => AppFormatters.naturalCompare(a.name, b.name));
      emit(state.copyWith(tables: sortedTables, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onTablesUpdated(
    _TablesUpdatedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    final sortedTables = List<ClubTable>.from(event.tables)
      ..sort((a, b) => AppFormatters.naturalCompare(a.name, b.name));
    emit(state.copyWith(tables: sortedTables, isLoading: false));
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
      emit(state.copyWith(successMessage: 'Table "${event.table.name}" updated.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteTable(
    DeleteTableEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.deleteTable(event.companyId, event.tableId);
      emit(state.copyWith(successMessage: 'Table "${event.tableName}" deleted successfully.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete table: $e'));
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

  void _onRemindersUpdated(
    _RemindersUpdatedEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(state.copyWith(reminders: event.reminders));
  }

  Future<void> _onAddReminder(
    AddReminderEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.saveReminder(event.companyId, event.reminder);
      emit(state.copyWith(successMessage: 'Reminder saved successfully'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDismissReminder(
    DismissReminderEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.dismissReminder(
        event.companyId,
        event.reminderId,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminderEvent event,
    Emitter<FloorMatrixState> emit,
  ) async {
    try {
      await _firestoreService.deleteReminder(
        event.companyId,
        event.reminderId,
      );
      emit(state.copyWith(successMessage: 'Reminder deleted'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onClearMessages(
    ClearFloorMatrixMessagesEvent event,
    Emitter<FloorMatrixState> emit,
  ) {
    emit(state.copyWith(clearMessages: true));
  }

  @override
  Future<void> close() {
    _tablesSub?.cancel();
    _sessionsSub?.cancel();
    _remindersSub?.cancel();
    _tickerTimer?.cancel();
    return super.close();
  }
}
