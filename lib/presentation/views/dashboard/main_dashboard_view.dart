import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import '../auth/login_screen.dart';
import '../canteen/food_canteen_view.dart';
import '../equipment/equipment_stock_view.dart';
import '../floor_matrix/floor_matrix_view.dart';
import '../history/tables_history_view.dart';
import '../manual/user_manual_view.dart';
import '../contact_and_pricing/pricing_and_contact_view.dart';
import '../users/company_users_view.dart';
import '../../widgets/bouncing_tap.dart';
import 'user_online_status_dialog.dart';

class MainDashboardView extends StatefulWidget {
  const MainDashboardView({super.key});

  @override
  State<MainDashboardView> createState() => _MainDashboardViewState();
}

class _MainDashboardViewState extends State<MainDashboardView> {
  int _selectedTabIndex = 0;
  bool _isSideMenuVisible = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(InitAuthEvent());
  }

  void _triggerCompanyReload(String companyId) {
    context.read<FloorMatrixBloc>().add(LoadFloorMatrixEvent(companyId));
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
        if (authState.isUserDeactivated) {
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        }
        if (authState.activeCompany != null) {
          _triggerCompanyReload(authState.activeCompany!.id);
        }
      },
      builder: (context, authState) {
        // If not authenticated or subscription expired, show LoginScreen
        if (!authState.isAuthenticated) {
          if (authState.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.backgroundBase,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.brandAccent),
                    SizedBox(height: 16),
                    Text(
                      'Verifying active session...',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
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
          if (currentUser.isAdmin) const CompanyUsersView(),
        ];

        // Ensure safe index bounds if role changes
        if (_selectedTabIndex >= screens.length) {
          _selectedTabIndex = 0;
        }

        final isMobile = Responsive.isMobile(context);

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: _buildTopAppBar(
            context,
            currentUser,
            activeCompany,
            isMobile: isMobile,
          ),
          bottomNavigationBar: isMobile
              ? _buildMobileBottomNavigationBar(context, navItems)
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.01, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedTabIndex),
                        child: screens[_selectedTabIndex],
                      ),
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
    List<_NavDestinationItem> items,
  ) {
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
          selectedIndex: _selectedTabIndex,
          onDestinationSelected: _selectTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: items.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon, color: AppColors.secondaryText, size: 22),
              selectedIcon: Icon(
                item.activeIcon,
                color: AppColors.brandAccentLight,
                size: 22,
              ),
              label: item.label,
            );
          }).toList(),
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
                  // Pricing & Subscription Plans Button
                  _buildPricingAndContactButton(
                    onTap: () => setState(() => _isSideMenuVisible = false),
                  ),

                  // User Manual Action Button
                  _buildUserManualButton(
                    onTap: () => setState(() => _isSideMenuVisible = false),
                  ),

                  const SizedBox(height: 6),

                  // Owner Info Card in Drawer
                  _buildOwnerInfoCard(ownerUser, activeCompany),

                  // Bottom Company Details Card
                  _buildCompanyInfoCard(activeCompany),
                ],
              ),
            ),
          ),
        ],
      ),
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
