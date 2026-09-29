import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/company.dart';
import '../auth/create_company_screen.dart';
import 'company_details_dev_screen.dart';

class DevAnalyticsDashboardScreen extends StatefulWidget {
  const DevAnalyticsDashboardScreen({super.key});

  @override
  State<DevAnalyticsDashboardScreen> createState() =>
      _DevAnalyticsDashboardScreenState();
}

class _DevAnalyticsDashboardScreenState
    extends State<DevAnalyticsDashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'active', 'expired'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = sl<FirestoreService>();
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dev Analytics & Admin',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Select any club to view full data & credentials',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Create New Company',
            icon: const Icon(
              Icons.add_business_rounded,
              color: AppColors.brandAccentLight,
            ),
            onPressed: () {
              AppHaptics.light();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateCompanyScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Company>>(
        stream: firestoreService.watchCompanies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.tableOccupied, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load companies: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            );
          }

          final allCompanies = snapshot.data ?? [];
          final activeCount =
              allCompanies.where((c) => !c.isExpired).length;
          final expiredCount =
              allCompanies.where((c) => c.isExpired).length;

          // Apply filters
          final filteredCompanies = allCompanies.where((c) {
            if (_filter == 'active' && c.isExpired) return false;
            if (_filter == 'expired' && !c.isExpired) return false;

            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchesName = c.name.toLowerCase().contains(query);
              final matchesCode = c.code.toLowerCase().contains(query);
              final matchesNumber = c.number.toLowerCase().contains(query);
              return matchesName || matchesCode || matchesNumber;
            }
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Top Analytics Header Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Analytics Metrics Bar
                      _buildMetricsRow(
                        totalCompanies: allCompanies.length,
                        activeCompanies: activeCount,
                        expiredCompanies: expiredCount,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 16),

                      // Search & Filter Toolbar
                      _buildSearchAndFilterBar(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Companies List
              if (filteredCompanies.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: AppColors.textDisabled.withAlpha(120),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No companies match "$_searchQuery"'
                                : 'No companies found in this filter',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final company = filteredCompanies[index];
                        return _buildCompanyCard(
                          company: company,
                          isMobile: isMobile,
                        );
                      },
                      childCount: filteredCompanies.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricsRow({
    required int totalCompanies,
    required int activeCompanies,
    required int expiredCompanies,
    required bool isMobile,
  }) {
    final cards = [
      _MetricItem(
        label: 'Total Clubs',
        value: '$totalCompanies',
        icon: Icons.storefront_rounded,
        color: AppColors.brandAccentLight,
        accentBg: AppColors.brandAccent.withAlpha(25),
      ),
      _MetricItem(
        label: 'Active Subscriptions',
        value: '$activeCompanies',
        icon: Icons.check_circle_rounded,
        color: AppColors.tableAvailable,
        accentBg: AppColors.tableAvailable.withAlpha(25),
      ),
      _MetricItem(
        label: 'Expired Subscriptions',
        value: '$expiredCompanies',
        icon: Icons.warning_amber_rounded,
        color: AppColors.tableOccupied,
        accentBg: AppColors.tableOccupied.withAlpha(25),
      ),
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 16) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: constraints.maxWidth, child: cards[0]),
              SizedBox(width: itemWidth, child: cards[1]),
              SizedBox(width: itemWidth, child: cards[2]),
            ],
          );
        },
      );
    }

    return Row(
      children: cards
          .map((card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by club name, code, or phone...',
            hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.secondaryText, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.cardSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorderStroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorderStroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brandAccent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All Clubs'),
              const SizedBox(width: 8),
              _buildFilterChip('active', 'Active Subscription'),
              const SizedBox(width: 8),
              _buildFilterChip('expired', 'Expired Subscription'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          AppHaptics.selection();
          setState(() {
            _filter = value;
          });
        }
      },
      selectedColor: AppColors.brandAccent,
      backgroundColor: AppColors.inputSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.secondaryText,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.brandAccent : AppColors.cardBorderStroke,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildCompanyCard({
    required Company company,
    required bool isMobile,
  }) {
    final isExpired = company.isExpired;
    final now = DateTime.now();
    final difference = company.expiryDate.difference(now).inDays;
    final formattedDate =
        DateFormat('dd MMM yyyy').format(company.expiryDate);

    final statusText = isExpired
        ? 'Expired (${difference.abs()}d ago)'
        : 'Active ($difference days left)';

    final statusColor =
        isExpired ? AppColors.tableOccupied : AppColors.tableAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorderStroke,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AppHaptics.light();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CompanyDetailsDevScreen(
                  initialCompany: company,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brandAccent.withAlpha(70),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          company.name.isNotEmpty
                              ? company.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name, Code & Phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Company Code Tag with Copy
                              InkWell(
                                onTap: () {
                                  AppHaptics.light();
                                  Clipboard.setData(
                                      ClipboardData(text: company.code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Company Code "${company.code}" copied to clipboard!'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.brandAccent.withAlpha(35),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          AppColors.brandAccent.withAlpha(100),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'CODE: ${company.code}',
                                        style: const TextStyle(
                                          color: AppColors.brandAccentLight,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.copy_rounded,
                                        size: 11,
                                        color: AppColors.brandAccentLight,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (company.number.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 12,
                                      color: AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      company.number,
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Trailing View Details Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.secondaryText,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom Subscription Info & Action Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpired
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$statusText • Expiry: $formattedDate',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Quick Action to Extend / Edit Expiry Date
                      InkWell(
                        onTap: () {
                          AppHaptics.light();
                          _showExtendExpiryDialog(context, company);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_calendar_rounded,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Change Expiry',
                                style: TextStyle(
                                  color: statusColor,
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
        ),
      ),
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
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color accentBg;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.accentBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
