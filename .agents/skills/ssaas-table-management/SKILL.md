---
name: ssaas-table-management
description: >-
  Workflows, domain models, and business logic for managing snooker/billiards tables, running live matches, adding canteen/stock items to tables, configuring rates, and executing checkout with multi-mode payment settlement. Use when modifying or debugging table sessions, pricing rules, live duration timers, or checkout dialogs in SSAAS (Constants.appName).
---

# SSAAS Table & Live Session Management

This skill documents the table management system, pricing models, running session timers, and checkout procedures in SSAAS (Constants.appName).

## 1. Domain Entities & Firestore Structure

Tables and sessions are scoped per club/company under Firestore:

- Collection: `companies/{companyId}/snookerTables/{tableId}`

### Key Entities

- **`ClubTable`** (`lib/domain/entities/club_table.dart`):
  - `id`, `companyId`, `name`, `type` (Snooker, English Billiards, 8-Ball Pool, 9-Ball Pool).
  - `ratePerHour`: Base hourly rate.
  - `frameRate`: Per-frame billing option.
  - `status`: `'available'`, `'occupied'`, `'maintenance'`.
  - `currentSession`: Embedded `TableSession` object when status is `'occupied'`, `null` when available.

- **`TableSession`** (`lib/domain/entities/table_session.dart`):
  - `id`: Session UUID.
  - `customerName`: Initial player/customer who opened the table.
  - `startedByName`: Staff operator who started the table.
  - `startTime`: `DateTime` when match commenced.
  - `pricingType`: Regular hourly, Frame-based, Peak hour, or Fixed slot.
  - `items`: `List<TableBillingItem>` (snacks, beverages, chalk, etc. ordered to table).
  - `itemsAmount`: Computed total of all added billing items.

---

## 2. Rate & Duration Calculation Rules

All time-based calculations use seconds elapsed to prevent drift:

```dart
int playedSeconds = session.playedSecondsAt(now);
int durationMinutes = (playedSeconds / 60).ceil();
```

### Table Charge Calculation:

- **Hourly**: `(playedSeconds / 3600.0) * table.ratePerHour` (subject to minimum charges if configured).
- **Frame-based**: Number of frames multiplied by `table.frameRate`.
- **Grand Total**: `tableCharge + session.itemsAmount`.

---

---

## 3. Starting a Table Session & Retroactive Start Time

Handled via `StartSessionDialog` (`lib/presentation/views/floor_matrix/start_session_dialog.dart`):

- **Customer Name**: Mandatory player/customer name.
- **Start Time Options**:
  - **Now** (Default): Starts immediately at current timestamp.
  - **Quick Presets**: `-5 min`, `-10 min`, `-15 min`, `-30 min`, `-45 min`, `-1 hr`.
  - **Custom Time**: Clock time picker (`showTimePicker`) or direct "Minutes ago" numeric input.
  - Validated: Start time cannot be set to a future timestamp.
  - Live Preview: Real-time calculation of elapsed timer and already accrued table charges based on the table's hourly rate and rate schedules.
  - Audit Trail: Appends `[Started at HH:mm]` to session notes when backdated.

---

## 4. Adding Items to Live Tables

Use `AddTableItemDialog` (`lib/presentation/views/floor_matrix/add_table_item_dialog.dart`):

- Staff can add items from Canteen stock (`CanteenItem`) or Custom ad-hoc items.
- Item contains: `id`, `name`, `unitPrice`, `quantity`, `totalPrice`, `addedAt`.
- Adding an item emits `AddSessionBillingItemEvent` in `FloorMatrixBloc`, atomically updating the table's `currentSession.items` array in Firestore.

---

## 5. Checkout & Table Closing Procedure

Closing a table is handled via `CheckoutSessionDialog` (`lib/presentation/views/floor_matrix/checkout_session_dialog.dart`):

### Table Close Time & Retroactive Close Options:

- **Now** (Default): Ends session at the current moment.
- **Quick Presets**: `-5 min`, `-10 min`, `-15 min`, `-30 min`, `-45 min`, `-1 hr`.
  - Presets that would fall before the table's actual start time are automatically disabled/clamped.
- **Custom Time**: Clock time picker (`showTimePicker`) or "Mins ago" numeric input.
- **Strict Validations**:
  - Close time cannot be in the future.
  - Close time cannot be earlier than or equal to the session start time (`widget.session.startTime`).
- **Dynamic Recalculation**: Duration played, dynamic hourly/frame table charges, items total, and settlement amounts recalculate in real-time based on the chosen effective close time.
- **Audit Badge**: Displays a yellow/amber retroactive badge (`CLOSED AT PREVIOUS TIME (Xm ago)`) and explicit end timestamp.

### Required Input Fields:

1. **Closing Person Name (`customerName`)**:
   - Pre-filled with `session.customerName`.
   - **Crucial**: Staff can change this to another player at the table if someone else is settling or responsible for the bill (e.g., loser pays).
   - Validated: Cannot be empty.
2. **Closed By Staff / Marker (`closedByName`)**:
   - Pre-filled with `activeOperator.name`.
   - Validated: Cannot be empty.

### Settlement Modes:

Staff select one of 3 payment modes:

1. **Full Paid**:
   - 100% of the bill is paid.
   - Status set to `'Received'`.
   - Appends a `PaymentTransaction` for the entire `grandTotal`.
2. **Partial Paid**:
   - Customer pays a partial amount now, remainder is marked due.
   - Requires amount received input with strict validation:
     - Cannot be negative or non-numeric (`FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))`).
     - Cannot be `>= grandTotal` (prompts staff to select Full Paid).
   - Appends a `PaymentTransaction` for the partial amount received.
   - Status set to `'Due'`.
3. **Full Due**:
   - ₹0 paid now; full amount pending.
   - Status set to `'Due'`. No transactions recorded yet.

### Completing the Session:

Dispatches `CloseTableSessionEvent(companyId, sessionId, historyRecord)`:

1. Saves the finalized `TableHistoryRecord` to `companies/{companyId}/tablesHistory/{recordId}`.
2. Resets `ClubTable.currentSession = null` and `status = 'available'` in Firestore.
