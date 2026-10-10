import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import '../../blocs/expense/expense_bloc.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';
import '../canteen/food_canteen_view.dart';
import '../equipment/equipment_stock_view.dart';
import '../expense/expenses_view.dart';
import '../floor_matrix/floor_matrix_view.dart';
import '../history/tables_history_view.dart';
import '../manual/user_manual_view.dart';
import '../contact_and_pricing/pricing_and_contact_view.dart';
import '../users/company_users_view.dart';
import '../../widgets/bouncing_tap.dart';
import 'club_reminders_dialog.dart';
import 'user_online_status_dialog.dart';

class MainDashboardView extends StatefulWidget {
  const MainDashboardView({super.key});

  @override
  State<MainDashboardView> createState() => _MainDashboardViewState();
}

class _MainDashboardViewState extends State<MainDashboardView> {
  int _selectedTabIndex = 0;
  bool _isSideMenuVisible = false;
  bool _isLoggingOut = false;
  String? _loadedCompanyId;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(InitAuthEvent());
  }

  void _triggerCompanyReload(String companyId) {
    context.read<FloorMatrixBloc>().add(LoadFloorMatrixEvent(companyId));
    final now = DateTime.now();
    context.read<ExpenseBloc>().add(LoadExpensesEvent(
          companyId,
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        ));
  }

  void _selectTab(int index) {
    if (_selectedTabIndex != index) {
      AppHaptics.selection();
      setState(() {
        _selectedTabIndex = index;
        _isSideMenuVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (!authState.isAuthenticated && _isLoggingOut) {
          _isLoggingOut = false;
        }
        if (authState.isUserDeactivated) {
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        }
        if (authState.activeCompany != null &&
            _loadedCompanyId != authState.activeCompany!.id) {
          _loadedCompanyId = authState.activeCompany!.id;
          _triggerCompanyReload(authState.activeCompany!.id);
        } else if (authState.activeCompany == null) {
          _loadedCompanyId = null;
        }
        if (authState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.read<AuthBloc>().add(ClearAuthErrorEvent());
        }
      },
      builder: (context, authState) {
        final isLoggingOut = _isLoggingOut ||
            (authState.isLoading && authState.currentUser != null);

        // If not authenticated or subscription expired, show LoginScreen
        if (!authState.isAuthenticated) {
          if (authState.isLoading || _isLoggingOut) {
            return Scaffold(
              backgroundColor: AppColors.backgroundBase,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.brandAccent),
                    const SizedBox(height: 16),
                    Text(
                      _isLoggingOut
                          ? 'Securing session & signing off...'
                          : 'Verifying active session...',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const LoginScreen();
        }

        final currentUser = authState.currentUser!;
        final activeCompany = authState.activeCompany!;

        UserAccount? ownerUser;
        for (final u in authState.companyUsers) {
          if (u.isOwner) {
            ownerUser = u;
            break;
          }
        }
        if (ownerUser == null) {
          for (final u in authState.companyUsers) {
            if (u.isAdmin) {
              ownerUser = u;
              break;
            }
          }
        }
        if (ownerUser == null && (currentUser.isOwner || currentUser.isAdmin)) {
          ownerUser = currentUser;
        }

        // Navigation destinations
        final navItems = [
          const _NavDestinationItem(
            icon: Icons.table_restaurant_outlined,
            activeIcon: Icons.table_restaurant,
            label: 'Tables',
            fullLabel: 'Running Tables',
          ),
          const _NavDestinationItem(
            icon: Icons.fastfood_outlined,
            activeIcon: Icons.fastfood,
            label: 'Canteen',
            fullLabel: 'Food & Canteen',
          ),
          const _NavDestinationItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: 'Equipment',
            fullLabel: 'Equipment & Stock',
          ),
          const _NavDestinationItem(
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            label: 'History',
            fullLabel: 'Tables History',
          ),
          const _NavDestinationItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Expenses',
            fullLabel: 'Expense Management',
          ),
          if (currentUser.isAdmin)
            const _NavDestinationItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Users',
              fullLabel: 'Associated Users',
            ),
        ];

        final List<Widget> screens = [
          const FloorMatrixView(),
          const FoodCanteenView(),
          const EquipmentStockView(),
          const TablesHistoryView(),
          const ExpensesView(),
          if (currentUser.isAdmin) const CompanyUsersView(),
        ];

        // Ensure safe index bounds if role changes
        if (_selectedTabIndex >= screens.length) {
          _selectedTabIndex = 0;
        }

        final isMobile = Responsive.isMobile(context);

        final scaffold = Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: _buildTopAppBar(
            context,
            currentUser,
            activeCompany,
            isMobile: isMobile,
          ),
          bottomNavigationBar: isMobile
              ? _buildMobileBottomNavigationBar(context, currentUser)
              : null,
          body: Row(
            children: [
              // Persistent Sidebar on Tablet / Desktop
              if (!isMobile)
                _buildDesktopSidebar(
                  context,
                  navItems,
                  currentUser,
                  activeCompany,
                  ownerUser,
                ),

              // Main Screen Area with Smooth AnimatedSwitcher Transition
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _selectedTabIndex.clamp(0, screens.length - 1),
                      children: screens,
                    ),

                    // Mobile Drawer Barrier & Floating Menu (if opened via hamburger)
                    if (isMobile && _isSideMenuVisible) ...[
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _isSideMenuVisible = false),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: Colors.black.withAlpha(120),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        bottom: 8,
                        child: _buildSideNavigationRail(
                          context,
                          currentUser,
                          activeCompany,
                          ownerUser,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

        if (!isLoggingOut) {
          return scaffold;
        }

        return Stack(
          children: [
            scaffold,
            const Positioned.fill(
              child: ModalBarrier(
                dismissible: false,
                color: Color(0xCC000000),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Material(
                  color: AppColors.cardSurface,
                  elevation: 16,
                  shadowColor: Colors.black.withAlpha(160),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.cardBorderStroke),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: AppColors.brandAccent,
                            strokeWidth: 3.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Logging out from club...',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Closing shift and securing session for ${currentUser.name}.',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    UserAccount currentUser,
    Company activeCompany, {
    required bool isMobile,
  }) {
    return AppBar(
      backgroundColor: AppColors.cardSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: isMobile ? 56 : 72,
      leading: isMobile
          ? IconButton(
              icon: Icon(
                _isSideMenuVisible ? Icons.menu_open : Icons.menu,
                color: AppColors.primaryText,
              ),
              onPressed: () {
                AppHaptics.light();
                setState(() => _isSideMenuVisible = !_isSideMenuVisible);
              },
              tooltip: 'Menu',
            )
          : Padding(
              padding: const EdgeInsets.only(left: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  "assets/logo.png",
                  height: 38,
                  width: 38,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.sports_esports,
                    color: AppColors.brandAccentLight,
                  ),
                ),
              ),
            ),
      titleSpacing: isMobile ? 0 : 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMobile) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                "assets/logo.png",
                height: 24,
                width: 24,
                errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              activeCompany.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // User Profile Tag with Live Shift Status Indicator
        Tooltip(
          message: 'Tap to view shift & change Online/Offline status',
          child: BouncingTap(
            onTap: () {
              AppHaptics.selection();
              showDialog(
                context: context,
                builder: (_) => UserOnlineStatusDialog(
                  currentUser: currentUser,
                  activeCompany: activeCompany,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.48,
              ),
              decoration: BoxDecoration(
                color: currentUser.isOnline
                    ? AppColors.tableAvailable.withAlpha(20)
                    : AppColors.inputSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: currentUser.isOnline
                      ? AppColors.tableAvailable.withAlpha(90)
                      : AppColors.cardBorderStroke,
                  width: currentUser.isOnline ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentUser.isOnline
                          ? AppColors.tableAvailable
                          : AppColors.textDisabled,
                      shape: BoxShape.circle,
                      boxShadow: currentUser.isOnline
                          ? [
                              BoxShadow(
                                color: AppColors.tableAvailable.withAlpha(140),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      currentUser.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: currentUser.isOnline
                          ? AppColors.tableAvailable.withAlpha(35)
                          : (currentUser.isOwner
                              ? const Color(0xFFFFB300).withAlpha(35)
                              : (currentUser.isAdmin
                                  ? AppColors.brandAccent.withAlpha(30)
                                  : AppColors.inputSurface)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currentUser.isOnline
                          ? 'ONLINE'
                          : (currentUser.isOwner
                              ? 'OWNER'
                              : (currentUser.isAdmin ? 'ADMIN' : 'STAFF')),
                      style: TextStyle(
                        color: currentUser.isOnline
                            ? AppColors.tableAvailable
                            : (currentUser.isOwner
                                ? const Color(0xFFFFB300)
                                : (currentUser.isAdmin
                                    ? AppColors.brandAccentLight
                                    : AppColors.secondaryText)),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Logout Button
        IconButton(
          icon: const Icon(
            Icons.logout,
            color: AppColors.secondaryText,
            size: 20,
          ),
          tooltip: 'Logout',
          onPressed: () => _confirmLogout(context, activeCompany.name),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildMobileBottomNavigationBar(
    BuildContext context,
    UserAccount currentUser,
  ) {
    final selectedIndex = _selectedTabIndex == 0
        ? 0
        : (_selectedTabIndex == 3 ? 1 : 2);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorderStroke, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: AppColors.cardSurface,
          indicatorColor: AppColors.brandAccent.withAlpha(45),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index == 2) {
              _showMobileMoreSheet(context, currentUser);
              return;
            }
            _selectTab(index == 1 ? 3 : 0);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.table_restaurant_outlined, color: AppColors.secondaryText, size: 22),
              selectedIcon: Icon(Icons.table_restaurant, color: AppColors.brandAccentLight, size: 22),
              label: 'Tables',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: AppColors.secondaryText, size: 22),
              selectedIcon: Icon(Icons.history, color: AppColors.brandAccentLight, size: 22),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz, color: AppColors.secondaryText, size: 22),
              selectedIcon: Icon(Icons.more_horiz, color: AppColors.brandAccentLight, size: 22),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMobileMoreSheet(
    BuildContext context,
    UserAccount currentUser,
  ) {
    AppHaptics.selection();
    return showAdaptiveModal<void>(
      context: context,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * .9,
          maxWidth: 580,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.cardBorderStroke),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('More', style: TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Club operations and reports', style: TextStyle(color: AppColors.secondaryText)),
              const SizedBox(height: 16),
              _MobileMoreDestination(icon: Icons.account_balance_wallet_outlined, label: 'Expenses', subtitle: 'Track and analyze club costs', onTap: () { Navigator.of(sheetContext).pop(); _selectTab(4); }),
              _MobileMoreDestination(icon: Icons.fastfood_outlined, label: 'Canteen', subtitle: 'Manage food and canteen orders', onTap: () { Navigator.of(sheetContext).pop(); _selectTab(1); }),
              _MobileMoreDestination(icon: Icons.inventory_2_outlined, label: 'Equipment', subtitle: 'Manage equipment and stock', onTap: () { Navigator.of(sheetContext).pop(); _selectTab(2); }),
              if (currentUser.isAdmin)
                _MobileMoreDestination(icon: Icons.people_outline, label: 'Users', subtitle: 'Manage associated users', onTap: () { Navigator.of(sheetContext).pop(); _selectTab(5); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    List<_NavDestinationItem> items,
    UserAccount currentUser,
    Company activeCompany,
    UserAccount? ownerUser,
  ) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          right: BorderSide(color: AppColors.cardBorderStroke, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.dashboard_customize_outlined,
                  color: AppColors.brandAccentLight,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorderStroke),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = _selectedTabIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: InkWell(
                    onTap: () => _selectTab(index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandAccent.withAlpha(40)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.brandAccent.withAlpha(120),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? AppColors.brandAccentLight
                                : AppColors.secondaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.fullLabel,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryText
                                    : AppColors.secondaryText,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Reminders & Bookings Button (Admins only)
          _buildRemindersDrawerButton(currentUser, activeCompany),

          // Password & Account Security
          _buildPasswordSecurityButton(currentUser),

          // Download App (Google Drive / APK link)
          _buildDownloadAppButton(),

          // Pricing & Subscription Plans Button
          _buildPricingAndContactButton(),

          // User Manual Action Button
          _buildUserManualButton(),

          // Owner Info Card in Drawer
          _buildOwnerInfoCard(ownerUser, activeCompany),

          // Bottom Company Details Card
          _buildCompanyInfoCard(activeCompany),
        ],
      ),
    );
  }

  Widget _buildSideNavigationRail(
    BuildContext context,
    UserAccount currentUser,
    Company activeCompany,
    UserAccount? ownerUser,
  ) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 28,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.brandAccentLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CLUB INFO & SHORTCUTS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.brandAccentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => _isSideMenuVisible = false),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorderStroke),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentUser.isAdmin)
                    BlocBuilder<FloorMatrixBloc, FloorMatrixState>(
                      builder: (context, matrixState) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _DrawerSectionLabel('OPERATIONS'),
                          _buildCompactDrawerAction(
                            icon: Icons.alarm_add_rounded,
                            label: 'Reminders & bookings',
                            subtitle: 'Manage upcoming table alerts',
                            badge: matrixState.activeUpcomingReminders.isEmpty
                                ? null
                                : '${matrixState.activeUpcomingReminders.length}',
                            onTap: () {
                              setState(() => _isSideMenuVisible = false);
                              showDialog(
                                context: context,
                                builder: (_) => ClubRemindersDialog(
                                  activeCompany: activeCompany,
                                  currentUser: currentUser,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  const _DrawerSectionLabel('ACCOUNT & HELP'),
                  _buildCompactDrawerAction(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    subtitle: 'Profile details, daily shifts & security',
                    onTap: () {
                      setState(() => _isSideMenuVisible = false);
                      AppNavigation.pushSmooth(context, const ProfileScreen());
                    },
                  ),
                  _buildCompactDrawerAction(
                    icon: Icons.menu_book_rounded,
                    label: 'User manual',
                    subtitle: 'Operations and guides',
                    onTap: () {
                      setState(() => _isSideMenuVisible = false);
                      AppNavigation.pushSmooth(context, const UserManualView());
                    },
                  ),
                  _buildCompactDrawerAction(
                    icon: Icons.android_rounded,
                    label: 'Download app',
                    subtitle: 'Get the latest Android APK',
                    onTap: () {
                      setState(() => _isSideMenuVisible = false);
                      _handleDownloadAppClick(context);
                    },
                  ),
                  _buildCompactDrawerAction(
                    icon: Icons.sell_outlined,
                    label: 'Pricing & contact',
                    subtitle: 'Plans and support details',
                    onTap: () {
                      setState(() => _isSideMenuVisible = false);
                      AppNavigation.pushSmooth(context, const PricingAndContactView());
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 5),
                    child: Divider(color: AppColors.cardBorderStroke),
                  ),
                  const _DrawerSectionLabel('CLUB CONTACT'),
                  _buildOwnerInfoCard(ownerUser, activeCompany),
                  const _DrawerSectionLabel('SUBSCRIPTION'),
                  _buildCompanyInfoCard(activeCompany),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDrawerAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandAccentLight, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10.5)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.brandAccent.withAlpha(45), borderRadius: BorderRadius.circular(10)),
                  child: Text(badge, style: const TextStyle(color: AppColors.brandAccentLight, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersDrawerButton(
    UserAccount currentUser,
    Company activeCompany, {
    VoidCallback? onTap,
  }) {
    if (!currentUser.isAdmin) return const SizedBox.shrink();

    return BlocBuilder<FloorMatrixBloc, FloorMatrixState>(
      builder: (context, matrixState) {
        final activeCount = matrixState.activeUpcomingReminders.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: InkWell(
            onTap: () {
              AppHaptics.selection();
              onTap?.call();
              showDialog(
                context: context,
                builder: (_) => ClubRemindersDialog(
                  activeCompany: activeCompany,
                  currentUser: currentUser,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withAlpha(22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB300).withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alarm_add_rounded,
                    color: Color(0xFFFFB300),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminders & Bookings',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Add booking alerts',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (activeCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFFFFB300),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricingAndContactButton({VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap?.call();
          AppNavigation.pushSmooth(context, const PricingAndContactView());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandAccent.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandAccent.withAlpha(85),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.sell_outlined,
                color: AppColors.brandAccentLight,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pricing & Contact',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Plans from ₹489 • Support',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.brandAccentLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserManualButton({VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap?.call();
          AppNavigation.pushSmooth(context, const UserManualView());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandAccent.withAlpha(22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandAccent.withAlpha(70),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: AppColors.brandAccentLight,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Manual',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Operations & guides',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.brandAccentLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSecurityButton(
    UserAccount currentUser, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap?.call();
          AppNavigation.pushSmooth(
            context,
            const ProfileScreen(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF673AB7).withAlpha(24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF673AB7).withAlpha(85),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: Color(0xFFB388FF),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'View profile, shifts & security',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Color(0xFFB388FF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadAppButton({VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap?.call();
          _handleDownloadAppClick(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00E676).withAlpha(70),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.android_rounded,
                color: Color(0xFF00E676),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download App',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Get latest Android APK',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 13,
                color: Color(0xFF00E676),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownloadAppClick(BuildContext context) async {
    try {
      final config = await sl<FirestoreService>().getAppDownloadConfig();
      if (!context.mounted) return;

      if (!config.hasValidUrl) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cardBorderStroke),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.install_mobile_rounded,
                  color: AppColors.brandAccentLight,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text('Download App'),
              ],
            ),
            content: const Text(
              'No download link has been published yet. Please contact your club administrator or support for the latest APK.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final uri = Uri.tryParse(config.downloadUrl.trim());
      if (uri == null || !uri.hasScheme) {
        throw 'Invalid download link format';
      }

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: config.downloadUrl));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download URL copied to clipboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open download link: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildOwnerInfoCard(UserAccount? owner, Company activeCompany) {
    final ownerName = owner != null && owner.name.trim().isNotEmpty
        ? owner.name.trim()
        : 'Club Owner';
    final ownerPhone = owner != null && owner.phoneNumber.trim().isNotEmpty
        ? owner.phoneNumber.trim()
        : activeCompany.number.trim();
    final ownerEmail = owner?.email.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB300).withAlpha(70),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withAlpha(35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFB300).withAlpha(120),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFB300),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Club Owner',
                      style: TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.w600,
                        fontSize: 9.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withAlpha(30),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withAlpha(110),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'OWNER',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          if (ownerPhone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 12,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    ownerPhone,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (ownerEmail != null && ownerEmail.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 12,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    ownerEmail,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyInfoCard(Company activeCompany) {
    final now = DateTime.now();
    final expiry = activeCompany.expiryDate;
    final isExpired = activeCompany.isExpired;
    final diffDays = expiry.difference(now).inDays;
    final isNearExpiry = !isExpired && diffDays <= 14;

    final Color statusColor = isExpired
        ? AppColors.tableOccupied
        : isNearExpiry
            ? AppColors.warning
            : AppColors.tableAvailable;

    final String statusLabel = isExpired
        ? 'EXPIRED'
        : isNearExpiry
            ? 'RENEW SOON'
            : 'ACTIVE';

    final String formattedDate = DateFormat('dd MMM yyyy').format(expiry);
    final String expiryText;
    if (isExpired) {
      expiryText = 'Expired on $formattedDate';
    } else if (diffDays <= 0) {
      expiryText = 'Expires today ($formattedDate)';
    } else if (diffDays == 1) {
      expiryText = 'Expires tomorrow ($formattedDate)';
    } else if (diffDays <= 30) {
      expiryText = 'Expires in $diffDays days ($formattedDate)';
    } else {
      expiryText = 'Valid till $formattedDate';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNearExpiry || isExpired
              ? statusColor.withAlpha(90)
              : AppColors.cardBorderStroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activeCompany.name,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withAlpha(120),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 13,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  activeCompany.number,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.event_outlined,
                  size: 13,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  expiryText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isNearExpiry || isExpired) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                AppHaptics.selection();
                AppNavigation.pushSmooth(
                  context,
                  const PricingAndContactView(),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withAlpha(100), width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew_rounded, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Renew License / View Plans',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, String companyName) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.tableOccupied, size: 22),
            SizedBox(width: 10),
            Text('Logout from Club?'),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of $companyName?',
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isLoggingOut = true);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tableOccupied,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _NavDestinationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String fullLabel;

  const _NavDestinationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.fullLabel,
  });
}

class _MobileMoreDestination extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MobileMoreDestination({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () { AppHaptics.light(); onTap(); },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.inputSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorderStroke)),
          child: Row(children: [
            Icon(icon, color: AppColors.brandAccentLight),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ]),
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;

  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 5),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
