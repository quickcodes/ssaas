---
name: cueclub-stock-and-canteen
description: >-
  Workflows, domain models, and UI patterns for managing food canteen inventory, beverages, snacks, snooker equipment stock, cue maintenance, and ordering items to live table sessions. Use when modifying or debugging canteen menus, stock counts, equipment tracking, or table item dialogs in CueClub OS.
---

# CueClub Canteen & Equipment Stock Management

This skill documents the canteen POS, inventory tracking, equipment maintenance, and stock integration with table billing in CueClub OS.

## 1. Domain Entities & Firestore Structure

### A. Food Canteen (`companies/{companyId}/canteenItems/{itemId}`)
- **`CanteenItem`**:
  - `id`: Unique UUID.
  - `name`: Food or beverage name (e.g. "Cold Coffee", "Sandwich", "Mineral Water").
  - `category`: `'Beverages'`, `'Snacks'`, `'Meals'`, `'Others'`.
  - `price`: Unit sale price in ₹.
  - `stock`: Current units in stock.
  - `isAvailable`: Quick toggle to mark sold-out items.

### B. Equipment & Club Stock (`companies/{companyId}/equipmentItems/{itemId}`)
- **`EquipmentItem`**:
  - `id`: Unique UUID.
  - `name`: Equipment asset name (e.g. "Master Chalk (Blue)", "Aramith Tournament Balls", "Cue Tip 10mm").
  - `quantity`: Quantity currently in possession or storage.
  - `condition`: `'Excellent'`, `'Good'`, `'Needs Maintenance'`, or `'Replaced'`.
  - `unitCost`: Procurement cost.
  - `notes`: Maintenance or storage log notes.

---

## 2. Food & Canteen POS Operations

In `FoodCanteenView` (`lib/presentation/views/canteen/food_canteen_view.dart`):
- Category filter tabs: All, Beverages, Snacks, Meals, Others.
- Stock increment/decrement shortcuts with immediate Firestore updates.
- Real-time Firestore stream listener updates all connected terminals instantaneously.
- Low-stock visual warning badges when inventory falls below minimum threshold.

---

## 3. Equipment & Maintenance Tracking

In `EquipmentStockView` (`lib/presentation/views/equipment/equipment_stock_view.dart`):
- Tracks capital club equipment (cues, balls, table heaters, cloth).
- Add/Edit modal with name, stock quantity, condition rating, and notes.
- Quick filtering by condition and stock availability.

---

## 4. Cross-Module Integration with Table Sessions

When items are sold directly to a table:
1. Staff tap **"+ Item / Snacks"** on a running table card or in `FloorMatrixView`.
2. `AddTableItemDialog` displays active `CanteenItem`s with stock counts.
3. Upon selecting quantity and tapping "Add to Table", `AddSessionBillingItemEvent` is dispatched to `FloorMatrixBloc`.
4. The item is embedded inside `table.currentSession.items` and immediately increases `itemsAmount` and `grandTotal`.
5. At checkout, itemized lines appear in the bill breakdown and persist into `TableHistoryRecord`.
