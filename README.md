# SSAAS - Snooker & Billiards Management System

[![Flutter](<https://img.shields.io/badge/Flutter-3.x%20(FVM)-02569B?logo=flutter>)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20BLoC-blueviolet)](https://bloclibrary.dev)
[![Database](https://img.shields.io/badge/Database-Cloud%20Firestore-FFA000?logo=firebase)](https://firebase.google.com)
[![Theme](https://img.shields.io/badge/Theme-Dark%20Obsidian-161A20)](https://material.io)
[![Version](https://img.shields.io/badge/Version-2.0.0%2B1-success)](lib/core/constants/constants.dart)

**SSAAS** is a multi-tenant club management software application engineered for snooker, pool, and billiards club owners and operators. Built with Flutter, Clean Architecture, and the BLoC pattern, SSAAS delivers live table duration tracking, food canteen POS, equipment stock maintenance, expense auditing, match history, due collection settlement, and universal RFC-4180 CSV export.

---

## Table of Contents

- [Core Modules & Features](#core-modules--features)
  - [1. Table & Live Match Management](#1-table--live-match-management)
  - [2. Food Canteen POS & Live Table Ordering](#2-food-canteen-pos--live-table-ordering)
  - [3. Equipment Asset & Cue Maintenance](#3-equipment-asset--cue-maintenance)
  - [4. Billing, Due Collection & Match History](#4-billing-due-collection--match-history)
  - [5. Universal RFC-4180 CSV Reporting & Native Sharing](#5-universal-rfc-4180-csv-reporting--native-sharing)
  - [6. Club Expense Management & Analytics](#6-club-expense-management--analytics)
  - [7. Multi-Tenant Auth & 10-Day Persistent Sessions](#7-multi-tenant-auth--10-day-persistent-sessions)
- [Architecture & Design System](#architecture--design-system)
- [Directory Structure](#directory-structure)
- [Getting Started & Tooling](#getting-started--tooling)
- [Deployment & OTA Updates](#deployment--ota-updates)
- [Firestore Multi-Tenant Schema](#firestore-multi-tenant-schema)
- [Configuration Constants](#configuration-constants)

---

## Core Modules & Features

### 1. Table & Live Match Management

- **Live Floor Matrix**: Real-time visual monitoring of Snooker, English Billiards, 8-Ball, and 9-Ball Pool tables.
- **Drift-Free Timers**: Time elapsed is computed directly against start timestamps in seconds, preventing timer drift across app pauses, device sleep, or restarts.
- **Flexible Pricing Rules**: Supports standard hourly rates, per-frame billing, peak-hour pricing, and fixed slots.
- **Retroactive Match Timing**:
  - **Start Presets**: Start immediately or backdate match starts (`-5m`, `-10m`, `-15m`, `-30m`, `-45m`, `-1h`, or custom clock picker).
  - **Finish Presets**: Backdate match conclusions with safety validations (cannot precede match start or be set in the future).
- **Match Controls**: Pause and resume match duration tracking with accumulated paused duration recording.
- **Multi-Mode Settlement at Checkout**:
  - **Full Paid**: 100% of the bill collected; automatically logged under `PaymentTransaction`.
  - **Partial Paid**: Accepts an initial partial payment; the remaining balance is flagged as `Due`.
  - **Full Due**: Zero payment collected at checkout; balance stored as pending `Due`.

### 2. Food Canteen POS & Live Table Ordering

- **Menu & Inventory Management**: Categorized food and beverage tracking (Beverages, Snacks, Meals, Others).
- **Direct Table Ordering**: Add canteen items directly to running table sessions with real-time bill recalculation.
- **Inventory Synchronization**: Adding items automatically decrements canteen inventory stock in Firestore; removing items from the bill restores inventory stock.
- **Low-Stock Alerts**: Visual badges trigger when inventory drops below 5 units.

### 3. Equipment Asset & Cue Maintenance

- **Club Assets Tracking**: Monitor cues, Aramith ball sets, table cloth, chalk, lighting, heaters, and accessories.
- **Condition Ratings**: Grade equipment health (`Excellent`, `Good`, `Needs Maintenance`, `Replaced`).
- **Procurement & Maintenance Logs**: Track unit procurement costs and maintenance service records.

### 4. Billing, Due Collection & Match History

- **Detailed Match Records**: Historical records capturing table duration, hourly charges, canteen orders, total bill, paid amount, and pending due balance.
- **Audit Trail**: Every transaction is logged with a `PaymentTransaction` entity containing payment method (`Cash`, `UPI`, `Card`), timestamp, operator attribution, and notes.
- **Due Payment Settlement**:
  - Staff can settle pending balances via dedicated due collection dialogs.
  - Form inputs are validated with numeric regex formatters and clamped to prevent over-collection beyond `dueAmount`.
  - **Automatic Due Waiving**: Any remaining due amount less than the configured buffer threshold (default: ₹5.00) is automatically waived and marked as `Received`.

### 5. Universal RFC-4180 CSV Reporting & Native Sharing

- **Predefined Reporting Ranges**:
  - Today (Daily)
  - This Week & Last 7 Days
  - This Month (Till Now) & Last 30 Days
  - This Year (Yearly)
  - All Time
  - Custom Date Range (via date picker)
- **RFC-4180 Compliant CSV Export**: Generates comprehensive spreadsheets containing club header summaries, match details, itemized canteen purchases, payment audit logs, and column totals.
- **Native OS Sharing**: Immediate dispatch through `SharePlus` to WhatsApp, Email, AirDrop, Telegram, Google Drive, or local storage.

### 6. Club Expense Management & Analytics

- **Categorized Outflow Tracking**: Log club operational expenses (Utilities, Maintenance, Inventory Stock, Staff Salaries, Rent, Other).
- **Visual Analytics**: Interactive category distribution charts powered by `fl_chart`.
- **Date Filtering**: Real-time expense metrics across custom or preset date filters.
- **Role-Based Permissions**: Only authorized club operators (Owner, Admin, or Online Employee) can register or delete expenses.

### 7. Multi-Tenant Auth & 10-Day Persistent Sessions

- **Multi-Tenant Club Identification**: Users log in using their unique club company code (e.g., `CCD01`, `MATRIX`).
- **Two-Tier 10-Day Session Persistence**:
  1. **Local Storage**: `SessionLocalStorage` using `SharedPreferences` key `'ssaas_club_user_session'`.
  2. **Remote Cloud Verification**: Firestore `sessionExpiresAt` timestamp on the user's document.
- **Subscription Expiry Enforcement**: Automatically validates the club's SaaS subscription validity (`expiryDate`); blocks access and provides support contacts when expired.
- **Single-Operator Concurrency**: Enforces that only one employee/operator can be marked `isOnline` per club at a given time to eliminate conflicting record modifications.
- **Role-Based Access Control (RBAC)**:
  - **Owner**: Master control, user role management, account activation/deactivation, rate configurations.
  - **Admin**: Staff management, table rate adjustments, and financial exports.
  - **Employee**: Daily live table operations, POS sales, and match checkouts.

---

## Architecture & Design System

### Clean Architecture & State Management

- **Presentation Layer** (`lib/presentation/`): Views, responsive modal sheets, widgets, and BLoCs (`AuthBloc`, `FloorMatrixBloc`, `ExpenseBloc`).
- **Domain Layer** (`lib/domain/`): Pure Dart immutable entities (`ClubTable`, `TableSession`, `TableHistoryRecord`, `UserAccount`, `StockItem`, `PaymentTransaction`, `ClubExpense`) extending `Equatable`.
- **Data Layer** (`lib/data/`): Remote multi-tenant Firestore data sources (`FirestoreService`), local session storage (`SessionLocalStorage`), and usage analytics tracking (`CompanyUsageTracker`).
- **Core Layer** (`lib/core/`): Dependency injection via `get_it`, dark theme tokens, responsive helpers, formatting utilities, and error handlers.

### Design System: Dark Obsidian Theme

- **Theme Palette**:
  - Background Canvas: `AppColors.darkCanvas` (`0xFF0D0F12`)
  - Card & Modal Surfaces: `AppColors.cardSurface` (`0xFF161A20`)
  - Border Strokes: `AppColors.cardBorderStroke` (`0xFF2E3646`)
  - Brand Accent: `AppColors.brandAccent` (`0xFF7C4DFF`)
  - Text Tokens: `AppColors.primaryText` (`0xFFF5F6F8`) and `AppColors.secondaryText` (`0xFF9EA8B6`)
- **Responsive Layout**: `Responsive.showAdaptiveModal()` automatically presents bottom sheets on mobile (`< 680px`) and constrained modal dialogs on desktop/tablet (`>= 680px`).

---

## Directory Structure

```
lib/
├── main.dart                             # App entry point, global BlocProviders, error builders
├── firebase_options.dart                 # Firebase cross-platform configuration
├── core/
│   ├── constants/constants.dart          # Constants.appName ('SSAAS'), version, contact info
│   ├── di/service_locator.dart           # GetIt service locator singleton initialization
│   ├── services/network_connectivity_service.dart # Real-time network connectivity watcher
│   ├── theme/                            # AppColors (Dark Obsidian) & AppTheme (Material 3)
│   └── utils/                            # Responsive, AppNavigation, Formatters, ErrorHandler, Haptics
├── data/
│   └── datasources/
│       ├── firestore_service.dart        # Multi-tenant Firestore CRUD, streams & batch writes
│       ├── session_local_storage.dart    # SharedPreferences 10-day session cache
│       └── company_usage_tracker.dart    # Firestore read/write/delete quota tracking
├── domain/
│   └── entities/                         # Core entities (ClubTable, UserAccount, StockItem, etc.)
└── presentation/
    ├── blocs/
    │   ├── auth/auth_bloc.dart           # Tenant auth, 10-day session validation, user roles
    │   ├── floor_matrix/floor_matrix_bloc.dart # Running tables, timer tick, POS orders, checkout
    │   └── expense/expense_bloc.dart     # Club expenses, category breakdown, date filtering
    ├── views/                            # Screen views categorized by feature module
    │   ├── admin/                        # Dev analytics & company details
    │   ├── auth/                         # Login, account security, company creation
    │   ├── canteen/                      # Food canteen POS & stock manager
    │   ├── contact_and_pricing/          # Pricing info & developer support contact
    │   ├── dashboard/                    # Main dashboard, navigation, online operator status
    │   ├── equipment/                    # Equipment asset stock tracking & maintenance
    │   ├── expense/                      # Operational expense tracking & analytics
    │   ├── floor_matrix/                 # Live table matrix, session start/checkout/order dialogs
    │   ├── history/                      # Match history, due collection, CSV export
    │   ├── manual/                       # Operational guide & user manual
    │   └── users/                        # Associated user administration & permissions
    └── widgets/                          # Reusable UI widgets (AppVersionGuard, NetworkAwareOverlay)
```

---

## Getting Started & Tooling

### Prerequisites

- **FVM (Flutter Version Management)**: This repository strictly requires FVM to prevent SDK version mismatch.
- Flutter SDK `^3.11.0` (managed via FVM).
- Firebase project configured with Cloud Firestore.

### Installation & Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-org/ssaas.git
   cd ssaas
   ```

2. **Install Flutter SDK dependencies via FVM:**

   ```bash
   fvm flutter pub get
   ```

3. **Verify Static Analysis:**

   ```bash
   fvm flutter analyze
   ```

4. **Run Unit & Widget Tests:**

   ```bash
   fvm flutter test
   ```

5. **Launch the application:**
   ```bash
   fvm flutter run
   ```

---

## Deployment & OTA Updates

### Production Builds

| Platform                     | Command                                 |
| ---------------------------- | --------------------------------------- |
| **Android APK (Release)**    | `fvm flutter build apk --release`       |
| **Android App Bundle (AAB)** | `fvm flutter build appbundle --release` |
| **Web Production Bundle**    | `fvm flutter build web`                 |

### Shorebird CodePush (Over-The-Air Patches)

To deploy instantaneous OTA hotfixes on Android without going through app store review:

```bash
shorebird patch --platforms=android --release-version=1.0.0+2
```

---

## Firestore Multi-Tenant Schema

All data collections in Cloud Firestore are strictly isolated and scoped by `companyId`:

```
companies/{companyId}/
├── snookerTables/{tableId}       # Snooker, pool, and billiards table inventory
├── runningTables/{sessionId}     # Live running match sessions
├── users/{userId}                # Associated club staff accounts & permissions
├── tablesHistory/{recordId}      # Finished match logs & payment audit history
├── foodCanteen/{itemId}          # Canteen food, snack, and beverage stock items
├── equipmentStock/{itemId}       # Cues, ball sets, cloth, and club equipment stock
├── expenses/{expenseId}          # Club operational expenses & outlays
├── reminders/{reminderId}        # Club operator maintenance and billing reminders
└── dailyUsage/{dateStr}          # Read/write/delete quota tracking
```

---

<!--
## Configuration Constants

Primary app variables are defined in [`lib/core/constants/constants.dart`](lib/core/constants/constants.dart):

```dart
class Constants {
  static const String appName = 'SSAAS';
  static const String appVersion = '2.0.0';
  static const int appBuildNumber = 1;
  static const bool isAdmin = true;
  static const double dueBufferAmount = 5.0; // Auto-waive pending due if < ₹5.00
  static const String contactPerson = 'Dhruv Soni';
  static const String contactPhone = '9009395674';
  static const String subscriptionUpiId = '9009395674@ybl';
}
```

--- -->

## License

This project is proprietary and confidential. Developed by the SSAAS engineering team.
