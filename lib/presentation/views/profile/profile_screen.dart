import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/user_account.dart';
import '../../../domain/entities/user_shift_record.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/bouncing_tap.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // -------------------------------------------------------------
  // SHIFTS PAGINATION STATE (Page limit: 10)
  // -------------------------------------------------------------
  static const int _shiftPageLimit = 10;
  List<UserShiftRecord> _shifts = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _isLoadingShifts = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _shiftError;
  Timer? _liveDurationTicker;

  // -------------------------------------------------------------
  // PASSWORD & SECURITY STATE
  // -------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showSavedPassword = false;
  bool _obscureCurrentInput = true;
  bool _obscureNewInput = true;
  bool _obscureConfirmInput = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        AppHaptics.selection();
        setState(() {});
      }
    });

    _newPasswordCtrl.addListener(_onFormUpdated);
    _confirmPasswordCtrl.addListener(_onFormUpdated);
    _currentPasswordCtrl.addListener(_onFormUpdated);

    // Initial shifts fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      final user = authState.currentUser;
      if (user != null) {
        _fetchInitialShifts(user.companyId, user.id);
      }
    });

    // 1-second live ticker for any active shift
    _liveDurationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _shifts.any((s) => s.isActive)) {
        setState(() {});
      }
    });
  }

  void _onFormUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveDurationTicker?.cancel();

    _newPasswordCtrl.removeListener(_onFormUpdated);
    _confirmPasswordCtrl.removeListener(_onFormUpdated);
    _currentPasswordCtrl.removeListener(_onFormUpdated);

    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // PAGINATED SHIFT FETCHING
  // -------------------------------------------------------------
  Future<void> _fetchInitialShifts(String companyId, String userId) async {
    setState(() {
      _isLoadingShifts = true;
      _shiftError = null;
    });

    try {
      final result = await sl<FirestoreService>().getUserShiftsPaginated(
        companyId: companyId,
        userId: userId,
        limit: _shiftPageLimit,
      );

      if (mounted) {
        setState(() {
          _shifts = result.shifts;
          _lastDoc = result.lastDocument;
          _hasMore = result.hasMore;
          _isLoadingShifts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shiftError = 'Failed to load shifts: $e';
          _isLoadingShifts = false;
        });
      }
    }
  }

  Future<void> _loadMoreShifts(String companyId, String userId) async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    setState(() => _isLoadingMore = true);
    AppHaptics.selection();

    try {
      final result = await sl<FirestoreService>().getUserShiftsPaginated(
        companyId: companyId,
        userId: userId,
        limit: _shiftPageLimit,
        startAfter: _lastDoc,
      );

      if (mounted) {
        setState(() {
          _shifts.addAll(result.shifts);
          _lastDoc = result.lastDocument;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more shifts: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------
  // PASSWORD ACTIONS
  // -------------------------------------------------------------
  void _copyToClipboard(String text) {
    AppHaptics.light();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Password copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.tableAvailable,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submitChangePassword(UserAccount user) {
    if (_isSubmitting) return;
    final authState = context.read<AuthBloc>().state;
    if (authState.isLoading) return;

    if (!_formKey.currentState!.validate()) {
      AppHaptics.error();
      return;
    }

    final currentPass = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text.trim();

    if (currentPass != user.password) {
      AppHaptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Current password is incorrect. Please verify and try again.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (newPass == user.password) {
      AppHaptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'New password cannot be identical to your current password.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    _isSubmitting = true;
    AppHaptics.medium();

    context.read<AuthBloc>().add(
      ChangeUserPasswordEvent(
        companyId: user.companyId,
        userId: user.id,
        currentPassword: currentPass,
        newPassword: newPass,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isSubmitting = false);
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shiftDay = DateTime(date.year, date.month, date.day);

    if (shiftDay == today) {
      return 'Today • ${DateFormat('dd MMM yyyy').format(date)}';
    } else if (shiftDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday • ${DateFormat('dd MMM yyyy').format(date)}';
    } else {
      return DateFormat('EEE, dd MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current.errorMessage != previous.errorMessage ||
          current.successMessage != previous.successMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.read<AuthBloc>().add(ClearAuthErrorEvent());
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.successMessage!)),
                ],
              ),
              backgroundColor: AppColors.tableAvailable,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          _currentPasswordCtrl.clear();
          _newPasswordCtrl.clear();
          _confirmPasswordCtrl.clear();
          context.read<AuthBloc>().add(ClearAuthErrorEvent());
        }
      },
      builder: (context, authState) {
        final currentUser = authState.currentUser;
        final activeCompany = authState.activeCompany;

        if (currentUser == null) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundBase,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Live user from active company users list if present
        final liveUser = authState.companyUsers.firstWhere(
          (u) => u.id == currentUser.id,
          orElse: () => currentUser,
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: AppBar(
            backgroundColor: AppColors.cardSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                AppHaptics.light();
                Navigator.of(context).pop();
              },
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: AppColors.brandAccentLight,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh shifts',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
                onPressed: () {
                  AppHaptics.light();
                  _fetchInitialShifts(liveUser.companyId, liveUser.id);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  // Top Profile Summary Header Card
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 20,
                      12,
                      isMobile ? 14 : 20,
                      4,
                    ),
                    child: _buildProfileHeaderCard(
                      liveUser,
                      activeCompany?.name,
                    ),
                  ),

                  // Modern Floating Pill Tab Bar
                  _buildModernTabBar(liveUser, isMobile),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // TAB 1: DAILY IN/OUT SHIFTS (Paginated)
                        _buildDailyShiftsTab(liveUser, isMobile),

                        // TAB 2: PASSWORD & SECURITY
                        _buildPasswordSecurityTab(
                          liveUser,
                          authState.isLoading,
                          isMobile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // MODERN FLOATING PILL TAB BAR
  // -------------------------------------------------------------
  Widget _buildModernTabBar(UserAccount liveUser, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 8),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AppColors.brandAccent, Color(0xFF8E24AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandAccent.withAlpha(90),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.secondaryText,
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.punch_clock_rounded, size: 16),
                const SizedBox(width: 7),
                const Text('Daily Shifts'),
                if (liveUser.shiftCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${liveUser.shiftCount}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 16),
                SizedBox(width: 7),
                Text('Password'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PROFILE HEADER CARD
  // -------------------------------------------------------------
  Widget _buildProfileHeaderCard(UserAccount user, String? companyName) {
    final roleName = user.isOwner
        ? 'Owner'
        : (user.isAdmin ? 'Admin' : 'Operator');

    final roleColor = user.isOwner
        ? AppColors.tableAvailable
        : (user.isAdmin ? AppColors.brandAccentLight : const Color(0xFF64B5F6));

    final totalHoursStr = user.totalWorkingDuration.inHours > 0
        ? '${user.totalWorkingDuration.inHours}h ${user.totalWorkingDuration.inMinutes.remainder(60)}m'
        : '${user.totalWorkingDuration.inMinutes}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brandAccent.withAlpha(45),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.brandAccentLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: user.isOnline
                            ? AppColors.tableAvailable
                            : AppColors.textDisabled,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardSurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: roleColor.withAlpha(120)),
                          ),
                          child: Text(
                            roleName.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.number.isNotEmpty ? user.number : user.email,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (companyName != null && companyName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        companyName,
                        style: TextStyle(
                          color: AppColors.brandAccentLight.withAlpha(210),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorderStroke),
          const SizedBox(height: 10),

          // Quick KPIs Row
          Row(
            children: [
              _buildKpiItem(
                label: 'STATUS',
                value: user.isOnline ? 'ONLINE' : 'OFFLINE',
                color: user.isOnline
                    ? AppColors.tableAvailable
                    : AppColors.secondaryText,
                icon: user.isOnline ? Icons.bolt : Icons.power_settings_new,
              ),
              Container(
                height: 24,
                width: 1,
                color: AppColors.cardBorderStroke,
              ),
              _buildKpiItem(
                label: 'TOTAL SHIFTS',
                value: '${user.shiftCount}',
                color: AppColors.brandAccentLight,
                icon: Icons.history_rounded,
              ),
              Container(
                height: 24,
                width: 1,
                color: AppColors.cardBorderStroke,
              ),
              _buildKpiItem(
                label: 'TOTAL HOURS',
                value: totalHoursStr,
                color: const Color(0xFF64B5F6),
                icon: Icons.timer_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: DAILY IN / OUT SHIFTS WITH PAGINATION (Limit: 10)
  // -------------------------------------------------------------
  Widget _buildDailyShiftsTab(UserAccount user, bool isMobile) {
    if (_isLoadingShifts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandAccentLight,
            ),
            SizedBox(height: 12),
            Text(
              'Loading shift records...',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_shiftError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 42, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _shiftError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchInitialShifts(user.companyId, user.id),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('RETRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.brandAccentLight,
      backgroundColor: AppColors.cardSurface,
      onRefresh: () => _fetchInitialShifts(user.companyId, user.id),
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: 14,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Subheader Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    size: 15,
                    color: AppColors.brandAccentLight,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'DAILY ATTENDANCE LOG',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorderStroke),
                ),
                child: Text(
                  'Showing ${_shifts.length} of ${user.shiftCount > _shifts.length ? user.shiftCount : _shifts.length}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Empty state
          if (_shifts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 44, color: AppColors.textDisabled),
                  SizedBox(height: 14),
                  Text(
                    'No Shift Records Found',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'When you toggle between Online and Offline status, your daily punch-in and punch-out attendance will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Shifts List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shifts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final shift = _shifts[index];
                return _buildShiftCard(shift);
              },
            ),

            const SizedBox(height: 16),

            // Pagination Footer (Limit: 10)
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandAccentLight,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading next 10 shifts...',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_hasMore)
              BouncingTap(
                onTap: () => _loadMoreShifts(user.companyId, user.id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.brandAccentLight.withAlpha(100),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.brandAccentLight,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'LOAD MORE SHIFTS (10 MORE)',
                        style: TextStyle(
                          color: AppColors.brandAccentLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'All ${_shifts.length} shifts loaded',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SHIFT CARD ITEM
  // -------------------------------------------------------------
  Widget _buildShiftCard(UserShiftRecord shift) {
    final isActive = shift.isActive;
    final dateHeader = _formatDateHeader(shift.onlineAt);
    final inTimeStr = DateFormat('hh:mm a').format(shift.onlineAt);
    final outTimeStr = shift.offlineAt != null
        ? DateFormat('hh:mm a').format(shift.offlineAt!)
        : 'In Progress';
    final durationStr = _formatDuration(shift.duration);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.tableAvailable.withAlpha(12)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.tableAvailable.withAlpha(90)
              : AppColors.cardBorderStroke,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isActive ? 40 : 25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: isActive
                        ? AppColors.tableAvailable
                        : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateHeader,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.tableAvailable
                          : AppColors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tableAvailable.withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.tableAvailable.withAlpha(120),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 11,
                        color: AppColors.tableAvailable,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'ACTIVE NOW',
                        style: TextStyle(
                          color: AppColors.tableAvailable,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // IN & OUT Times Row
          Row(
            children: [
              // IN Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface.withAlpha(140),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.tableAvailable.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          size: 14,
                          color: AppColors.tableAvailable,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PUNCH IN',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              inTimeStr,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // OUT Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface.withAlpha(140),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.tableReserved.withAlpha(25)
                              : AppColors.tableOccupied.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.hourglass_top_rounded
                              : Icons.logout_rounded,
                          size: 14,
                          color: isActive
                              ? AppColors.tableReserved
                              : AppColors.tableOccupied,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isActive ? 'CURRENT STATUS' : 'PUNCH OUT',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              outTimeStr,
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.tableReserved
                                    : AppColors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Total Duration Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.tableAvailable.withAlpha(20)
                  : AppColors.inputSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? AppColors.tableAvailable.withAlpha(60)
                    : AppColors.cardBorderStroke,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isActive
                          ? AppColors.tableAvailable
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Live Working Time:' : 'Shift Duration:',
                      style: TextStyle(
                        color: isActive
                            ? AppColors.tableAvailable
                            : AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  durationStr,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.tableAvailable
                        : AppColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: PASSWORD & SECURITY
  // -------------------------------------------------------------
  Widget _buildPasswordSecurityTab(
    UserAccount user,
    bool isLoading,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Saved Password Viewer Card
          _buildSavedPasswordCard(user),

          const SizedBox(height: 16),

          // Change Password Card
          _buildChangePasswordCard(user, isLoading),
        ],
      ),
    );
  }

  Widget _buildSavedPasswordCard(UserAccount user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SAVED ACCOUNT PASSWORD',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderStroke),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.key_rounded,
                  color: AppColors.brandAccentLight,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _showSavedPassword
                        ? user.password
                        : '•' *
                              (user.password.length > 3
                                  ? user.password.length
                                  : 8),
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: _showSavedPassword ? 15 : 20,
                      letterSpacing: _showSavedPassword ? 0.5 : 2.0,
                      fontWeight: _showSavedPassword
                          ? FontWeight.w700
                          : FontWeight.w900,
                      fontFamily: _showSavedPassword ? null : 'Courier',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _showSavedPassword
                      ? 'Hide Password'
                      : 'Show Password',
                  icon: Icon(
                    _showSavedPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                  onPressed: () {
                    AppHaptics.light();
                    setState(() => _showSavedPassword = !_showSavedPassword);
                  },
                ),
                IconButton(
                  tooltip: 'Copy Password',
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.brandAccentLight,
                    size: 19,
                  ),
                  onPressed: () => _copyToClipboard(user.password),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.secondaryText,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Use this password alongside your club code to sign in on any device.',
                  style: TextStyle(
                    color: AppColors.secondaryText.withAlpha(200),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordCard(UserAccount user, bool isLoading) {
    final newPass = _newPasswordCtrl.text.trim();
    final confirmPass = _confirmPasswordCtrl.text.trim();

    final isMinLength = newPass.length >= 4;
    final isDifferentFromOld = newPass.isNotEmpty && newPass != user.password;
    final isMatch = newPass.isNotEmpty && newPass == confirmPass;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.brandAccentLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose a new password for your account',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Field 1: Current Password
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: _obscureCurrentInput,
              decoration: InputDecoration(
                labelText: 'Current Password *',
                hintText: 'Enter your existing password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentInput
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureCurrentInput = !_obscureCurrentInput,
                    );
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your current password';
                }
                if (val != user.password) {
                  return 'Does not match current password';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Field 2: New Password
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: _obscureNewInput,
              decoration: InputDecoration(
                labelText: 'New Password *',
                hintText: 'Minimum 4 characters',
                prefixIcon: const Icon(Icons.password_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewInput ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () {
                    setState(() => _obscureNewInput = !_obscureNewInput);
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a new password';
                }
                if (val.trim().length < 4) {
                  return 'Password must be at least 4 characters';
                }
                if (val.trim() == user.password) {
                  return 'New password cannot be the same as current password';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Field 3: Confirm New Password
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: _obscureConfirmInput,
              decoration: InputDecoration(
                labelText: 'Confirm New Password *',
                hintText: 'Re-enter your new password',
                prefixIcon: const Icon(Icons.check_circle_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmInput
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmInput = !_obscureConfirmInput,
                    );
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please confirm your new password';
                }
                if (val.trim() != _newPasswordCtrl.text.trim()) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Password Checklist Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputSurface.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequirementRow(
                    label: 'At least 4 characters',
                    isMet: isMinLength,
                  ),
                  const SizedBox(height: 6),
                  _buildRequirementRow(
                    label: 'Different from current password',
                    isMet: isDifferentFromOld,
                  ),
                  const SizedBox(height: 6),
                  _buildRequirementRow(
                    label: 'New passwords match',
                    isMet: isMatch,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            BouncingTap(
              onTap: (isLoading || _isSubmitting)
                  ? null
                  : () => _submitChangePassword(user),
              child: ElevatedButton(
                onPressed: (isLoading || _isSubmitting)
                    ? null
                    : () => _submitChangePassword(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: (isLoading || _isSubmitting)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'UPDATE PASSWORD',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow({required String label, required bool isMet}) {
    return Row(
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 15,
          color: isMet ? AppColors.tableAvailable : AppColors.secondaryText,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isMet ? AppColors.primaryText : AppColors.secondaryText,
            fontSize: 12,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
