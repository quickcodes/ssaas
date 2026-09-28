# Snooker Project - AI Agent Guidelines

This document contains mandatory guidelines for all AI agents working on the Snooker (Constants.appName) Flutter project. These rules are enforced and should be followed in all code modifications, bug fixes, and feature implementations.

---

## 1. State Management Rules

### BLoC Pattern Enforcement
- **Use FloorMatrixBloc** for table management, running sessions, pricing configuration, and live orders
- **Use AuthBloc** for tenant club context, operator identity verification, and session authentication
- **Never manage shared state via isolated widget setState()**. All state changes must go through the appropriate BLoC event dispatch

### Auto-Initialization Requirement
- Any BLoC requiring startup verification (such as `AuthBloc` session checks) **MUST** dispatch its initialization event in its constructor
- This ensures hot reload / hot restart never leaves the bloc in an uninitialized state
- Example: `AuthBloc` automatically calls `add(InitAuthEvent())` on construction

---

## 2. Multi-Tenant Firestore Architecture

### Tenant Scope Enforcement
Every document belongs strictly to its parent company using this structure:

```
companies/{companyId}/tables/{tableId}      // Snooker tables
companies/{companyId}/users/{userId}        // Club users/operators
companies/{companyId}/tablesHistory/{recordId}  // Table session history
companies/{companyId}/canteenItems/{itemId}   // Canteen menu items
companies/{companyId}/equipmentItems/{itemId} // Equipment stock
```

### Merge Updates Rule
When modifying user sessions or financial records, **ALWAYS** use `.set(data, SetOptions(merge: true))` to prevent overwriting existing fields or failing on unindexed subcollections.

---

## 3. Financial & Monetary Safety

### Input Formatting
All monetary input fields MUST include this formatter:

```dart
inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
]
```

### Validation Rules
- **Never allow negative numbers or zero-amount payments**
- In due collection dialogs, always clamp or validate that the entered payment cannot exceed `record.dueAmount`
- Disable action buttons (`onPressed: null`) whenever input is empty, non-numeric, or exceeds allowable limits

---

## 4. Layout & Flutter RenderFlex Safety

### Modal Dialogs
Every modal dialog or bottom sheet MUST have responsive constraints and be wrapped in a `SingleChildScrollView`:

```dart
constraints: BoxConstraints(
  maxHeight: MediaQuery.of(context).size.height * 0.9,
  maxWidth: 580,
),
child: SingleChildScrollView(
  child: contentWidget,
)
```

### Text Overflow Handling
- **Never place unbounded dynamic text or timestamp rows inside rigid Row/Flex widgets**
- Always wrap in `Expanded(child: Text(..., maxLines: 1, overflow: TextOverflow.ellipsis))` or use `Wrap(runSpacing: 4, children: [...])`

---

## 5. Session Management Rules

### Duration & Storage
- User sessions last **10 days** from login time
- Sessions are stored in TWO places:
  1. **Local**: `SharedPreferences` key `'snooker_club_user_session'` with payload `{ "companyId": "...", "userId": "...", "expiresAt": "2026-09-26T..." }`
  2. **Remote**: Firestore document `users/{userId}` field `sessionExpiresAt` as a `Timestamp`

### Auto-Login Flow
On app launch, verify that:
1. Local session has not expired (`DateTime.now().isAfter(expiresAt)` → invalid)
2. Remote Firestore `sessionExpiresAt` timestamp is valid
3. Company subscription is active (not expired)

If all checks pass → auto-login and open main dashboard immediately. Otherwise → show login screen.

---

## 6. Tooling & Flutter Version Management (FVM)

### FVM Enforcement
This project **STRICTLY** uses FVM (Flutter Version Management). All commands must use `fvm`:

| Command | FVM Format |
|---------|------------|
| Build APK | `fvm flutter build apk --release` |
| Build Web | `fvm flutter build web` |
| Package Get | `fvm flutter pub get` |
| Add Package | `fvm flutter pub add <pkg>` |
| Analyze | `fvm flutter analyze` |
| Run Tests | `fvm flutter test` |
| Build Runner | `fvm dart run build_runner build` |

### Global Tooling Prohibition
**NEVER** execute global `flutter` or `dart` directly to prevent SDK version mismatches. Always use FVM-wrapped commands.

---

## 7. Code Quality & Conventions

### Entity Design
- Domain entities in `lib/domain/entities/` must be independent of data sources and UI layers
- Use `equatable` package for value equality checks in BLoCs
- Implement `copyWith()` methods for all state classes to enable immutable updates

### Error Handling
- Catch errors at the datasource layer, not in business logic
- Emit descriptive error messages through BLoC states instead of printing directly
- Use `debugPrint()` only for debugging; never in production code

### Testing Requirements
- Do not Write any unit tests for any BLoCs or critical datasources

---

## 8. Common Pitfalls to Avoid

| Pitfall | Correct Approach |
|---------|------------------|
| Managing table state in widget setState() | Dispatch events through FloorMatrixBloc |
| Overwriting Firestore documents without merge | Use `.set(data, SetOptions(merge: true))` |
| Allowing negative payment amounts | Validate input with regex and disable buttons when invalid |
| Rigid Row/Flex layouts with dynamic content | Wrap text in Expanded + TextOverflow.ellipsis |
| Skipping auto-login initialization | Always call init event in BLoC constructor |

---

## 9. Quick Reference: Key Files & Classes

```
lib/
├── core/
│   ├── constants/constants.dart          # Constants.appName, app version
│   ├── di/service_locator.dart           # GetIt singleton for DI
│   ├── services/network_connectivity_service.dart
│   └── theme/app_theme.dart
├── data/datasources/
│   ├── firestore_service.dart             # Firebase CRUD + streams
│   └── session_local_storage.dart         # SharedPreferences wrapper
├── domain/entities/                       # Business logic models
│   ├── company.dart
│   ├── user_account.dart
│   ├── table_session.dart
│   └── ...
└── presentation/
    ├── blocs/
    │   ├── auth/auth_bloc.dart            # Auth + session management
    │   └── floor_matrix/floor_matrix_bloc.dart  # Table operations
    └── views/                              # UI screens
```

---

## 10. When to Use This Skill

Use this skill when:
- Modifying authentication flows or session persistence logic
- Working with multi-tenant Firestore data structures
- Implementing financial calculations or payment features
- Creating modal dialogs or handling responsive layouts
- Debugging state management issues across BLoCs

---

*Last updated: September 2026*
