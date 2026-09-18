import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/user_account.dart';
import '../../../domain/entities/user_shift_record.dart';

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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final sortedShifts = List<UserShiftRecord>.from(user.shifts)
      ..sort((a, b) => b.onlineAt.compareTo(a.onlineAt));

    final totalHours = _formatDuration(user.totalWorkingDuration);
    final activeShift = user.activeShift;

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
              user.name,
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
              color: user.isOnline
                  ? AppColors.tableAvailable.withAlpha(25)
                  : AppColors.cardBorderStroke,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isOnline
                    ? AppColors.tableAvailable.withAlpha(80)
                    : AppColors.cardBorderStroke,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: user.isOnline
                      ? AppColors.tableAvailable
                      : AppColors.textDisabled,
                ),
                const SizedBox(width: 6),
                Text(
                  user.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: user.isOnline
                        ? AppColors.tableAvailable
                        : AppColors.secondaryText,
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
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 24 : 28,
                              backgroundColor: user.isAdmin
                                  ? AppColors.brandAccent.withAlpha(40)
                                  : AppColors.inputSurface,
                              child: Icon(
                                user.isAdmin ? Icons.shield : Icons.person,
                                size: isMobile ? 24 : 28,
                                color: user.isAdmin
                                    ? AppColors.brandAccentLight
                                    : AppColors.secondaryText,
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
                                          user.name,
                                          style: TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: isMobile ? 18 : 20,
                                            fontWeight: FontWeight.w800,
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
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isAdmin
                                          ? AppColors.brandAccent.withAlpha(30)
                                          : AppColors.inputSurface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.isAdmin ? 'ADMINISTRATOR' : 'STAFF OPERATOR',
                                      style: TextStyle(
                                        color: user.isAdmin
                                            ? AppColors.brandAccentLight
                                            : AppColors.secondaryText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
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
                          value: user.number.isNotEmpty ? user.number : 'Not set',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: user.email.isNotEmpty ? user.email : 'Not set',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Account Created',
                          value: DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt),
                        ),
                        if (user.sessionExpiresAt != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.lock_clock_outlined,
                            label: 'Session Validity',
                            value: user.isSessionValid
                                ? 'Active until ${DateFormat('dd MMM yyyy, hh:mm a').format(user.sessionExpiresAt!)}'
                                : 'Session Expired',
                            valueColor: user.isSessionValid
                                ? AppColors.tableAvailable
                                : AppColors.error,
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
                          value: '${user.shifts.length}',
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
