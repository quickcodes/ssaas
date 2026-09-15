import '../../domain/entities/equipment_item.dart';
import '../../domain/repositories/i_equipment_repository.dart';
import '../datasources/local_data_store.dart';

class EquipmentRepositoryImpl implements IEquipmentRepository {
  final LocalDataStore _ds;
  EquipmentRepositoryImpl(this._ds);

  @override
  Stream<List<EquipmentItem>> watchEquipmentItems(String branchId) =>
      _ds.watchEquipmentItems(branchId);

  @override
  Future<List<EquipmentItem>> getEquipmentItems(String branchId) async =>
      _ds.getEquipmentItems(branchId);

  @override
  Future<void> saveEquipmentItem(EquipmentItem item) async =>
      _ds.saveEquipmentItem(item);

  @override
  Future<void> recordPlayingHours(String tableId, double hours) async {
    _ds.recordEquipmentWear(tableId, hours);
  }

  @override
  Future<void> recordSessionPlayed(String tableId) async {}

  @override
  Future<void> logMaintenanceDone(String equipmentId, {String? notes}) async {
    _ds.logEquipmentMaintenanceDone(equipmentId, notes: notes);
  }

  @override
  Future<void> replenishChalk(String branchId, int addedUnits) async {
    final chalk = _ds
        .getEquipmentItems(branchId)
        .firstWhere((e) => e.type == EquipmentType.chalkBlock);
    _ds.logEquipmentMaintenanceDone(
      chalk.id,
      notes: 'Replenished $addedUnits chalk units',
    );
  }

  @override
  Future<void> issueChalk(String branchId, int issuedUnits) async {}
}
