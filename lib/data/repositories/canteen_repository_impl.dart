import '../../domain/entities/canteen_item.dart';
import '../../domain/entities/tab_order_item.dart';
import '../../domain/repositories/i_canteen_repository.dart';
import '../datasources/local_data_store.dart';

class CanteenRepositoryImpl implements ICanteenRepository {
  final LocalDataStore _ds;
  CanteenRepositoryImpl(this._ds);

  @override
  Stream<List<CanteenItem>> watchCanteenItems(String branchId) =>
      _ds.watchCanteenItems(branchId);

  @override
  Future<List<CanteenItem>> getCanteenItems(String branchId) async =>
      _ds.getCanteenItems(branchId);

  @override
  Future<CanteenItem?> getItemById(String itemId) async {
    try {
      return _ds.getCanteenItems('branch-1').firstWhere((i) => i.id == itemId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveItem(CanteenItem item) async => _ds.saveCanteenItem(item);

  @override
  Future<void> deductStock(String itemId, int quantity) async {
    _ds.deductCanteenStock(itemId, quantity);
  }

  @override
  Future<void> restockItem(String itemId, int quantity) async {
    _ds.restockCanteenItem(itemId, quantity);
  }

  @override
  Stream<List<TabOrderItem>> watchSessionTabItems(String sessionId) {
    // Return stream filtered for session
    return Stream.fromFuture(getSessionTabItems(sessionId));
  }

  @override
  Future<List<TabOrderItem>> getSessionTabItems(String sessionId) async {
    return _ds.getSessionTabItems(sessionId);
  }

  @override
  Future<List<TabOrderItem>> getAllSalesHistory(
    String branchId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _ds.getAllSalesHistory(branchId);
  }

  @override
  Future<void> addTabOrderItem(TabOrderItem orderItem) async {
    _ds.addTabOrderItem(orderItem);
  }
}
