import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/equipment_item.dart';
import '../../../domain/repositories/i_equipment_repository.dart';

// Events
abstract class EquipmentEvent extends Equatable {
  const EquipmentEvent();
  @override
  List<Object?> get props => [];
}

class LoadEquipmentEvent extends EquipmentEvent {
  final String branchId;
  const LoadEquipmentEvent(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class _EquipmentUpdatedEvent extends EquipmentEvent {
  final List<EquipmentItem> items;
  const _EquipmentUpdatedEvent(this.items);
  @override
  List<Object?> get props => [items];
}

class FilterEquipmentTypeEvent extends EquipmentEvent {
  final EquipmentType? type;
  const FilterEquipmentTypeEvent(this.type);
  @override
  List<Object?> get props => [type];
}

class LogEquipmentMaintenanceAction extends EquipmentEvent {
  final String equipmentId;
  final String? notes;
  const LogEquipmentMaintenanceAction({required this.equipmentId, this.notes});
  @override
  List<Object?> get props => [equipmentId, notes];
}

class ReplenishChalkAction extends EquipmentEvent {
  final String branchId;
  final int count;
  const ReplenishChalkAction({required this.branchId, required this.count});
  @override
  List<Object?> get props => [branchId, count];
}

class SaveEquipmentItemEvent extends EquipmentEvent {
  final EquipmentItem item;
  const SaveEquipmentItemEvent(this.item);
  @override
  List<Object?> get props => [item];
}

// State
class EquipmentState extends Equatable {
  final List<EquipmentItem> items;
  final EquipmentType? selectedType;
  final bool isLoading;
  final String? actionSuccess;

  const EquipmentState({
    this.items = const [],
    this.selectedType,
    this.isLoading = false,
    this.actionSuccess,
  });

  List<EquipmentItem> get filteredItems {
    if (selectedType == null) return items;
    return items.where((e) => e.type == selectedType).toList();
  }

  int get alertCount =>
      items.where((e) => e.alertStatus != EquipmentAlertStatus.normal).length;

  EquipmentState copyWith({
    List<EquipmentItem>? items,
    EquipmentType? selectedType,
    bool? isLoading,
    String? actionSuccess,
    bool clearType = false,
  }) {
    return EquipmentState(
      items: items ?? this.items,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      isLoading: isLoading ?? this.isLoading,
      actionSuccess: actionSuccess,
    );
  }

  @override
  List<Object?> get props => [items, selectedType, isLoading, actionSuccess];
}

// BLoC
class EquipmentBloc extends Bloc<EquipmentEvent, EquipmentState> {
  final IEquipmentRepository _equipmentRepo;
  StreamSubscription<List<EquipmentItem>>? _sub;

  EquipmentBloc({required IEquipmentRepository equipmentRepo})
    : _equipmentRepo = equipmentRepo,
      super(const EquipmentState(isLoading: true)) {
    on<LoadEquipmentEvent>(_onLoadEquipment);
    on<_EquipmentUpdatedEvent>(_onEquipmentUpdated);
    on<FilterEquipmentTypeEvent>(_onFilterType);
    on<LogEquipmentMaintenanceAction>(_onLogMaintenance);
    on<ReplenishChalkAction>(_onReplenishChalk);
    on<SaveEquipmentItemEvent>(_onSaveItem);
  }

  Future<void> _onLoadEquipment(
    LoadEquipmentEvent event,
    Emitter<EquipmentState> emit,
  ) async {
    await _sub?.cancel();
    _sub = _equipmentRepo.watchEquipmentItems(event.branchId).listen((items) {
      add(_EquipmentUpdatedEvent(items));
    });
    final items = await _equipmentRepo.getEquipmentItems(event.branchId);
    emit(state.copyWith(items: items, isLoading: false));
  }

  void _onEquipmentUpdated(
    _EquipmentUpdatedEvent event,
    Emitter<EquipmentState> emit,
  ) {
    emit(state.copyWith(items: event.items));
  }

  void _onFilterType(
    FilterEquipmentTypeEvent event,
    Emitter<EquipmentState> emit,
  ) {
    emit(
      state.copyWith(selectedType: event.type, clearType: event.type == null),
    );
  }

  Future<void> _onLogMaintenance(
    LogEquipmentMaintenanceAction event,
    Emitter<EquipmentState> emit,
  ) async {
    await _equipmentRepo.logMaintenanceDone(
      event.equipmentId,
      notes: event.notes,
    );
    emit(
      state.copyWith(
        actionSuccess: 'Maintenance cycle recorded and alert cleared!',
      ),
    );
  }

  Future<void> _onReplenishChalk(
    ReplenishChalkAction event,
    Emitter<EquipmentState> emit,
  ) async {
    await _equipmentRepo.replenishChalk(event.branchId, event.count);
    emit(
      state.copyWith(
        actionSuccess: 'Chalk stock replenished by ${event.count} units!',
      ),
    );
  }

  Future<void> _onSaveItem(
    SaveEquipmentItemEvent event,
    Emitter<EquipmentState> emit,
  ) => _equipmentRepo.saveEquipmentItem(event.item);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
