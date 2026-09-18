# Snooker Architecture & Coding Rules

These guidelines are mandatory for all AI agents working on Snooker (Constants.appName).

## 1. State Management
- **BLoC Pattern**: Use `FloorMatrixBloc` for tables, running sessions, pricing, and live orders. Use `AuthBloc` for tenant club context, operator identity, and session authentication.
- **No Rogue State**: Never manage shared table or financial states via isolated widget `setState`. Always dispatch events through the corresponding BLoC.
- **Auto-Initialization**: Any BLoC requiring startup verification (such as `AuthBloc` session checks) must dispatch its initialization event in its constructor so hot reload / hot restart never leaves the bloc in an uninitialized state.

## 2. Multi-Tenant Firestore Schema
- **Tenant Scope**: Every document belongs strictly to its parent company:
  - Tables: `companies/{companyId}/snookerTables/{tableId}`
  - Users: `companies/{companyId}/users/{userId}`
  - History: `companies/{companyId}/tablesHistory/{recordId}`
  - Canteen: `companies/{companyId}/canteenItems/{itemId}`
  - Equipment: `companies/{companyId}/equipmentItems/{itemId}`
- **Merge Updates**: Always use `.set(data, SetOptions(merge: true))` when modifying user sessions or financial records to prevent overwriting existing fields or failing on unindexed subcollections.

## 3. Financial & Monetary Safety
- **Strict Input Formatters**: Any monetary input field must include:
  ```dart
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ]
  ```
- **Validation**:
  - Never allow negative numbers or zero-amount payments.
  - In due collection dialogs, always clamp or validate that the entered payment cannot exceed `record.dueAmount`.
  - Disable action buttons (`onPressed: null`) whenever input is empty, non-numeric, or exceeds allowable limits.

## 4. Layout & Flutter RenderFlex Safety
- **Modal Dialogs**: Every modal dialog or bottom sheet MUST have a responsive maximum height constraint and be wrapped in a `SingleChildScrollView`:
  ```dart
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.9,
    maxWidth: 580,
  )
  ```
- **Rows & Badges**: Never place unbounded dynamic text or timestamp rows inside rigid `Row`s. Always wrap in `Expanded(child: Text(..., maxLines: 1, overflow: TextOverflow.ellipsis))` or use `Wrap(runSpacing: 4, children: [...])`.

## 5. Session Management
- **10-Day Duration**: User sessions last 10 days from login.
- **Dual Verification**: Sessions are stored locally via `SharedPreferences` in `SessionLocalStorage` and remotely on `users/{userId}.sessionExpiresAt` as a Firestore `Timestamp`.
- **Auto-Login**: On launch, verify that the local session has not expired and that the user's remote `sessionExpiresAt` timestamp in Firestore is valid before opening the dashboard.

## 6. Tooling & Flutter Version Management (FVM)
- **FVM Enforcement**: This project strictly uses FVM (Flutter Version Management). All Flutter and Dart commands executed via CLI must use `fvm`:
  - Builds: `fvm flutter build apk --release`, `fvm flutter build web`, etc.
  - Package Management: `fvm flutter pub get`, `fvm flutter pub add <pkg>`
  - Static Analysis & Testing: `fvm flutter analyze`, `fvm flutter test`
  - Code Generation / Dart Tools: `fvm dart run build_runner build`
- **Global Tooling Prohibition**: Never execute global `flutter` or `dart` directly to prevent SDK version mismatches.
