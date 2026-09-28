# SSAAS Club OS - Migration & Functional Requirement Overhaul TODO

## Phase 1: Setup, Dependencies & Constants
- [x] Add `cloud_firestore` to `pubspec.yaml` and install dependencies
- [x] Create `lib/core/constants/constants.dart` with `Constants.isAdmin = false`

## Phase 2: Domain Models & Entities
- [x] Create `Company` entity (`lib/domain/entities/company.dart`) with Name, number, expiryDate, createdAt, isExpired
- [x] Update `UserAccount` entity (`lib/domain/entities/user_account.dart`) with Name, Number, email, isAdmin, password, companyId
- [x] Update `RateSchedule` entity (`lib/domain/entities/rate_schedule.dart`) to support weekdays filtering (Mon..Sun)
- [x] Update `ClubTable` entity (`lib/domain/entities/club_table.dart`) with companyId, generalPrice, and customPricings
- [x] Create `StockItem` entity (`lib/domain/entities/stock_item.dart`) for Equipment & Food/Canteen
- [x] Create `TableHistoryRecord` entity (`lib/domain/entities/table_history_record.dart`)
- [x] Update `TableSession` entity (`lib/domain/entities/table_session.dart`) with customerName, closingName, items, dynamic pricing, and paymentStatus (Received / Due)

## Phase 3: Firebase Firestore Data Layer & Services
- [x] Create `FirestoreService` (`lib/data/datasources/firestore_service.dart`) for Firestore operations:
  - Companies (`companies`)
  - Associated Users (`companies/{companyId}/users`)
  - Snooker Tables (`companies/{companyId}/snookerTables`)
  - Running Tables (`companies/{companyId}/runningTables`)
  - Equipment Stock (`companies/{companyId}/equipmentStock`)
  - Food / Canteen (`companies/{companyId}/foodCanteen`)
  - Tables History (`companies/{companyId}/tablesHistory`)
- [x] Implement Repositories connecting to Firestore
- [x] Update `setupServiceLocator` in `lib/core/di/service_locator.dart`

## Phase 4: Auth & Company Management Flow
- [x] Update `AuthBloc` / State to handle Company Login, Subscription Expiry check & auto-logout
- [x] Create `CreateCompanyScreen` (`lib/presentation/views/auth/create_company_screen.dart`) (dedicated screen for company creation + initial admin user)
- [x] Create `LoginScreen` (`lib/presentation/views/auth/login_screen.dart`) with company selector, user credentials, expiry guard, and "Create Company" button visible only when `Constants.isAdmin == true`
- [x] Create `CompanyUsersView` (`lib/presentation/views/users/company_users_view.dart`) allowing Admin to create users and toggle admin status

## Phase 5: Snooker Tables & Custom Pricing
- [x] Update `TableConfigurationDialog` / Table Creator (Admin only):
  - General price
  - Custom pricings with starting time, end time, weekdays (Mon..Sun)
- [x] Implement dynamic price calculation logic matching weekdays + time of day

## Phase 6: Running Tables (Floor Matrix) & Match Workflow
- [x] Update `FloorMatrixView` & `TableCard`:
  - Show all tables with status (Running, Maintenance, Booked, Available)
  - Start table: prompts for Customer Name
  - Running table: dynamic rate display & item breakdown
  - Add snacks/drinks from Food Canteen to table billing (with stock decrement)
  - Add custom item (name, desc, price, qty) to table billing
  - Close table: prompts for Closing Name
  - Payment options: "Amount Received" (with payment method) or "Due"
  - Automatically writes match to `tablesHistory` on close

## Phase 7: Equipment Stock & Food Canteen Management
- [x] Create `FoodCanteenView` (Add/Edit/Delete/View drinks, snacks, food items with name, stock, price, desc, optional expiry date)
- [x] Create `EquipmentStockView` (Add/Edit/Delete/View sticks, chalks, table cloth, etc., with name, stock, desc, optional expiry date)

## Phase 8: Tables History View & Navigation Integration
- [x] Create `TablesHistoryView` (view all closed tables, who closed, customer name, price status Received/Due, timing, items breakdown)
- [x] Update `MainDashboardView` with top bar, subscription expiry monitor, and role-based tabs
- [x] Update `lib/main.dart` with routing / initial screen logic (Login vs Dashboard)

## Phase 9: Verification & Quality Assurance
- [x] Verify build and code correctness with `flutter analyze`
- [x] Fix any compile/lint errors and ensure seamless experience

## Phase 10: Pricing & Contact Information (New Businesses & License Renewals)
- [x] Add contact constants to `Constants` (`lib/core/constants/constants.dart`)
- [x] Create `PricingAndContactView` (`lib/presentation/views/contact_and_pricing/pricing_and_contact_view.dart`)
  - Contact Details: Dhruv Soni (`9009395674`) with one-tap Direct Call, WhatsApp chat, and Copy Number
  - Subscription Plans:
    - 28 Days = ₹489 (Starter / Monthly)
    - 84 Days = ₹1,389 (Quarterly / 3 cycles: ₹489 × 3 = ₹1,467 → Save ₹78) [Most Popular]
    - 168 Days = ₹2,889 (Half-Yearly / 6 cycles: ₹489 × 6 = ₹2,934 → Save ₹45) [Best Value]
  - Feature highlights & 3-step rapid onboarding guide
- [x] Add navigation on `LoginScreen` (`lib/presentation/views/auth/login_screen.dart`)
  - "New Club or Subscription?" interactive card with "View Plans" button
  - "View Plans & Contact" button in subscription expiry dialog
- [x] Add navigation in drawer & sidebar (`lib/presentation/views/dashboard/main_dashboard_view.dart`)
  - Desktop sidebar: dedicated "Pricing & Contact" button
  - Mobile side drawer: dedicated "Pricing & Contact" button
  - Company expiry card: quick "Renew License / View Plans" action
