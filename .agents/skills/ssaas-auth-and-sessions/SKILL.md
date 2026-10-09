---
name: ssaas-auth-and-sessions
description: >-
  Workflows, domain models, and business logic for multi-tenant club authentication, 10-day user session persistence, Firestore session timestamps, subscription expiry enforcement, and user administration. Use when modifying or debugging authentication flows, auto-login, local session storage, or user roles in SSAAS (Constants.appName).
---

# SSAAS Authentication & Session Persistence

This skill documents the multi-tenant architecture, user roles, subscription enforcement, and 10-day persistent session system in SSAAS (`Constants.appName`).

## 1. Domain Entities & Firestore Structure

- **Companies Collection**: `companies/{companyId}`
  - `name`: Club name.
  - `code`: Unique company code (uppercase, e.g., `CCD01`, `MATRIX`). Entered during login to identify the club.
  - `number`: Contact phone.
  - `expiryDate`: `DateTime` representing SaaS subscription expiration.
  - `dueBufferAmount`: Threshold cap for waiving minor dues (defaults to `Constants.dueBufferAmount` = ₹5.00).
  - `isExpired`: Getter comparing `DateTime.now().isAfter(expiryDate)`. When expired, app access is blocked and users are prompted to contact support.
- **Users Subcollection**: `companies/{companyId}/users/{userId}`
  - `name`, `email`, `number`, `password`.
  - `role`: `'owner'` or `'employee'`.
  - `isAdmin`: Boolean granting user administration, table rate configuration, and history export.
  - `isOwner`: Boolean (`role == 'owner'`) with master control over user activation/deactivation and roles.
  - `isActive`: Account status boolean. If `false`, login is blocked and active sessions are revoked.
  - `isOnline`: Operator online status boolean. Concurrency rule enforces only one online operator per club at a time.
  - `sessionExpiresAt`: Firestore `Timestamp` indicating when user's current session will expire.

---

## 2. 10-Day Persistent Session Architecture

Sessions persist for **10 days** from login time across app restarts and device reboots.

### Two-Tier Verification System:

1. **Local Storage (`SharedPreferences`)**:
   - Service: `SessionLocalStorage` (`lib/data/datasources/session_local_storage.dart`).
   - Key: `'ssaas_club_user_session'` (fallback to `'snooker_club_user_session'`).
   - Payload JSON: `{ "companyId": "...", "userId": "...", "expiresAt": "2026-09-26T..." }`.
2. **Remote Cloud Verification (Firestore)**:
   - On login, user document is updated with `sessionExpiresAt = DateTime.now().add(Duration(days: 10))`.
   - On logout or deactivation, Firestore `sessionExpiresAt` is set to `null`.

---

## 3. Startup & Auto-Login Verification Flow

In `AuthBloc` (`lib/presentation/blocs/auth/auth_bloc.dart`):

1. **Trigger**: `add(InitAuthEvent())` runs automatically in `AuthBloc` constructor and `MainDashboardView.initState()`.
2. **Local Session Check**: Reads `SessionLocalStorage.getSession()`.
   - If missing or `DateTime.now().isAfter(expiresAt)` -> clears local session, displays `LoginScreen`.
3. **Remote Subscription & DB Verification**:
   - Fetches `company = await _firestoreService.getCompanyById(companyId)`.
   - If `company.isExpired` -> clears session, displays subscription expired alert.
   - Fetches `user = await _firestoreService.getUserById(companyId, userId)`.
   - Checks `user.isSessionValid` (`sessionExpiresAt != null && DateTime.now().isBefore(sessionExpiresAt)`).
   - Confirms `user.isActive == true`.
4. **Outcome**:
   - If valid: Emits `AuthState(currentUser: user, activeCompany: company)`. App immediately opens `MainDashboardView`.
   - If invalid/deactivated/revoked: Clears local session, presents `LoginScreen` with descriptive message.

---

## 4. User Administration & Operator Concurrency

In `CompanyUsersView` (`lib/presentation/views/users/company_users_view.dart`) and `UserOnlineStatusDialog` (`lib/presentation/views/dashboard/user_online_status_dialog.dart`):

- **Role Rules**: Only admins (`currentUser.isAdmin`) can view users. Only owners (`currentUser.isOwner`) can toggle user roles, activate/deactivate accounts, or add new operators.
- **Online Operator Concurrency**:
  - Before an operator switches status to `isOnline = true`, Firestore checks if another user in the company is already marked online.
  - If another operator is online, the switch is blocked with message: `"<Operator Name> is currently online. They must go offline before you can go online."`
- **Session Status Badge**: Displays live session expiration timestamp or `"Session expired"`.
