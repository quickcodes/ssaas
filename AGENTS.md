# SSAAS Project - AI Agent Master Guidelines

This document is the primary entry point and mandatory guideline handbook for AI agents working on the SSAAS (Snooker & Billiards Management System) Flutter application.

---

## 1. Project Overview & Core Architecture

SSAAS is a multi-tenant Flutter application designed for snooker, pool, and billiards club management, offering live match duration tracking, food canteen POS, equipment stock tracking, match history, and payment collection.

### Architectural Blueprint (Clean Architecture + BLoC)
- **Presentation Layer** (`lib/presentation/`): Views, dialogs, custom widgets, and BLoC state management (`AuthBloc`, `FloorMatrixBloc`).
- **Domain Layer** (`lib/domain/`): Pure Dart entities, immutable value objects (`ClubTable`, `TableSession`, `TableHistoryRecord`, `UserAccount`, `StockItem`, `PaymentTransaction`). Independent of Flutter framework and data sources.
- **Data Layer** (`lib/data/`): Remote data sources (`FirestoreService`), local storage (`SessionLocalStorage`), and usage analytics tracking (`CompanyUsageTracker`).
- **Core Layer** (`lib/core/`): DI service locator (`service_locator.dart`), theme and color design tokens (`app_colors.dart`, `app_theme.dart`), error handling (`error_handler.dart`), formatters (`formatters.dart`), responsive layout helpers (`responsive.dart`), haptics (`interactive_feedback.dart`), and app constants (`constants.dart`).

---

## 2. Directory Structure Quick Reference

```
lib/
├── main.dart                             # Application entry, global BlocProviders, error builders
├── firebase_options.dart                 # Firebase platform configuration
├── core/
│   ├── constants/constants.dart          # Constants.appName ('SSAAS'), version, due buffer
│   ├── di/service_locator.dart           # GetIt service locator singleton initialization
│   ├── services/network_connectivity_service.dart # Real-time connectivity watcher
│   ├── theme/                            # AppColors (Dark Obsidian) & AppTheme (Material 3)
│   └── utils/                            # Responsive, AppNavigation, Formatters, ErrorHandler, Haptics
├── data/
│   └── datasources/
│       ├── firestore_service.dart        # Multi-tenant Firestore CRUD, streams & batch writes
│       ├── session_local_storage.dart    # SharedPreferences 10-day session cache
│       └── company_usage_tracker.dart    # Firestore read/write/delete quota tracking
├── domain/
│   └── entities/                         # Core domain models (ClubTable, UserAccount, TableSession, etc.)
└── presentation/
    ├── blocs/
    │   ├── auth/auth_bloc.dart           # Tenant auth, 10-day session validation, user roles
    │   └── floor_matrix/floor_matrix_bloc.dart # Running tables, timer tick, POS orders, checkout
    ├── views/                            # Screen views categorized by feature module
    │   ├── admin/                        # Dev analytics & company details
    │   ├── auth/                         # Login, account security, company creation
    │   ├── canteen/                      # Food canteen POS & stock manager
    │   ├── contact_and_pricing/          # Pricing info & developer support contact
    │   ├── dashboard/                    # Main dashboard, navigation, online operator status
    │   ├── equipment/                    # Equipment asset stock tracking & maintenance
    │   ├── floor_matrix/                 # Live table matrix, session start/checkout/order dialogs
    │   ├── history/                      # Match history, due collection, CSV export
    │   ├── manual/                       # Operational guide & user manual
    │   └── users/                        # Associated user administration & permissions
    └── widgets/                          # Reusable UI widgets (AppVersionGuard, NetworkAwareOverlay, etc.)
```

---

## 3. Essential Tooling & Development Commands

This project **STRICTLY** uses Flutter Version Management (**FVM**). Direct execution of global `flutter` or `dart` commands is prohibited to avoid SDK version drift.

| Action | Supported Command |
|--------|-------------------|
| Install Dependencies | `fvm flutter pub get` |
| Add Package | `fvm flutter pub add <package>` |
| Run Static Analyzer | `fvm flutter analyze` |
| Run Test Suite | `fvm flutter test` |
| Build Android APK | `fvm flutter build apk --release` |
| Build Web Bundle | `fvm flutter build web` |
| Run Code Generator | `fvm dart run build_runner build` |

---

## 4. Key Coding Conventions & Architectural Rules

### A. State Management & BLoCs
- **Global Providers**: `AuthBloc` and `FloorMatrixBloc` are provided globally at root in `main.dart`.
- **Auto-Initialization**: BLoCs requiring startup state verification MUST trigger their initialization event in their constructor (e.g., `AuthBloc` dispatches `InitAuthEvent()` on creation).
- **No Rogue Widget State**: Never manage shared match, pricing, or financial state in isolated widget `setState()`. Always dispatch events through the appropriate BLoC.

### B. Multi-Tenant Firestore Rules
- Document hierarchy MUST be strictly scoped by `companyId`:
  - Snooker Tables: `companies/{companyId}/snookerTables/{tableId}`
  - Running Sessions: `companies/{companyId}/runningTables/{sessionId}`
  - User Accounts: `companies/{companyId}/users/{userId}`
  - Match History: `companies/{companyId}/tablesHistory/{recordId}`
  - Canteen Stock: `companies/{companyId}/foodCanteen/{itemId}`
  - Equipment Stock: `companies/{companyId}/equipmentStock/{itemId}`
  - Reminders: `companies/{companyId}/reminders/{reminderId}`
  - Usage Log: `companies/{companyId}/dailyUsage/{dateStr}`
- **Merge Updates**: Always use `.set(data, SetOptions(merge: true))` when modifying existing Firestore documents to prevent field overwrites.

### C. Financial & Monetary Safety
- Monetary inputs MUST use the standard regex formatter:
  ```dart
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ]
  ```
- **Clamping & Validation**: Never allow negative payment values. In due collection dialogs, always clamp or validate that payments cannot exceed `record.dueAmount`. Action buttons MUST be disabled (`onPressed: null`) when inputs are invalid or empty.

### D. Layout & RenderFlex Protection
- **Modal Constraints**: Modal sheets and dialogs must have responsive maximum height limits and wrap dynamic content in a `SingleChildScrollView`:
  ```dart
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.9,
    maxWidth: 580,
  ),
  child: SingleChildScrollView(child: contentWidget),
  ```
- **Adaptive Display**: Use `Responsive.showAdaptiveModal()` for modals (`showModalBottomSheet` on mobile `<680px`, `showDialog` on desktop/tablet `>=680px`).
- **Text Overflow**: Wrap dynamic string rows in `Expanded(child: Text(..., maxLines: 1, overflow: TextOverflow.ellipsis))` or `Wrap` widgets to avoid RenderFlex overflows.

---

## 5. Session Management & Security

- **10-Day Persistence**: User sessions remain active for 10 days from login.
- **Dual Tier Persistence**:
  1. Local storage via `SharedPreferences` key `'ssaas_club_user_session'` (`SessionLocalStorage`).
  2. Cloud document `companies/{companyId}/users/{userId}` field `sessionExpiresAt` (`Timestamp`).
- **Auto-Login**: On launch, `AuthBloc` verifies local session validity, fetches the company record to confirm active subscription, checks remote `sessionExpiresAt`, and confirms account `isActive`.

---

## 6. Testing & Quality Expectations

- Run `fvm flutter analyze` before completing changes to verify zero static analysis errors.
- Run `fvm flutter test` to ensure existing unit tests pass.
- Maintain immutability on domain entities (`copyWith()`, `Equatable`).
- Route all user-facing errors through `AppErrorHandler.format()` or `AppErrorHandler.showErrorSnackBar()`.

---

## 7. Rules and Skills Index

Refer to specialized documentation in `.agents/` for task-specific workflows:

### Rules (`.agents/rules/`)
- [`ssaas_architecture_rules.md`](.agents/rules/ssaas_architecture_rules.md): Core architecture, multi-tenant Firestore schema, layer responsibilities, DI, and state management.
- [`ssaas_ui_and_design_system_rules.md`](.agents/rules/ssaas_ui_and_design_system_rules.md): Dark obsidian color system, Material 3 theme, responsive breakpoints, adaptive modals, and layout safety.
- [`ssaas_coding_and_testing_rules.md`](.agents/rules/ssaas_coding_and_testing_rules.md): Dart/Flutter conventions, entity design, error formatting, FVM workflows, and testing guidelines.

### Skills (`.agents/skills/`)
- [`ssaas-table-management`](.agents/skills/ssaas-table-management/SKILL.md): Snooker tables, live match timers, pricing rules, order items, and checkout settlement.
- [`ssaas-auth-and-sessions`](.agents/skills/ssaas-auth-and-sessions/SKILL.md): Multi-tenant auth, 10-day session persistence, user roles, auto-login, and operator concurrency.
- [`ssaas-stock-and-canteen`](.agents/skills/ssaas-stock-and-canteen/SKILL.md): Food canteen POS, inventory stock increment/decrement, equipment maintenance, and table billing integration.
- [`ssaas-billing-and-history`](.agents/skills/ssaas-billing-and-history/SKILL.md): Match history records, partial payment tracking, due collection settlement, and RFC-4180 CSV export.
- [`ssaas-feature-and-ui-development`](.agents/skills/ssaas-feature-and-ui-development/SKILL.md): Creating or modifying views, adaptive modals, BLoC events, responsive layouts, and UI tokens.

---
*Last updated: September 2026*
