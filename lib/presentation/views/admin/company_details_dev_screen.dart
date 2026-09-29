import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/club_reminder.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/stock_item.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';
import '../../widgets/bouncing_tap.dart';

class CompanyDetailsDevScreen extends StatefulWidget {
  final Company initialCompany;

  const CompanyDetailsDevScreen({
    super.key,
    required this.initialCompany,
  });

  @override
  State<CompanyDetailsDevScreen> createState() =>
      _CompanyDetailsDevScreenState();
}

class _CompanyDetailsDevScreenState extends State<CompanyDetailsDevScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _revealedPasswords = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = sl<FirestoreService>();
    final isMobile = Responsive.isMobile(context);

    return StreamBuilder<Company?>(
      stream: firestoreService.watchCompany(widget.initialCompany.id),
      initialData: widget.initialCompany,
      builder: (context, snapshot) {
        final company = snapshot.data ?? widget.initialCompany;
        final isExpired = company.isExpired;
        final now = DateTime.now();
        final difference = company.expiryDate.difference(now).inDays;
        final formattedExpiry =
            DateFormat('dd MMM yyyy').format(company.expiryDate);

        final statusText = isExpired
            ? 'Expired (${difference.abs()}d ago)'
            : 'Active ($difference days left)';

        final statusColor =
            isExpired ? AppColors.tableOccupied : AppColors.tableAvailable;

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: AppBar(
            backgroundColor: AppColors.cardSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryText, size: 20),
              onPressed: () {
                AppHaptics.light();
                Navigator.of(context).pop();
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Code: ${company.code} • ${company.number.isNotEmpty ? company.number : "No Phone"}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // Removed redundant calendar icon from AppBar since Change Expiry is already on the card
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        // Subscription Status Banner
                        _buildSubscriptionBanner(
                          company: company,
                          statusText: statusText,
                          statusColor: statusColor,
                          formattedExpiry: formattedExpiry,
                          isExpired: isExpired,
                        ),
                        const SizedBox(height: 12),

                        // Analytics Summary Matrix
                        _buildKpiMetricsBar(
                          companyId: company.id,
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ),
                ),

                // Refined Pinned Pill Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    height: 56,
                    child: Container(
                      color: AppColors.backgroundBase,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.cardBorderStroke),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicator: BoxDecoration(
                            color: AppColors.brandAccent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.secondaryText,
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge_outlined, size: 15),
                                  SizedBox(width: 6),
                                  Text('Operators & Credentials'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sports_baseball_outlined, size: 15),
                                  SizedBox(width: 6),
                                  Text('Snooker Tables'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_rounded, size: 15),
                                  SizedBox(width: 6),
                                  Text('Match History'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 15),
                                  SizedBox(width: 6),
                                  Text('Inventory & Notes'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Operators & Credentials
                _buildOperatorsTab(company: company, isMobile: isMobile),

                // Tab 2: Snooker Tables & Live Floor
                _buildTablesTab(companyId: company.id, isMobile: isMobile),

                // Tab 3: Match History & Collections
                _buildHistoryTab(companyId: company.id, isMobile: isMobile),

                // Tab 4: Inventory & Reminders
                _buildInventoryTab(companyId: company.id, isMobile: isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // SUBSCRIPTION & KPI HEADER
  // -------------------------------------------------------------

  Widget _buildSubscriptionBanner({
    required Company company,
    required String statusText,
    required Color statusColor,
    required String formattedExpiry,
    required bool isExpired,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(
            isExpired
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 20,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Expires on: $formattedExpiry • Due Buffer: ₹${company.dueBufferAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Change Expiry Button
          ElevatedButton.icon(
            onPressed: () {
              AppHaptics.light();
              _showExtendExpiryDialog(context, company);
            },
            icon: const Icon(Icons.edit_calendar_rounded, size: 14),
            label: const Text('Change Expiry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardSurface,
              foregroundColor: statusColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: statusColor.withAlpha(100)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsBar({
    required String companyId,
    required bool isMobile,
  }) {
    final firestoreService = sl<FirestoreService>();

    return StreamBuilder<List<UserAccount>>(
      stream: firestoreService.watchCompanyUsers(companyId),
      builder: (context, userSnap) {
        final users = userSnap.data ?? [];
        final activeUsers = users.where((u) => u.isActive).length;

        return StreamBuilder<List<ClubTable>>(
          stream: firestoreService.watchTables(companyId),
          builder: (context, tableSnap) {
            final tables = tableSnap.data ?? [];
            final liveTables = tables
                .where((t) => t.status == TableStatus.occupied)
                .length;

            return StreamBuilder<List<TableHistoryRecord>>(
              stream: firestoreService.watchTablesHistory(companyId),
              builder: (context, histSnap) {
                final history = histSnap.data ?? [];
                double totalBilled = 0.0;
                double totalDue = 0.0;
                for (final r in history) {
                  totalBilled += r.totalAmount;
                  totalDue += r.dueAmount;
                }

                final kpis = [
                  _buildKpiCard(
                    title: 'Operators',
                    value: '${users.length}',
                    subtitle: '$activeUsers active',
                    icon: Icons.people_alt_outlined,
                    color: AppColors.brandAccentLight,
                  ),
                  _buildKpiCard(
                    title: 'Tables',
                    value: '${tables.length}',
                    subtitle: '$liveTables live now',
                    icon: Icons.sports_baseball_outlined,
                    color: AppColors.tableAvailable,
                  ),
                  _buildKpiCard(
                    title: 'Total Matches',
                    value: '${history.length}',
                    subtitle: 'All-time played',
                    icon: Icons.military_tech_outlined,
                    color: AppColors.info,
                  ),
                  _buildKpiCard(
                    title: 'Revenue Billed',
                    value: '₹${totalBilled.toStringAsFixed(0)}',
                    subtitle: totalDue > 0
                        ? '₹${totalDue.toStringAsFixed(0)} pending due'
                        : '0 pending due',
                    icon: Icons.payments_outlined,
                    color: totalDue > 0
                        ? AppColors.tableOccupied
                        : AppColors.tableAvailable,
                  ),
                ];

                if (isMobile) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kpis
                        .map((kpi) => SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 40) / 2,
                              child: kpi,
                            ))
                        .toList(),
                  );
                }

                return Row(
                  children: kpis
                      .map((kpi) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: kpi,
                            ),
                          ))
                      .toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: OPERATORS & CREDENTIALS
  // -------------------------------------------------------------

  Widget _buildOperatorsTab({
    required Company company,
    required bool isMobile,
  }) {
    final firestoreService = sl<FirestoreService>();

    return StreamBuilder<List<UserAccount>>(
      stream: firestoreService.watchCompanyUsers(company.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent),
            ),
          );
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: AppColors.textDisabled),
                  SizedBox(height: 12),
                  Text(
                    'No operators found for this club.',
                    style: TextStyle(
                        color: AppColors.secondaryText, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserTile(
              company: company,
              user: user,
              isMobile: isMobile,
            );
          },
        );
      },
    );
  }

  Widget _buildUserTile({
    required Company company,
    required UserAccount user,
    required bool isMobile,
  }) {
    final isPasswordVisible = _revealedPasswords.contains(user.id);
    final isOwner = user.isOwner;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isActive
              ? AppColors.cardBorderStroke
              : AppColors.tableOccupied.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Avatar, Operator Details & Status Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Operator Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOwner
                        ? AppColors.brandAccent.withAlpha(35)
                        : AppColors.info.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: user.isOnline
                          ? AppColors.tableAvailable
                          : (isOwner
                              ? AppColors.brandAccent.withAlpha(90)
                              : AppColors.cardBorderStroke),
                      width: user.isOnline ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isOwner
                          ? Icons.admin_panel_settings_rounded
                          : Icons.person_rounded,
                      size: 22,
                      color:
                          isOwner ? AppColors.brandAccentLight : AppColors.info,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Contact Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          color: user.isActive
                              ? AppColors.primaryText
                              : AppColors.textDisabled,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration:
                              user.isActive ? null : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (user.number.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.number,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (user.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 13,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.email,
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
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
                ),
                const SizedBox(width: 8),

                // Badges Column (Role, Online, Active)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? AppColors.brandAccent.withAlpha(40)
                            : AppColors.info.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOwner
                              ? AppColors.brandAccent.withAlpha(100)
                              : AppColors.info.withAlpha(80),
                        ),
                      ),
                      child: Text(
                        isOwner ? 'OWNER' : 'EMPLOYEE',
                        style: TextStyle(
                          color: isOwner
                              ? AppColors.brandAccentLight
                              : AppColors.info,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status and Online Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.isOnline) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.tableAvailable,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Live',
                            style: TextStyle(
                              color: AppColors.tableAvailable,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (user.isActive
                                    ? AppColors.tableAvailable
                                    : AppColors.tableOccupied)
                                .withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.isActive ? 'Active' : 'Deactivated',
                            style: TextStyle(
                              color: user.isActive
                                  ? AppColors.tableAvailable
                                  : AppColors.tableOccupied,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Refined Password Box (2-Tier Layout: Full Width for password so it NEVER truncates!)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandAccent.withAlpha(60),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier 1: Header row with label and quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.key_rounded,
                              size: 14,
                              color: AppColors.brandAccentLight,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'PASSWORD / ACCESS PIN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // View/Hide button
                          IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: isPasswordVisible
                                  ? AppColors.brandAccentLight
                                  : AppColors.secondaryText,
                            ),
                            tooltip: isPasswordVisible
                                ? 'Hide Password'
                                : 'Show Password',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                            onPressed: () {
                              AppHaptics.light();
                              setState(() {
                                if (isPasswordVisible) {
                                  _revealedPasswords.remove(user.id);
                                } else {
                                  _revealedPasswords.add(user.id);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 2),

                          // Copy button
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: AppColors.secondaryText,
                            ),
                            tooltip: 'Copy Password',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                            onPressed: () {
                              AppHaptics.light();
                              Clipboard.setData(
                                  ClipboardData(text: user.password));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Password for "${user.name}" copied to clipboard!'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tier 2: Password Display Box with integrated Change Button (Guaranteed 0 overflow)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPasswordVisible
                            ? AppColors.brandAccent.withAlpha(90)
                            : AppColors.cardBorderStroke,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            isPasswordVisible
                                ? (user.password.isNotEmpty
                                    ? user.password
                                    : '<No Password Set>')
                                : '• • • • • • • •',
                            style: TextStyle(
                              color: isPasswordVisible
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
                              fontSize: isPasswordVisible ? 15 : 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: isPasswordVisible ? 0.8 : 3.0,
                              fontFamily:
                                  isPasswordVisible ? 'monospace' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Change Password Button
                        BouncingTap(
                          onTap: () {
                            AppHaptics.medium();
                            _showUpdatePasswordDialog(
                                context, company, user);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Actions Row (Role change & Deactivation)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Working time badge if any
                Text(
                  user.totalWorkingDuration > Duration.zero
                      ? 'Shift: ${user.totalWorkingDuration.inHours}h ${user.totalWorkingDuration.inMinutes.remainder(60)}m'
                      : 'No shifts recorded',
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Change Role Button
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        AppHaptics.light();
                        _showChangeRoleDialog(context, company, user);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.inputSurface,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: AppColors.cardBorderStroke),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                size: 14, color: AppColors.secondaryText),
                            SizedBox(width: 4),
                            Text(
                              'Change Role',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Activate / Deactivate Button
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        AppHaptics.light();
                        _showToggleActiveDialog(context, company, user);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: (user.isActive
                                  ? AppColors.tableOccupied
                                  : AppColors.tableAvailable)
                              .withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (user.isActive
                                    ? AppColors.tableOccupied
                                    : AppColors.tableAvailable)
                                .withAlpha(70),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              user.isActive
                                  ? Icons.person_off_outlined
                                  : Icons.check_circle_outline,
                              size: 14,
                              color: user.isActive
                                  ? AppColors.tableOccupied
                                  : AppColors.tableAvailable,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(
                                color: user.isActive
                                    ? AppColors.tableOccupied
                                    : AppColors.tableAvailable,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: SNOOKER TABLES & LIVE FLOOR
  // -------------------------------------------------------------

  Widget _buildTablesTab({
    required String companyId,
    required bool isMobile,
  }) {
    final firestoreService = sl<FirestoreService>();

    return StreamBuilder<List<ClubTable>>(
      stream: firestoreService.watchTables(companyId),
      builder: (context, tableSnap) {
        if (tableSnap.connectionState == ConnectionState.waiting &&
            !tableSnap.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent),
            ),
          );
        }

        final tables = tableSnap.data ?? [];
        if (tables.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_baseball_outlined,
                      size: 48, color: AppColors.textDisabled),
                  SizedBox(height: 12),
                  Text(
                    'No tables registered in this club yet.',
                    style: TextStyle(
                        color: AppColors.secondaryText, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<List<TableSession>>(
          stream: firestoreService.watchRunningTables(companyId),
          builder: (context, sessionSnap) {
            final activeSessions = sessionSnap.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                TableSession? session;
                try {
                  session = activeSessions
                      .firstWhere((s) => s.tableId == table.id);
                } catch (_) {}

                final isOccupied = table.status == TableStatus.occupied;
                final statusColor = isOccupied
                    ? AppColors.tableOccupied
                    : (table.status == TableStatus.maintenance
                        ? AppColors.tableMaintenance
                        : AppColors.tableAvailable);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isOccupied
                          ? AppColors.tableOccupied.withAlpha(120)
                          : AppColors.cardBorderStroke,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: statusColor.withAlpha(80)),
                            ),
                            child: Icon(
                              Icons.sports_baseball_rounded,
                              size: 20,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  table.name,
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${table.specsDescription.isNotEmpty ? table.specsDescription : "Standard Table"} • Rate: ₹${table.generalPrice.toStringAsFixed(0)}/hr',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: statusColor.withAlpha(70)),
                            ),
                            child: Text(
                              table.status.displayName,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (session != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.inputSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Customer: ${session.customerName.isNotEmpty ? session.customerName : "Walk-in"}',
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (session.customerPhone.isNotEmpty)
                                    Text(
                                      session.customerPhone,
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Started by: ${session.startedByName} • Items: ${session.items.length}',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 3: MATCH HISTORY
  // -------------------------------------------------------------

  Widget _buildHistoryTab({
    required String companyId,
    required bool isMobile,
  }) {
    final firestoreService = sl<FirestoreService>();

    return StreamBuilder<List<TableHistoryRecord>>(
      stream: firestoreService.watchTablesHistory(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent),
            ),
          );
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 48, color: AppColors.textDisabled),
                  SizedBox(height: 12),
                  Text(
                    'No completed match records yet.',
                    style: TextStyle(
                        color: AppColors.secondaryText, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final record = history[index];
            final closedAtFormatted =
                DateFormat('dd MMM yyyy, hh:mm a').format(record.closedAt);
            final isDue = record.isDue;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        record.tableName,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDue
                                  ? AppColors.tableOccupied
                                  : AppColors.tableAvailable)
                              .withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDue
                              ? 'DUE: ₹${record.dueAmount.toStringAsFixed(0)}'
                              : 'PAID',
                          style: TextStyle(
                            color: isDue
                                ? AppColors.tableOccupied
                                : AppColors.tableAvailable,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${record.customerName.isNotEmpty ? record.customerName : "Walk-in"} ${record.customerPhone.isNotEmpty ? "(${record.customerPhone})" : ""} • Duration: ${record.durationMinutes}m',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        closedAtFormatted,
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Total: ₹${record.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 4: INVENTORY & REMINDERS
  // -------------------------------------------------------------

  Widget _buildInventoryTab({
    required String companyId,
    required bool isMobile,
  }) {
    final firestoreService = sl<FirestoreService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Canteen Section
          _buildInventorySubSection<StockItem>(
            title: 'Canteen Menu Items',
            icon: Icons.fastfood_outlined,
            stream: firestoreService.watchFoodCanteen(companyId),
            emptyMessage: 'No canteen items configured.',
            itemBuilder: (item) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lunch_dining_rounded,
                    color: AppColors.brandAccentLight, size: 20),
                title: Text(item.name,
                    style: const TextStyle(
                        color: AppColors.primaryText, fontSize: 13)),
                trailing: Text(
                  '${item.price != null ? "₹${item.price!.toStringAsFixed(0)}" : "₹0"} (Stock: ${item.stock})',
                  style: const TextStyle(
                      color: AppColors.tableAvailable,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Equipment Stock Section
          _buildInventorySubSection<StockItem>(
            title: 'Equipment & Cues Stock',
            icon: Icons.sports_tennis_outlined,
            stream: firestoreService.watchEquipmentStock(companyId),
            emptyMessage: 'No equipment stock items found.',
            itemBuilder: (item) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.precision_manufacturing_outlined,
                    color: AppColors.info, size: 20),
                title: Text(item.name,
                    style: const TextStyle(
                        color: AppColors.primaryText, fontSize: 13)),
                trailing: Text(
                  'Stock: ${item.stock}',
                  style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Club Reminders Section
          _buildInventorySubSection<ClubReminder>(
            title: 'Club Reminders',
            icon: Icons.alarm_rounded,
            stream: firestoreService.watchCompanyReminders(companyId),
            emptyMessage: 'No reminders created for this club.',
            itemBuilder: (rem) {
              final formattedTime =
                  DateFormat('dd MMM, hh:mm a').format(rem.remindAt);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  rem.isDismissed
                      ? Icons.check_circle_rounded
                      : Icons.notifications_active_rounded,
                  color: rem.isDismissed
                      ? AppColors.textDisabled
                      : AppColors.warning,
                  size: 20,
                ),
                title: Text(rem.description,
                    style: TextStyle(
                      color: rem.isDismissed
                          ? AppColors.textDisabled
                          : AppColors.primaryText,
                      fontSize: 13,
                      decoration:
                          rem.isDismissed ? TextDecoration.lineThrough : null,
                    )),
                subtitle: Text(formattedTime,
                    style: const TextStyle(
                        color: AppColors.secondaryText, fontSize: 11)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySubSection<T>({
    required String title,
    required IconData icon,
    required Stream<List<T>> stream,
    required String emptyMessage,
    required Widget Function(T item) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandAccentLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<T>>(
            stream: stream,
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Text(
                  emptyMessage,
                  style: const TextStyle(
                      color: AppColors.secondaryText, fontSize: 12),
                );
              }
              return Column(
                children: list.map(itemBuilder).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOGS: UPDATE PASSWORD, EXTEND SUBSCRIPTION, TOGGLE ACTIVE
  // -------------------------------------------------------------

  void _showUpdatePasswordDialog(
    BuildContext context,
    Company company,
    UserAccount user,
  ) {
    final passwordCtrl = TextEditingController(text: user.password);
    bool obscure = false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorderStroke),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: 480,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccent.withAlpha(35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.key_rounded,
                              color: AppColors.brandAccentLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update Operator Password',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${user.name} (${company.name})',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.cardBorderStroke),
                      const SizedBox(height: 16),
                      const Text(
                        'New Password / PIN',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: obscure,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter new password...',
                          hintStyle: const TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.inputSurface,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.secondaryText,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.secondaryText,
                              size: 20,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscure = !obscure;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.cardBorderStroke),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.cardBorderStroke),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.brandAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The operator can use this new password immediately to sign in.',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(dialogCtx).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final newPass = passwordCtrl.text.trim();
                                    if (newPass.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Password cannot be empty.'),
                                          backgroundColor:
                                              AppColors.tableOccupied,
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      await sl<FirestoreService>()
                                          .updateUserPassword(
                                        company.id,
                                        user.id,
                                        newPass,
                                      );

                                      if (dialogCtx.mounted) {
                                        Navigator.of(dialogCtx).pop();
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Password updated for ${user.name}!',
                                            ),
                                            backgroundColor:
                                                AppColors.tableAvailable,
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        isSaving = false;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to update password: $e',
                                            ),
                                            backgroundColor:
                                                AppColors.tableOccupied,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save Password',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExtendExpiryDialog(BuildContext context, Company company) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: company.expiryDate.isAfter(DateTime.now())
          ? company.expiryDate
          : DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandAccent,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      try {
        await sl<FirestoreService>().updateCompanyExpiryDate(
          company.id,
          pickedDate,
        );
        if (context.mounted) {
          final formatted = DateFormat('dd MMM yyyy').format(pickedDate);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Subscription for "${company.name}" updated to $formatted!',
              ),
              backgroundColor: AppColors.tableAvailable,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update subscription expiry: $e'),
              backgroundColor: AppColors.tableOccupied,
            ),
          );
        }
      }
    }
  }

  void _showToggleActiveDialog(
    BuildContext context,
    Company company,
    UserAccount user,
  ) {
    final willDeactivate = user.isActive;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: Row(
          children: [
            Icon(
              willDeactivate
                  ? Icons.person_off_rounded
                  : Icons.check_circle_rounded,
              color: willDeactivate
                  ? AppColors.tableOccupied
                  : AppColors.tableAvailable,
            ),
            const SizedBox(width: 8),
            Text(
              willDeactivate ? 'Deactivate Operator?' : 'Activate Operator?',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          willDeactivate
              ? 'Are you sure you want to deactivate "${user.name}"? They will be immediately signed out and blocked from logging in.'
              : 'Reactivate "${user.name}" so they can log in and manage tables?',
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await sl<FirestoreService>().updateUserActiveStatus(
                  company.id,
                  user.id,
                  !willDeactivate,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Operator ${user.name} is now ${!willDeactivate ? "Active" : "Deactivated"}!',
                      ),
                      backgroundColor: !willDeactivate
                          ? AppColors.tableAvailable
                          : AppColors.tableOccupied,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update operator status: $e'),
                      backgroundColor: AppColors.tableOccupied,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willDeactivate
                  ? AppColors.tableOccupied
                  : AppColors.tableAvailable,
              foregroundColor: Colors.white,
            ),
            child: Text(willDeactivate ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(
    BuildContext context,
    Company company,
    UserAccount user,
  ) {
    final nextRole = user.isOwner ? 'employee' : 'owner';
    final nextRoleTitle = user.isOwner ? 'Employee' : 'Owner';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: const Text(
          'Change Operator Role',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Change role for "${user.name}" from ${user.role.toUpperCase()} to $nextRoleTitle?',
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await sl<FirestoreService>().updateUserRole(
                  company.id,
                  user.id,
                  nextRole,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Role for ${user.name} changed to $nextRoleTitle!',
                      ),
                      backgroundColor: AppColors.tableAvailable,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update role: $e'),
                      backgroundColor: AppColors.tableOccupied,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverTabBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
