# SSAAS Architecture & Data Rules

These guidelines are mandatory for all AI agents working on SSAAS (`Constants.appName`).

## 1. Clean Architecture & Layer Responsibilities
- **Domain Layer (`lib/domain/`)**: Contains pure Dart domain entities (`ClubTable`, `TableSession`, `TableHistoryRecord`, `UserAccount`, `StockItem`, `PaymentTransaction`, `ClubReminder`). Contains NO Flutter dependencies (`package:flutter`) or data source packages (`cloud_firestore`).
- **Data Layer (`lib/data/`)**: Handles remote Firestore CRUD & stream queries (`FirestoreService`), local session storage (`SessionLocalStorage`), and usage analytics tracking (`CompanyUsageTracker`).
- **Presentation Layer (`lib/presentation/`)**: Contains views, dialogs, custom widgets, and BLoC state management (`AuthBloc`, `FloorMatrixBloc`). UI communicates with data through BLoCs or service locator (`sl<FirestoreService>()`).
- **Core Layer (`lib/core/`)**: Cross-cutting utilities, theme constants, DI locator, formatters, and error handling.

## 2. State Management & BLoC Pattern
- **Bloc Providers**: `AuthBloc` and `FloorMatrixBloc` are provided at the root widget level in `main.dart`.
- **FloorMatrixBloc**: Manages table status, running match sessions, timer ticks, billing items, table configurations, and reminders.
- **AuthBloc**: Manages multi-tenant club selection, 10-day session verification, user authentication, active subscription state, operator online status, and user permissions.
- **No Rogue State**: Never manage shared match, table, or payment state via isolated widget `setState()`. Always dispatch events through the corresponding BLoC.
- **Auto-Initialization**: Any BLoC requiring startup verification (such as `AuthBloc` session checks) MUST dispatch its initialization event in its constructor (`add(InitAuthEvent())`) so hot reload / hot restart never leaves the bloc uninitialized.

## 3. Service Locator & Dependency Injection
- Service locator instance is `sl` (`GetIt.instance`), defined in `lib/core/di/service_locator.dart`.
- Singletons registered:
  - `NetworkConnectivityService` (`sl<NetworkConnectivityService>()`)
  - `FirestoreService` (`sl<FirestoreService>()`)
  - `SessionLocalStorage` (`sl<SessionLocalStorage>()`)

## 4. Multi-Tenant Firestore Schema & Collection Names
Every club document belongs strictly to its parent company document under `companies/{companyId}`:

- **Tables**: `companies/{companyId}/snookerTables/{tableId}`
- **Running Sessions**: `companies/{companyId}/runningTables/{sessionId}`
- **Users**: `companies/{companyId}/users/{userId}`
- **Match History**: `companies/{companyId}/tablesHistory/{recordId}`
- **Canteen Inventory**: `companies/{companyId}/foodCanteen/{itemId}`
- **Equipment Stock**: `companies/{companyId}/equipmentStock/{itemId}`
- **Club Reminders**: `companies/{companyId}/reminders/{reminderId}`
- **Daily Quota Log**: `companies/{companyId}/dailyUsage/{dateStr}`
- **Global App Config**: `appConfig/appDownload`

### Firestore Atomic Operations & Merge Rules
- **Merge Updates**: Always use `.set(data, SetOptions(merge: true))` when modifying existing user sessions, table configs, or financial records to prevent accidental field deletion.
- **Batch Writes**: When starting or closing a session, use Firestore batch writes (`_firestore.batch()`) to update the session state and table status atomically.

## 5. Daily Usage & Quota Monitoring
- All Firestore CRUD operations in `FirestoreService` report reads/writes/deletes through `CompanyUsageTracker` (`trackRead`, `trackWrite`, `trackDelete`).
- Flushing usage logs writes aggregated daily usage metrics into `companies/{companyId}/dailyUsage/yyyy-MM-dd`.
