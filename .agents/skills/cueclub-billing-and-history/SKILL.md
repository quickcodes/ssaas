---
name: cueclub-billing-and-history
description: >-
  Workflows, domain models, and business logic for match history, payment transaction logs, collecting pending due payments, due-amount clamping, financial audits, and CSV reports. Use when updating or debugging billing records, transaction histories, due settlement dialogs, or history views in CueClub OS.
---

# CueClub Billing & Match History Management

This skill documents the payment audit trail, due payment collection, financial accounting, and history reporting in CueClub OS.

## 1. Domain Entities & Firestore Structure

Collection: `companies/{companyId}/tablesHistory/{recordId}`

### Entities
- **`PaymentTransaction`** (`lib/domain/entities/payment_transaction.dart`):
  - `id`: Unique UUID.
  - `amount`: Monetary value received in this transaction.
  - `paymentMethod`: `'Cash'`, `'UPI'`, or `'Card'`.
  - `receivedAt`: `DateTime` when payment was collected.
  - `receivedBy`: Staff operator who accepted the funds.
  - `notes`: Audit note (e.g. "Initial partial payment at checkout", "Settlement of pending due").

- **`TableHistoryRecord`** (`lib/domain/entities/table_history_record.dart`):
  - `totalAmount`: Table amount + items amount.
  - `transactions`: `List<PaymentTransaction>` tracking all payments made across time.
  - `paidAmount`: Computed dynamically:
    ```dart
    double get paidAmount => transactions.fold<double>(0.0, (total, t) => total + t.amount);
    ```
  - `dueAmount`: Computed dynamically:
    ```dart
    double get dueAmount {
      final rem = totalAmount - paidAmount;
      return rem > 0.001 ? rem : 0.0;
    }
    ```
  - `paymentStatus`: `'Received'` if `dueAmount <= 0.001`, otherwise `'Due'`.
  - `customerName`: The player/person on whom the table was closed.
  - `closedByName`: Staff operator who closed the table.

---

## 2. Collecting Subsequent Due Payments

When a customer comes back later to pay off a pending bill, staff use `_showRecordPaymentDialog` in `TablesHistoryView` (`lib/presentation/views/history/tables_history_view.dart`):

### Safety & Validation Rules:
1. **Input Restrictions**:
   - Strictly numerical input: `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))`.
   - Disallow values `<= 0.0`.
   - Disallow values `> record.dueAmount`. Inline error states: `"Amount cannot exceed pending due of ₹X.XX"`.
   - The Confirm button is disabled (`onPressed: null`) whenever the input is empty or invalid.
2. **Dynamic Settlement Breakdown Banner**:
   - Real-time display showing:
     - `Received Now: ₹X.XX`
     - `Remaining Due: ₹Y.YY`
     - Status: `FULL SETTLE (MATCH SETTLED)` or `PARTIAL (STILL DUE)`.
3. **Quick-Fill Helpers**:
   - Chips for **"Pay Full Due (₹X)"** and **"Pay Half (₹Y)"** to accelerate staff data entry.
4. **Recording the Transaction**:
   - Appends a new `PaymentTransaction` to `record.transactions`.
   - Updates `paymentStatus` to `'Received'` if fully cleared, else `'Due'`.
   - Saves via `FirestoreService.updateTableHistoryRecord(updatedRecord)` using `SetOptions(merge: true)`.

---

## 3. Match Details & Transaction Audit Trail

In `_showMatchDetailsModal`:
- Shows complete breakdown: Table Charge, Itemized Canteen Purchases, Grand Total, Total Paid, and Current Balance.
- **Audit List**: Renders every individual transaction with payment method badge (Cash/UPI/Card), formatted timestamp, operator attribution (`"by Marker 1"`), and notes.

---

## 4. UI Rendering Best Practices for History Views

To prevent Flutter layout exceptions:
- **Vertical RenderFlex Overflows**: Modal sheets and dialogs MUST be wrapped in `SingleChildScrollView` with a responsive constraint:
  ```dart
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.9,
    maxWidth: 580,
  )
  ```
- **Horizontal RenderFlex Overflows**: Match item headers and status badges must use `Wrap` with `runSpacing: 4` or `Flexible` widgets rather than rigid `Row`s.

---

## 5. Detailed Spreadsheet Export & Sharing

Handled via `HistoryReportExporter` (`lib/core/utils/history_report_exporter.dart`) and `ShareHistoryReportDialog` (`lib/presentation/views/history/share_history_report_dialog.dart`):

### Presets Supported:
- **This Month (Till Now)** (1st of month to now)
- **Last 30 Days (Daily)**
- **This Week** (Monday to now)
- **Last 7 Days**
- **Today (Daily)**
- **This Year (Yearly)**
- **All Time**
- **Custom Range...** (via `showDateRangePicker`)

### Spreadsheet Format (.CSV):
- **Universal RFC-4180 Format**: Instantly opens in Excel, Google Sheets, Apple Numbers.
- **Header Summary**: Club Name, Report Range, Generated Timestamp, Total Matches, Total Duration, Table Revenue, Canteen Revenue, Grand Total, Total Paid Received, Total Due Pending.
- **Detailed Data Columns**: Match #, Date, Table Name, Closing Person, Started By, Closed By, Start Time, End Time, Duration, Table Amount, Items Amount, Grand Total, Paid Amount, Due Amount, Payment Status, Payment Method, Itemized Canteen Purchases, and Payment Transactions Audit Log.
- **Totals Row**: Computes column sums for all duration and financial metrics.
- **Native Sharing**: Dispatches through `SharePlus.instance.share(ShareParams(...))` with `sharePositionOrigin` anchoring, allowing immediate dispatch via WhatsApp, Mail, AirDrop, Telegram, Google Drive, or local file save.
