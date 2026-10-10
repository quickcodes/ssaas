import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/user_account.dart';
import '../../../domain/entities/user_shift_record.dart';
import '../../blocs/auth/auth_bloc.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserAccount user;
  final bool isSelf;

  const UserDetailsScreen({
    super.key,
    required this.user,
    this.isSelf = false,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours == 0 && minutes == 0) {
      final seconds = duration.inSeconds % 60;
      return '${seconds}s';
    }
    if (hours == 0) {
      return '${minutes}m';
    }
    return '${hours}h ${minutes}m';
  }

  void _confirmDeactivateUser(
    BuildContext context,
    UserAccount targetUser,
    String companyName,
  ) {
    AppHaptics.selection();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: const Row(
          children: [
            Icon(Icons.person_off_outlined, color: AppColors.tableOccupied, size: 24),
            SizedBox(width: 10),
            Text(
              'Deactivate User?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 460,
          ),
          child: SingleChildScrollView(
            child: Text(
              'Are you sure you want to deactivate ${targetUser.name}? This user will be immediately logged out and prevented from accessing $companyName until reactivated.',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              AppHaptics.medium();
              context.read<AuthBloc>().add(
                    ToggleUserActiveStatusEvent(userId: targetUser.id, isActive: false),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tableOccupied,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate User'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final currentUser = authState.currentUser;
        final activeCompany = authState.activeCompany;
        // Use live user from companyUsers list if present
        final liveUser = authState.companyUsers.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );

        return StreamBuilder<List<UserShiftRecord>>(
          stream: sl<FirestoreService>().watchUserShifts(
            liveUser.companyId,
            liveUser.id,
          ),
          builder: (context, shiftSnapshot) {
            final sortedShifts = shiftSnapshot.data ?? const <UserShiftRecord>[];
            final totalDuration = sortedShifts.fold<Duration>(
              Duration.zero,
              (total, shift) => total + shift.duration,
            );
            final totalHours = _formatDuration(totalDuration);
            final activeShift = sortedShifts.where((shift) => shift.isActive).firstOrNull;
            final isOwner = liveUser.isOwner;
            final isActive = liveUser.isActive;
            final canOwnerManage = (currentUser?.isOwner ?? false) && !isSelf;

            return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: AppBar(
            backgroundColor: AppColors.cardSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OPERATOR PROFILE & SHIFTS',
                  style: TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  liveUser.name,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: !isActive
                      ? AppColors.tableOccupied.withAlpha(25)
                      : liveUser.isOnline
                          ? AppColors.tableAvailable.withAlpha(25)
                          : AppColors.cardBorderStroke,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isActive
                        ? AppColors.tableOccupied.withAlpha(80)
                        : liveUser.isOnline
                            ? AppColors.tableAvailable.withAlpha(80)
                            : AppColors.cardBorderStroke,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      !isActive
                          ? Icons.block
                          : (liveUser.isOnline ? Icons.bolt : Icons.circle),
                      size: 10,
                      color: !isActive
                          ? AppColors.tableOccupied
                          : (liveUser.isOnline
                              ? AppColors.tableAvailable
                              : AppColors.textDisabled),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      !isActive
                          ? 'DEACTIVATED'
                          : (liveUser.isOnline ? 'ONLINE' : 'OFFLINE'),
                      style: TextStyle(
                        color: !isActive
                            ? AppColors.tableOccupied
                            : (liveUser.isOnline
                                ? AppColors.tableAvailable
                                : AppColors.secondaryText),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User Profile Summary Card
                      Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 22),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !isActive
                                ? AppColors.tableOccupied.withAlpha(80)
                                : isOwner
                                    ? const Color(0xFFFFB300).withAlpha(90)
                                    : AppColors.cardBorderStroke,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: isMobile ? 24 : 28,
                                  backgroundColor: !isActive
                                      ? AppColors.tableOccupied.withAlpha(30)
                                      : isOwner
                                          ? const Color(0xFFFFB300).withAlpha(35)
                                          : AppColors.inputSurface,
                                  child: Icon(
                                    !isActive
                                        ? Icons.person_off_outlined
                                        : (isOwner ? Icons.verified_user : Icons.person),
                                    size: isMobile ? 24 : 28,
                                    color: !isActive
                                        ? AppColors.tableOccupied
                                        : (isOwner
                                            ? const Color(0xFFFFB300)
                                            : AppColors.secondaryText),
                                  ),
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
                                              liveUser.name,
                                              style: TextStyle(
                                                color: isActive
                                                    ? AppColors.primaryText
                                                    : AppColors.secondaryText,
                                                fontSize: isMobile ? 18 : 20,
                                                fontWeight: FontWeight.w800,
                                                decoration: !isActive
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelf) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandAccent.withAlpha(40),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'YOU',
                                                style: TextStyle(
                                                  color: AppColors.brandAccentLight,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          // Role Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOwner
                                                  ? const Color(0xFFFFB300).withAlpha(30)
                                                  : AppColors.inputSurface,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isOwner
                                                    ? const Color(0xFFFFB300).withAlpha(120)
                                                    : AppColors.cardBorderStroke,
                                              ),
                                            ),
                                            child: Text(
                                              isOwner ? 'CLUB OWNER' : 'STAFF / EMPLOYEE',
                                              style: TextStyle(
                                                color: isOwner
                                                    ? const Color(0xFFFFB300)
                                                    : AppColors.secondaryText,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ),
                                          // Status Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppColors.tableAvailable.withAlpha(25)
                                                  : AppColors.tableOccupied.withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isActive
                                                    ? AppColors.tableAvailable.withAlpha(90)
                                                    : AppColors.tableOccupied.withAlpha(100),
                                              ),
                                            ),
                                            child: Text(
                                              isActive ? 'ACTIVE ACCOUNT' : 'DEACTIVATED ACCOUNT',
                                              style: TextStyle(
                                                color: isActive
                                                    ? AppColors.tableAvailable
                                                    : AppColors.tableOccupied,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Divider(color: AppColors.cardBorderStroke),
                            const SizedBox(height: 12),

                            // Contact & Account Specs
                            _buildDetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: liveUser.number.isNotEmpty ? liveUser.number : 'Not set',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                              value: liveUser.email.isNotEmpty ? liveUser.email : 'Not set',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Account Created',
                              value: DateFormat('dd MMM yyyy, hh:mm a').format(liveUser.createdAt),
                            ),
                            if (liveUser.sessionExpiresAt != null) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                icon: Icons.lock_clock_outlined,
                                label: 'Session Validity',
                                value: liveUser.isSessionValid
                                    ? 'Active until ${DateFormat('dd MMM yyyy, hh:mm a').format(liveUser.sessionExpiresAt!)}'
                                    : 'Session Expired',
                                valueColor: liveUser.isSessionValid
                                    ? AppColors.tableAvailable
                                    : AppColors.error,
                              ),
                            ],

                            // Owner controls on other users
                            if (canOwnerManage) ...[
                              const SizedBox(height: 16),
                              const Divider(color: AppColors.cardBorderStroke),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  // Deactivate / Reactivate
                                  if (isActive)
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmDeactivateUser(
                                        context,
                                        liveUser,
                                        activeCompany?.name ?? 'Club',
                                      ),
                                      icon: const Icon(Icons.block, size: 16),
                                      label: const Text('Deactivate Account'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.tableOccupied,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        AppHaptics.medium();
                                        context.read<AuthBloc>().add(
                                              ToggleUserActiveStatusEvent(
                                                userId: liveUser.id,
                                                isActive: true,
                                              ),
                                            );
                                      },
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: const Text('Reactivate Account'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.tableAvailable,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  // Change Role
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      AppHaptics.selection();
                                      final newRole = isOwner ? 'employee' : 'owner';
                                      context.read<AuthBloc>().add(
                                            UpdateUserRoleEvent(
                                              userId: liveUser.id,
                                              role: newRole,
                                            ),
                                          );
                                    },
                                    icon: Icon(
                                      isOwner ? Icons.badge_outlined : Icons.verified_user,
                                      size: 16,
                                      color: isOwner ? AppColors.primaryText : const Color(0xFFFFB300),
                                    ),
                                    label: Text(
                                      isOwner ? 'Demote to Employee' : 'Promote to Owner',
                                      style: TextStyle(
                                        color: isOwner ? AppColors.primaryText : const Color(0xFFFFB300),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isOwner
                                            ? AppColors.cardBorderStroke
                                            : const Color(0xFFFFB300).withAlpha(140),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                  // Working Hours & Shift KPI Metrics
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.timer_outlined,
                          title: 'TOTAL WORKING TIME',
                          value: totalHours,
                          accentColor: AppColors.brandAccentLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.history_toggle_off,
                          title: 'TOTAL SHIFTS',
                          value: '${sortedShifts.length}',
                          accentColor: AppColors.tableReserved,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.bolt,
                          title: 'CURRENT SHIFT',
                          value: activeShift != null
                              ? _formatDuration(activeShift.duration)
                              : 'Offline',
                          accentColor: activeShift != null
                              ? AppColors.tableAvailable
                              : AppColors.textDisabled,
                          isPulsing: activeShift != null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Shift History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SHIFT HISTORY & TIMELINE',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${sortedShifts.length} Shift${sortedShifts.length == 1 ? "" : "s"}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Shift History List
                  if (sortedShifts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 40,
                            color: AppColors.textDisabled,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No Shift History Recorded',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'When this operator switches between Online and Offline status, their shifts and working hours will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedShifts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final shift = sortedShifts[idx];
                        final isActive = shift.isActive;
                        final durationStr = _formatDuration(shift.duration);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.tableAvailable.withAlpha(15)
                                : AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.tableAvailable.withAlpha(80)
                                  : AppColors.cardBorderStroke,
                              width: isActive ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.tableAvailable.withAlpha(30)
                                      : AppColors.inputSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive ? Icons.bolt : Icons.check_circle_outline,
                                  size: 16,
                                  color: isActive
                                      ? AppColors.tableAvailable
                                      : AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          DateFormat('EEE, dd MMM yyyy').format(shift.onlineAt),
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (isActive) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.tableAvailable.withAlpha(35),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'ACTIVE NOW',
                                              style: TextStyle(
                                                color: AppColors.tableAvailable,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${DateFormat('hh:mm a').format(shift.onlineAt)}  ➔  ${shift.offlineAt != null ? DateFormat('hh:mm a').format(shift.offlineAt!) : "Present"}',
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
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.tableAvailable.withAlpha(25)
                                      : AppColors.inputSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.tableAvailable.withAlpha(80)
                                        : AppColors.cardBorderStroke,
                                  ),
                                ),
                                child: Text(
                                  durationStr,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.tableAvailable
                                        : AppColors.primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
    bool isPulsing = false,
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
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPulsing ? accentColor : AppColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
