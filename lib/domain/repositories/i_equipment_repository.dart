import '../entities/equipment_item.dart';

abstract class IEquipmentRepository {
  Stream<List<EquipmentItem>> watchEquipmentItems(String branchId);
  Future<List<EquipmentItem>> getEquipmentItems(String branchId);
  Future<void> saveEquipmentItem(EquipmentItem item);
  Future<void> recordPlayingHours(String tableId, double hours);
  Future<void> recordSessionPlayed(String tableId);
  Future<void> logMaintenanceDone(String equipmentId, {String? notes});
  Future<void> replenishChalk(String branchId, int addedUnits);
  Future<void> issueChalk(String branchId, int issuedUnits);
}
