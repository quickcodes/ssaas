import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/club_branch.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/canteen_pos/canteen_pos_bloc.dart';
import '../../blocs/equipment/equipment_bloc.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import '../../blocs/shift_audit/shift_audit_bloc.dart';
import '../analytics/analytics_export_view.dart';
import '../canteen_pos/canteen_pos_view.dart';
import '../equipment/equipment_lifecycle_view.dart';
import '../expense/expense_manager_view.dart';
import '../floor_matrix/floor_matrix_view.dart';
import '../shift_audit/shift_handover_view.dart';

class MainDashboardView extends StatefulWidget {
  const MainDashboardView({super.key});

  @override
  State<MainDashboardView> createState() => _MainDashboardViewState();
}

class _MainDashboardViewState extends State<MainDashboardView> {
  int _selectedTabIndex = 0;
  bool _isSideMenuVisible = true;

  @override
  void initState() {
    super.initState();
    // Initialize Auth and load first branch
    context.read<AuthBloc>().add(InitAuthEvent());
  }

  void _triggerBranchReload(String branchId) {
    context.read<FloorMatrixBloc>().add(LoadFloorMatrixEvent(branchId));
    context.read<CanteenPosBloc>().add(LoadCanteenCatalogEvent(branchId));
    context.read<EquipmentBloc>().add(LoadEquipmentEvent(branchId));
    context.read<ShiftAuditBloc>().add(LoadShiftAuditEvent(branchId));
    context.read<ExpenseBloc>().add(LoadExpensesEvent(branchId));
    context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(branchId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.activeBranch != null) {
          _triggerBranchReload(authState.activeBranch!.id);
        }
      },
      builder: (context, authState) {
        if (authState.isLoading ||
            authState.activeBranch == null ||
            authState.currentUser == null) {
          if (!authState.isLoading) {
            return _buildEmptyWorkspace(authState);
          }
          return const Scaffold(
            backgroundColor: AppColors.backgroundBase,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.brandAccent),
                  SizedBox(height: 16),
                  Text(
                    'Loading Snooker & Billiards Club System...',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          );
        }

        final currentUser = authState.currentUser!;
        final activeBranch = authState.activeBranch!;
        final branches = authState.branches;
        final availableUsers = authState.availableUsers;

        // Navigation items based on RBAC
        final navItems = [
          const _NavDestinationItem(
            icon: Icons.table_restaurant_outlined,
            activeIcon: Icons.table_restaurant,
            label: 'Floor Matrix',
          ),
          const _NavDestinationItem(
            icon: Icons.point_of_sale_outlined,
            activeIcon: Icons.point_of_sale,
            label: 'Canteen POS',
          ),
          const _NavDestinationItem(
            icon: Icons.inventory_outlined,
            activeIcon: Icons.inventory,
            label: 'Equipment Wear',
          ),
          const _NavDestinationItem(
            icon: Icons.assignment_turned_in_outlined,
            activeIcon: Icons.assignment_turned_in,
            label: 'Shift Handover',
          ),
          const _NavDestinationItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Expense Ledger',
          ),
          const _NavDestinationItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Analytics & Export',
          ),
        ];

        final List<Widget> screens = [
          FloorMatrixView(
            onOpenCanteen: () => setState(() => _selectedTabIndex = 1),
          ),
          const CanteenPosView(),
          const EquipmentLifecycleView(),
          const ShiftHandoverView(),
          const ExpenseManagerView(),
          const AnalyticsExportView(),
        ];

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: _buildTopAppBar(
            context,
            currentUser,
            activeBranch,
            branches,
            availableUsers,
          ),
          body: Stack(
            children: [
              Positioned.fill(child: screens[_selectedTabIndex]),
              if (_isSideMenuVisible) ...[
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Material(
                    color: AppColors.cardSurface,
                    elevation: 10,
                    child: NavigationRail(
                      backgroundColor: AppColors.cardSurface,
                      selectedIndex: _selectedTabIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedTabIndex = index);
                      },
                      labelType: NavigationRailLabelType.all,
                      unselectedIconTheme: const IconThemeData(
                        color: AppColors.secondaryText,
                      ),
                      selectedIconTheme: const IconThemeData(
                        color: AppColors.brandAccentLight,
                      ),
                      unselectedLabelTextStyle: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                      selectedLabelTextStyle: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      indicatorColor: AppColors.brandAccent.withAlpha(40),
                      destinations: navItems.map((item) {
                        return NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.activeIcon),
                          label: Text(item.label),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyWorkspace(AuthState authState) => Scaffold(
    backgroundColor: AppColors.backgroundBase,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 52,
              color: AppColors.brandAccentLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your club workspace is ready',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              authState.availableUsers.isEmpty
                  ? 'No demo data has been added. Start by creating the details for your own club.'
                  : 'Choose your operator account to sign in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            if (authState.availableUsers.isEmpty)
              ElevatedButton.icon(
                onPressed: () => _showInitialSetup(context),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('SET UP MY CLUB'),
              )
            else
              ...authState.availableUsers.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.read<AuthBloc>().add(LoginUserEvent(user)),
                    icon: const Icon(Icons.login),
                    label: Text('SIGN IN AS ${user.name}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showInitialSetup(BuildContext context) async {
    final club = TextEditingController(),
        owner = TextEditingController(),
        email = TextEditingController();
    final standard = TextEditingController(text: '150'),
        peak = TextEditingController(text: '250');
    final team = <_PendingUser>[];
    var tables = 1, error = '';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: const Text(
            'Set up your first club',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Only details you enter are created. You can add more tables and team members later.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: club,
                    decoration: const InputDecoration(labelText: 'Club name *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: owner,
                    decoration: const InputDecoration(
                      labelText: 'Owner name *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Owner email *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: standard,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Standard ₹ / hour',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: peak,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Peak ₹ / hour',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: tables,
                    decoration: const InputDecoration(
                      labelText: 'Tables to create now',
                    ),
                    dropdownColor: AppColors.cardSurface,
                    items: List.generate(12, (i) => i + 1)
                        .map(
                          (count) => DropdownMenuItem(
                            value: count,
                            child: Text(count.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialog(() => tables = value ?? 1),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TEAM & ROLE ACCESS',
                      style: TextStyle(
                        color: AppColors.brandAccentLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...team.map(
                    (member) => ListTile(
                      title: Text(member.name),
                      subtitle: Text(member.role.displayName),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setDialog(() => team.remove(member)),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final member = await _showAddTeamUser(context);
                      if (member != null) setDialog(() => team.add(member));
                    },
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Add team member and role'),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: const TextStyle(color: AppColors.tableOccupied),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final stdRate = double.tryParse(standard.text.trim()),
                    peakRate = double.tryParse(peak.text.trim());
                if (club.text.trim().isEmpty ||
                    owner.text.trim().isEmpty ||
                    email.text.trim().isEmpty ||
                    stdRate == null ||
                    peakRate == null ||
                    stdRate <= 0 ||
                    peakRate <= 0) {
                  setDialog(
                    () => error =
                        'Enter club and owner details, plus valid hourly rates.',
                  );
                  return;
                }
                final uuid = const Uuid(), branchId = uuid.v4();
                final branch = ClubBranch(
                  id: branchId,
                  name: club.text.trim(),
                  address: '',
                  phone: '',
                  defaultStandardHourlyRate: stdRate,
                  defaultPeakHourlyRate: peakRate,
                );
                final account = UserAccount(
                  id: uuid.v4(),
                  name: owner.text.trim(),
                  email: email.text.trim(),
                  role: UserRole.superAdmin,
                  branchId: branchId,
                );
                final users = <UserAccount>[account];
                users.addAll(
                  team.map(
                    (member) => UserAccount(
                      id: uuid.v4(),
                      name: member.name,
                      email: member.email,
                      role: member.role,
                      branchId: branchId,
                    ),
                  ),
                );
                final initialTables = List.generate(
                  tables,
                  (index) => ClubTable(
                    id: uuid.v4(),
                    branchId: branchId,
                    tableNumber: index + 1,
                    name: 'Table ${index + 1}',
                    type: TableType.standardSnooker12ft,
                    specsDescription:
                        'Configure table specifications from the floor matrix.',
                    status: TableStatus.available,
                    standardRatePerHour: stdRate,
                    peakRatePerHour: peakRate,
                    fixedFrameRate: stdRate,
                    vipRatePerHour: peakRate,
                  ),
                );
                context.read<AuthBloc>().add(
                  CreateInitialWorkspaceEvent(
                    branch: branch,
                    owner: account,
                    users: users,
                    tables: initialTables,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CREATE WORKSPACE'),
            ),
          ],
        ),
      ),
    );
    // These controllers are captured by the dialog route. Leaving their
    // lifetime to the route avoids disposing them during its final teardown.
  }

  Future<_PendingUser?> _showAddTeamUser(BuildContext context) async {
    final name = TextEditingController(), email = TextEditingController();
    var role = UserRole.counterAdmin;
    return showDialog<_PendingUser>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: const Text('Add team member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
              ),
              DropdownButtonFormField<UserRole>(
                initialValue: role,
                items: UserRole.values
                    .where((item) => item != UserRole.superAdmin)
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => role = value ?? role),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty) {
                  Navigator.pop(
                    dialogContext,
                    _PendingUser(name.text.trim(), email.text.trim(), role),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    UserAccount currentUser,
    ClubBranch activeBranch,
    List<ClubBranch> branches,
    List<UserAccount> availableUsers,
  ) {
    return AppBar(
      titleSpacing: 20,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Logo & Brand
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandAccent),
              ),
              child: const Icon(
                Icons.sports_esports,
                color: AppColors.brandAccentLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUECLUB OS',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Snooker & Billiards Management',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Multi-Branch Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.inputSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeBranch.id,
                  dropdownColor: AppColors.cardSurface,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.secondaryText,
                    size: 18,
                  ),
                  items: branches.map((b) {
                    return DropdownMenuItem(
                      value: b.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront,
                            size: 16,
                            color: AppColors.brandAccentLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            b.name,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newBranchId) {
                    if (newBranchId != null) {
                      context.read<AuthBloc>().add(
                        SwitchBranchEvent(newBranchId),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),

            // SaaS Subscription Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandAccent.withAlpha(80)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: AppColors.brandAccentLight,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '₹200 / mo Micro-SaaS Active',
                    style: TextStyle(
                      color: AppColors.brandAccentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: _isSideMenuVisible ? 'Hide side menu' : 'Show side menu',
          onPressed: () => setState(() {
            _isSideMenuVisible = !_isSideMenuVisible;
          }),
          icon: Icon(
            _isSideMenuVisible ? Icons.menu_open : Icons.menu,
            color: AppColors.primaryText,
          ),
        ),
        // Role & Active Operator Switcher for Demo
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorderStroke),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<UserRole>(
              value: currentUser.role,
              dropdownColor: AppColors.cardSurface,
              icon: const Icon(
                Icons.switch_account,
                color: AppColors.brandAccentLight,
                size: 18,
              ),
              items: UserRole.values.map((role) {
                Color badgeCol;
                switch (role) {
                  case UserRole.superAdmin:
                    badgeCol = AppColors.brandAccentLight;
                    break;
                  case UserRole.counterAdmin:
                    badgeCol = AppColors.tableAvailable;
                    break;
                  case UserRole.attendantMarker:
                    badgeCol = AppColors.tableReserved;
                    break;
                }

                return DropdownMenuItem(
                  value: role,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: badgeCol,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        role.displayName,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null) {
                  context.read<AuthBloc>().add(SwitchRoleEvent(newRole));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NavDestinationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestinationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _PendingUser {
  final String name;
  final String email;
  final UserRole role;
  const _PendingUser(this.name, this.email, this.role);
}
