import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import '../auth/login_screen.dart';
import '../canteen/food_canteen_view.dart';
import '../equipment/equipment_stock_view.dart';
import '../floor_matrix/floor_matrix_view.dart';
import '../history/tables_history_view.dart';
import '../users/company_users_view.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
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
                      style: TextStyle(color: AppColors.secondaryText),
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

        // Navigation destinations
        final navItems = [
          const _NavDestinationItem(
            icon: Icons.table_restaurant_outlined,
            activeIcon: Icons.table_restaurant,
            label: 'Running Tables',
          ),
          const _NavDestinationItem(
            icon: Icons.fastfood_outlined,
            activeIcon: Icons.fastfood,
            label: 'Food & Canteen',
          ),
          const _NavDestinationItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: 'Equipment & Stock',
          ),
          const _NavDestinationItem(
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            label: 'Tables History',
          ),
          if (currentUser.isAdmin)
            const _NavDestinationItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Associated Users',
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

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: _buildTopAppBar(context, currentUser, activeCompany),
          body: Stack(
            children: [
              Positioned.fill(child: screens[_selectedTabIndex]),
              if (_isSideMenuVisible) ...[
                // Dismiss barrier: clicking anywhere outside closes the drawer
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSideMenuVisible = false),
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.black.withAlpha(90)),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  bottom: 16,
                  child: _buildSideNavigationRail(
                    context,
                    navItems,
                    currentUser,
                    activeCompany,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    UserAccount currentUser,
    Company activeCompany,
  ) {
    return AppBar(
      backgroundColor: AppColors.cardSurface,
      elevation: 0,
      leadingWidth: 56,
      leading: IconButton(
        icon: Icon(
          _isSideMenuVisible ? Icons.menu_open : Icons.menu,
          color: AppColors.primaryText,
        ),
        onPressed: () =>
            setState(() => _isSideMenuVisible = !_isSideMenuVisible),
        tooltip: 'Toggle Navigation',
      ),
      titleSpacing: 0,
      title: Text(
        activeCompany.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        // User Profile Tag
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          decoration: BoxDecoration(
            color: AppColors.inputSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorderStroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: currentUser.isAdmin
                    ? AppColors.brandAccent.withAlpha(40)
                    : AppColors.cardBorderStroke,
                child: Icon(
                  currentUser.isAdmin ? Icons.shield : Icons.person,
                  size: 14,
                  color: currentUser.isAdmin
                      ? AppColors.brandAccentLight
                      : AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  currentUser.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: currentUser.isAdmin
                      ? AppColors.brandAccent.withAlpha(30)
                      : AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  currentUser.isAdmin ? 'ADMIN' : 'STAFF',
                  style: TextStyle(
                    color: currentUser.isAdmin
                        ? AppColors.brandAccentLight
                        : AppColors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Logout Button
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.secondaryText),
          tooltip: 'Logout',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.cardBorderStroke),
                ),
                title: const Text('Logout from Club?'),
                content: Text(
                  'Are you sure you want to log out of ${activeCompany.name}?',
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
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSideNavigationRail(
    BuildContext context,
    List<_NavDestinationItem> items,
    UserAccount currentUser,
    Company activeCompany,
  ) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(
                  Icons.dashboard_customize_outlined,
                  color: AppColors.brandAccentLight,
                  size: 20,
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
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _isSideMenuVisible = false),
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorderStroke),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = _selectedTabIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedTabIndex = index);
                      setState(() => _isSideMenuVisible = false);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
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
                              item.label,
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

          // Bottom Company Details Pill
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderStroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeCompany.name,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 13,
                      color: activeCompany.isExpired
                          ? AppColors.tableOccupied
                          : AppColors.tableAvailable,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Expires: ',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: DateFormat(
                                'dd MMM yyyy',
                              ).format(activeCompany.expiryDate),
                              style: TextStyle(
                                color: activeCompany.isExpired
                                    ? AppColors.tableOccupied
                                    : AppColors.tableAvailable,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  const _NavDestinationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
