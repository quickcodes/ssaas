# SSAAS Expense Management Feature Implementation Plan

This TODO document tracks the step-by-step development of the Expense Management module in SSAAS (`Constants.appName`).

> **Note for AI Agent**: You MUST check off each task (`- [x]`) as you complete it during implementation. Follow Clean Architecture, BLoC pattern, Dark Obsidian theme tokens, and FVM tool requirements defined in `AGENTS.md`.

---

## Phase 1: Domain Entity & Data Layer
- [x] **Task 1.1: Create Domain Entity `ClubExpense`**
  - File: `lib/domain/entities/club_expense.dart`
  - Fields: `id`, `companyId`, `title`, `amount`, `category` (Utilities, Maintenance, Inventory Stock, Rent, Staff Salary, Other), `expenseDate`, `addedBy` (operator name), `addedById`, `paymentMethod` (Cash, UPI, Card), `notes`, `createdAt`.
  - Extend `Equatable`, implement `copyWith()`, `toMap()`, and `factory ClubExpense.fromMap(String id, Map<String, dynamic> map)`.

- [x] **Task 1.2: Add Firestore Queries & Quota Tracking in `FirestoreService`**
  - File: `lib/data/datasources/firestore_service.dart`
  - Firestore Subcollection: `companies/{companyId}/expenses/{expenseId}`
  - Methods:
    - `Stream<List<ClubExpense>> watchCompanyExpenses(String companyId, {DateTime? startDate, DateTime? endDate})`
    - `Future<List<ClubExpense>> getCompanyExpenses(String companyId, {DateTime? startDate, DateTime? endDate})`
    - `Future<void> saveExpense(ClubExpense expense)` (using `SetOptions(merge: true)`)
    - `Future<void> deleteExpense(String companyId, String expenseId)`
  - Integrate quota tracking: `trackRead`, `trackWrite`, `trackDelete`.

---

## Phase 2: State Management (BLoC Layer)
- [x] **Task 2.1: Create `ExpenseBloc`, `ExpenseEvent`, and `ExpenseState`**
  - File: `lib/presentation/blocs/expense/expense_bloc.dart`
  - **Events**:
    - `LoadExpensesEvent(String companyId, {DateTime? startDate, DateTime? endDate})`
    - `AddExpenseEvent(ClubExpense expense)`
    - `DeleteExpenseEvent({required String companyId, required String expenseId})`
    - `SetExpenseDateFilterEvent({required DateTime startDate, required DateTime endDate, String filterPreset})`
    - `ClearExpenseMessagesEvent()`
  - **State**:
    - `expenses` (List<ClubExpense>), `filteredExpenses`
    - `startDate`, `endDate`, `activePreset` ('Today', 'This Week', 'This Month', 'All Time', 'Custom')
    - Computed metrics: `totalExpenseAmount`, `categoryBreakdown` (Map<String, double>)
    - `isLoading`, `errorMessage`, `successMessage`
  - **Permission Check in BLoC**:
    - Enforce permission validation when adding/deleting expense: Only allow if operator is Owner (`isOwner == true`), Admin (`isAdmin == true`), or currently Online (`isOnline == true`).

---

## 3. UI Views, Analytics & Modal Dialogs
- [x] **Task 3.1: Create Add/Edit Expense Dialog (`AddExpenseDialog`)**
  - File: `lib/presentation/views/expense/add_expense_dialog.dart`
  - Use `Responsive.showAdaptiveModal()` and `SingleChildScrollView` layout bounds.
  - Form Fields:
    - Expense Title (Text input)
    - Amount (₹) with numeric regex formatter `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))`
    - Category Dropdown (Utilities, Maintenance, Stock/Inventory, Salaries, Rent, Other)
    - Payment Method Selector (Cash, UPI, Card chips)
    - Date & Time Picker (`expenseDate`)
    - Notes (Optional)
  - Validate permissions: Show warning if operator is offline employee.

- [x] **Task 3.2: Create Expense Analytics Breakdown Component**
  - File: `lib/presentation/views/expense/expense_analytics_card.dart`
  - Displays Total Spent for selected period (Today / This Week / This Month).
  - Integrates `fl_chart` PieChart / BarChart for category percentage distribution.
  - Renders category-wise legend with monetary totals and percentage badges.

- [x] **Task 3.3: Create Main Expense Management Screen (`ExpensesView`)**
  - File: `lib/presentation/views/expense/expenses_view.dart`
  - Top Bar Header: Date range preset filter pills (Today, This Week, This Month, All Time, Custom Range picker).
  - Floating/Header Action: "+ Add Expense" button (visible to all, active for Owner / Admin / Online Employee).
  - Analytics Summary Section (`ExpenseAnalyticsCard`).
  - Search / Category filter input.
  - Expense Cards List: Title, category badge, date/time, amount in ₹, payment method tag, operator attribution ("Added byMarker 1"), and delete action (for authorized users).
  - Empty state fallback (`EmptyStateCard`).

---

## 4. Integration & Navigation
- [x] **Task 4.1: Integrate Expenses in `MainDashboardView`**
  - File: `lib/presentation/views/dashboard/main_dashboard_view.dart`
  - Add `BlocProvider<ExpenseBloc>` in widget hierarchy or global providers in `main.dart`.
  - Add Expenses destination tab in navigation sidebar (Desktop/Tablet) and bottom navigation bar (Mobile).
  - Trigger `LoadExpensesEvent` on company selection/switch.

---

## 5. Testing & Verification
- [ ] **Task 5.1: Run Static Analyzer & Unit Verification**
  - Run `fvm flutter analyze` to verify 0 static errors or warnings.
  - Run `fvm flutter test` to verify existing tests continue to pass.
