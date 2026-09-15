import '../entities/canteen_item.dart';
import '../entities/tab_order_item.dart';

abstract class ICanteenRepository {
  Stream<List<CanteenItem>> watchCanteenItems(String branchId);
  Future<List<CanteenItem>> getCanteenItems(String branchId);
  Future<CanteenItem?> getItemById(String itemId);
  Future<void> saveItem(CanteenItem item);
  Future<void> deductStock(String itemId, int quantity);
  Future<void> restockItem(String itemId, int quantity);

  Stream<List<TabOrderItem>> watchSessionTabItems(String sessionId);
  Future<List<TabOrderItem>> getSessionTabItems(String sessionId);
  Future<List<TabOrderItem>> getAllSalesHistory(String branchId, {DateTime? startDate, DateTime? endDate});
  Future<void> addTabOrderItem(TabOrderItem orderItem);
}
