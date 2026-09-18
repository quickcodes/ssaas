---
name: snooker-auth-and-sessions
description: >-
  Workflows, domain models, and business logic for multi-tenant club authentication, 10-day user session persistence, Firestore session timestamps, subscription expiry enforcement, and user administration. Use when modifying or debugging authentication flows, auto-login, local session storage, or user roles in Snooker (Constants.appName).
---

# Snooker Authentication & Session Persistence

This skill documents the multi-tenant architecture, user roles, subscription enforcement, and 10-day persistent session system in Snooker (Constants.appName).

## 1. Domain Entities & Firestore Structure

- **Companies Collection**: `companies/{companyId}`
  - `name`: Club name.
  - `code`: Unique company code (uppercase, e.g., `CCD01`, `MATRIX`). Entered during login to identify the club without revealing other clubs' names.
  - `number`: Contact phone.
  - `expiryDate`: `DateTime` representing the SaaS subscription expiration.
  - `isExpired`: Getter comparing `DateTime.now().isAfter(expiryDate)`. When expired, all app access is blocked and users are redirected to the subscription screen.
- **Users Subcollection**: `companies/{companyId}/users/{userId}`
  - `name`, `email`, `number`, `password`.
  - `isAdmin`: Boolean granting user management, table price configuration, and report export permissions.
  - `sessionExpiresAt`: Firestore `Timestamp` indicating when this user's current session will expire.

---

## 2. 10-Day Persistent Session Architecture

Sessions persist for **10 days** from the time of login across app restarts and device reboots.

### Two-Tier Verification System:

1. **Local Storage (`SharedPreferences`)**:
   - Class: `SessionLocalStorage` (`lib/data/datasources/session_local_storage.dart`).
   - Key: `'snooker_club_user_session'`.
   - Payload: `{ "companyId": "...", "userId": "...", "expiresAt": "2026-09-26T..." }`.
   - Native storage on Android (`SharedPreferences`), macOS/iOS (`NSUserDefaults`), and Web (`localStorage`).
2. **Remote Cloud Verification (Firestore)**:
   - On login, Firestore user doc is updated:
     ```dart
     final sessionExpiresAt = DateTime.now().add(const Duration(days: 10));
     await _firestoreService.updateUserSession(companyId, userId, sessionExpiresAt);
     ```
   - On logout, Firestore user doc session is invalidated (`sessionExpiresAt: null`).

---

## 3. Startup & Hot Restart Auto-Login Flow

In `AuthBloc` (`lib/presentation/blocs/auth/auth_bloc.dart`):

1. **Trigger**: `add(InitAuthEvent())` runs automatically in `AuthBloc` constructor and in `MainDashboardView.initState()`.
2. **Local Check**: Reads `SessionLocalStorage.getSession()`.
   - If missing or `DateTime.now().isAfter(expiresAt)` -> clears local session, displays `LoginScreen`.
3. **Remote Check**:
   - Fetches `company = await _firestoreService.getCompanyById(companyId)`.
   - If `company.isExpired` -> emits subscription expired state.
   - Fetches `user = await _firestoreService.getUserById(companyId, userId)`.
   - Checks `user.isSessionValid`:
     ```dart
     bool get isSessionValid => sessionExpiresAt != null && DateTime.now().isBefore(sessionExpiresAt!);
     ```
4. **Outcome**:
   - If valid: Emits `AuthState(currentUser: user, activeCompany: company)`. App immediately opens the main dashboard with zero login friction.
   - If invalid or revoked in DB: Clears local session, shows login screen.

---

## 4. User Administration & Permissions

In `CompanyUsersView` (`lib/presentation/views/users/company_users_view.dart`):

- Only admins (`currentUser.isAdmin`) can access the Associated Users screen.
- Displays all registered club operators, markers, and admins.
- Under each user card, displays live session status:
  - `"Session active until <Date, Time>"` with green checkmark.
  - Or `"Session expired"`.
- Layout safety: Wrap user labels and session rows in `Expanded` / `Flexible` with `TextOverflow.ellipsis` to prevent RenderFlex overflow on narrow views.
