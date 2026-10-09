---
name: ssaas-stock-and-canteen
description: >-
  Workflows, domain models, and UI patterns for managing food canteen inventory, beverages, snacks, snooker equipment stock, cue maintenance, and ordering items to live table sessions. Use when modifying or debugging canteen menus, stock counts, equipment tracking, or table item dialogs in SSAAS (Constants.appName).
---

# SSAAS Canteen & Equipment Stock Management

This skill documents the canteen POS, inventory tracking, equipment maintenance, and stock integration with table billing in SSAAS (`Constants.appName`).

## 1. Domain Entities & Firestore Structure

Both food canteen and equipment items use the `StockItem` entity (`lib/domain/entities/stock_item.dart`).

### A. Food Canteen (`companies/{companyId}/foodCanteen/{itemId}`)

- **`StockItem`** fields for food:
  - `id`: Unique UUID.
  - `companyId`: Parent club ID.
  - `name`: Food or beverage name (e.g. "Cold Coffee", "Sandwich", "Water Bottle").
  - `category`: `'Beverages'`, `'Snacks'`, `'Meals'`, `'Others'`.
  - `price`: Unit sale price in ₹.
  - `stock`: Current units available in inventory.
  - `unit`: Measurement unit (`'pcs'`, `'bottles'`, `'plates'`).
  - `isAvailable`: Quick availability toggle.

### B. Equipment & Club Stock (`companies/{companyId}/equipmentStock/{itemId}`)

- **`StockItem`** fields for equipment:
  - `id`: Unique UUID.
  - `companyId`: Parent club ID.
  - `name`: Asset name (e.g. "Master Chalk (Blue)", "Aramith Ball Set", "Cue Tip 10mm").
  - `category`: `'Cues'`, `'Balls'`, `'Chalk'`, `'Cloth'`, `'Lighting'`, `'Maintenance'`.
  - `stock`: Current quantity in possession or storage.
  - `condition`: `'Excellent'`, `'Good'`, `'Needs Maintenance'`, or `'Replaced'`.
  - `unitCost`: Procurement cost.
  - `notes`: Maintenance log notes.

---

## 2. Food & Canteen POS Operations

In `FoodCanteenView` (`lib/presentation/views/canteen/food_canteen_view.dart`):

- Category tabs: All, Beverages, Snacks, Meals, Others.
- Stock adjustment: Increment (`incrementFoodStock`) or Decrement (`decrementFoodStock`) shortcuts in `FirestoreService` update Firestore in real-time.
- Real-time Stream: `_firestoreService.watchFoodCanteen(companyId)` broadcasts live stock updates across all active club devices.
- Low-Stock Badges: Visual warnings displayed when inventory drops below 5 units.

---

## 3. Equipment & Maintenance Tracking

In `EquipmentStockView` (`lib/presentation/views/equipment/equipment_stock_view.dart`):

- Capital asset tracking (cues, ball sets, heaters, cloth, lighting).
- Add/Edit modal via `AddEditEquipmentItemScreen` (`lib/presentation/views/equipment/add_edit_equipment_item_screen.dart`).
- Track stock counts, asset condition ratings, unit procurement costs, and maintenance logs.

---

## 4. Integration with Running Table Sessions

When canteen items are added directly to a running match:

1. Operator taps **"+ Add Item"** on a running table card in `FloorMatrixView` or inside `ManageTableItemsDialog`.
2. `AddTableItemDialog` lists active food items from `watchFoodCanteen`.
3. Tapping "Add to Table" dispatches `AddBillingItemEvent` to `FloorMatrixBloc`:
   - Adds `TableBillingItem` into `session.items`.
   - Calls `_firestoreService.decrementFoodStock(companyId, item.stockItemId, quantity)`.
4. Removing an item from table bill dispatches `RemoveBillingItemEvent`:
   - Removes item from `session.items`.
   - Restores stock count via `_firestoreService.incrementFoodStock(companyId, stockItemId, quantity)`.
