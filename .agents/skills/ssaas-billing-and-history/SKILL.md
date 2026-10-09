---
name: ssaas-billing-and-history
description: >-
  Workflows, domain models, and business logic for match history, payment transaction logs, collecting pending due payments, due-amount clamping, financial audits, and CSV reports. Use when updating or debugging billing records, transaction histories, due settlement dialogs, or history views in SSAAS (Constants.appName).
---

# SSAAS Billing & Match History Management

This skill documents the payment audit trail, due payment collection, financial accounting, and history reporting in SSAAS (`Constants.appName`).

## 1. Domain Entities & Firestore Structure

Collection: `companies/{companyId}/tablesHistory/{recordId}`

### Entities

- **`PaymentTransaction`** (`lib/domain/entities/payment_transaction.dart`):
  - `id`: Unique UUID.
  - `amount`: Monetary value received.
  - `paymentMethod`: `'Cash'`, `'UPI'`, or `'Card'`.
  - `receivedAt`: `DateTime` timestamp.
  - `receivedBy`: Staff operator who accepted payment.
  - `notes`: Audit note (e.g. "Initial partial payment at checkout", "Settlement of pending due").

- **`TableHistoryRecord`** (`lib/domain/entities/table_history_record.dart`):
  - `totalAmount`: Table charge + items total.
  - `transactions`: `List<PaymentTransaction>` tracking all payments made over time.
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
  - `paymentStatus`: `'Received'` if `dueAmount <= company.dueBufferAmount`, otherwise `'Due'`.
  - `customerName`: Player/customer responsible for closing the bill.
  - `closedByName`: Staff operator who closed the table.

---

## 2. Collecting Subsequent Pending Due Payments

When a customer returns later to settle a pending balance:

1. Staff open `SettleDuePaymentScreen` (`lib/presentation/views/history/settle_due_payment_screen.dart`) or use record payment dialog in `TablesHistoryView` (`lib/presentation/views/history/tables_history_view.dart`).

### Safety & Validation Rules:

- **Input Formatters**: `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))`.
- **Validation**: Disallow amounts `<= 0.0` or `> record.dueAmount`. Display error: `"Amount cannot exceed pending due of ₹X.XX"`.
- **Waiving Minor Dues**: If remaining due is less than `company.dueBufferAmount` (default ₹5.00), it is automatically waived and marked `'Received'`.
- **Quick Presets**: Chips for **"Pay Full Due (₹X)"** and **"Pay Half (₹Y)"**.
- **Transaction Recording**: Appends new `PaymentTransaction` to `record.transactions`, updates `paymentStatus` to `'Received'` if cleared, and saves via `_firestoreService.updateTableHistoryRecord(updatedRecord)` using `SetOptions(merge: true)`.

---

## 3. Match Details & Transaction Audit Trail

In `TablesHistoryView`:

- View detailed breakdown: Table Name, Start Time, End Time, Total Played Duration, Table Charge, Canteen Items, Total Bill, Total Paid, and Current Balance.
- **Audit Log**: Displays every individual `PaymentTransaction` with payment method badge (Cash/UPI/Card), timestamp, operator attribution (`"by Operator Name"`), and audit notes.

---

## 4. Universal RFC-4180 CSV Spreadsheet Export & Native Sharing

Handled via `HistoryReportExporter` (`lib/core/utils/history_report_exporter.dart`) and `ShareHistoryReportDialog` (`lib/presentation/views/history/share_history_report_dialog.dart`):

### Supported Presets:
- **This Month (Till Now)**
- **Last 30 Days (Daily)**
- **This Week**
- **Last 7 Days**
- **Today (Daily)**
- **This Year (Yearly)**
- **All Time**
- **Custom Range...** (via `showDateRangePicker`)

### CSV Spreadsheet Format:
- **Header Summary**: Club Name, Report Range, Generated Timestamp, Total Matches, Total Duration, Table Revenue, Canteen Revenue, Grand Total, Total Paid Received, Total Pending Due.
- **Data Columns**: Match #, Date, Table Name, Closing Person, Started By, Closed By, Start Time, End Time, Duration, Table Amount, Items Amount, Grand Total, Paid Amount, Due Amount, Payment Status, Payment Method, Itemized Canteen Purchases, and Payment Transactions Audit Log.
- **Totals Row**: Column sums for duration and financial metrics.
- **Native Dispatch**: Transmitted via `SharePlus` (`ShareParams`), enabling immediate dispatch via WhatsApp, Mail, AirDrop, Telegram, Drive, or local storage.
