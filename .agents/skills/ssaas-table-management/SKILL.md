---
name: ssaas-table-management
description: >-
  Workflows, domain models, and business logic for managing snooker/billiards tables, running live matches, adding canteen/stock items to tables, configuring rates, and executing checkout with multi-mode payment settlement. Use when modifying or debugging table sessions, pricing rules, live duration timers, or checkout dialogs in SSAAS (Constants.appName).
---

# SSAAS Table & Live Session Management

This skill documents the table management system, pricing models, running session timers, and checkout procedures in SSAAS (`Constants.appName`).

## 1. Domain Entities & Firestore Structure

Tables and active running sessions are scoped per club/company under Firestore:

- Snooker Tables: `companies/{companyId}/snookerTables/{tableId}`
- Running Sessions: `companies/{companyId}/runningTables/{sessionId}`

### Key Entities

- **`ClubTable`** (`lib/domain/entities/club_table.dart`):
  - `id`, `companyId`, `name`, `type` (Snooker, English Billiards, 8-Ball Pool, 9-Ball Pool).
  - `ratePerHour`: Base hourly rate.
  - `frameRate`: Per-frame billing option.
  - `status`: `TableStatus` enum (`available`, `occupied`, `maintenance`, `reserved`).
  - `currentSessionId`: ID of active `TableSession` when occupied.

- **`TableSession`** (`lib/domain/entities/table_session.dart`):
  - `id`: Session UUID.
  - `companyId`, `tableId`, `tableName`.
  - `customerName`: Initial player/customer who opened the table.
  - `startedByName`: Staff operator who started the table.
  - `startTime`: `DateTime` when match commenced.
  - `pricingType`: Regular hourly, Frame-based, Peak hour, or Fixed slot.
  - `items`: `List<TableBillingItem>` (snacks, beverages, chalk, etc. ordered to table).
  - `isPaused`: Pause toggle boolean.
  - `lastPauseTime`: `DateTime?` timestamp when paused.
  - `pausedSeconds`: Accumulated paused duration in seconds.
  - `itemsAmount`: Computed total of all added billing items.

---

## 2. Rate & Duration Calculation Rules

All time-based calculations use seconds elapsed to prevent timer drift across restarts:

```dart
int playedSeconds = session.playedSecondsAt(now);
int durationMinutes = (playedSeconds / 60).ceil();
```

### Table Charge Calculation:

- **Hourly**: `(playedSeconds / 3600.0) * table.ratePerHour` (subject to minimum charges if configured).
- **Frame-based**: Number of frames multiplied by `table.frameRate`.
- **Grand Total**: `tableCharge + session.itemsAmount`.

---

## 3. Starting a Table Session & Retroactive Start Time

Handled via `StartSessionDialog` (`lib/presentation/views/floor_matrix/start_session_dialog.dart`):

- **Customer Name**: Mandatory player/customer name.
- **Start Time Options**:
  - **Now** (Default): Starts immediately at current timestamp.
  - **Quick Presets**: `-5 min`, `-10 min`, `-15 min`, `-30 min`, `-45 min`, `-1 hr`.
  - **Custom Time**: Clock time picker (`showTimePicker`) or direct "Minutes ago" numeric input.
  - Validated: Start time cannot be set to a future timestamp.
  - Live Preview: Real-time calculation of elapsed timer and accrued charges.
  - Audit Trail: Appends `[Started at HH:mm]` to session notes when backdated.

Dispatches `StartTableSessionEvent(session)` through `FloorMatrixBloc`.

---

## 4. Adding & Managing Items on Live Tables

Use `AddTableItemDialog` (`lib/presentation/views/floor_matrix/add_table_item_dialog.dart`) and `ManageTableItemsDialog` (`lib/presentation/views/floor_matrix/manage_table_items_dialog.dart`):

- Staff can add items from Canteen stock (`StockItem`) or Custom ad-hoc items.
- Item contains: `id`, `name`, `unitPrice`, `quantity`, `totalPrice`, `addedAt`, `stockItemId`.
- Adding an item dispatches `AddBillingItemEvent` in `FloorMatrixBloc`, updating the running session in Firestore and decrementing canteen stock.

---

## 5. Checkout & Table Closing Procedure

Closing a table is handled via `CheckoutSessionDialog` (`lib/presentation/views/floor_matrix/checkout_session_dialog.dart`):

### Table Close Time & Retroactive Options:

- **Now** (Default): Ends session at the current moment.
- **Quick Presets**: `-5 min`, `-10 min`, `-15 min`, `-30 min`, `-45 min`, `-1 hr`.
  - Presets prior to match start time are disabled/clamped.
- **Strict Validations**:
  - Close time cannot be in the future.
  - Close time cannot be earlier than or equal to `session.startTime`.
- **Dynamic Recalculation**: Duration, hourly charges, items total, and settlement amounts recalculate in real-time based on effective close time.

### Settlement Modes:

1. **Full Paid**: 100% of bill paid. Status = `'Received'`. Appends `PaymentTransaction` for `grandTotal`.
2. **Partial Paid**: Customer pays partial amount now, remainder due. Status = `'Due'`. Requires positive numeric amount `<= grandTotal`.
3. **Full Due**: ₹0 paid now; full amount pending. Status = `'Due'`.

### Completing Checkout:

Dispatches `CloseTableSessionEvent(companyId, sessionId, historyRecord)`:

1. Saves `TableHistoryRecord` to `companies/{companyId}/tablesHistory/{recordId}`.
2. Removes session from `companies/{companyId}/runningTables/{sessionId}`.
3. Resets `ClubTable.status = 'available'` and `currentSessionId = null`.
