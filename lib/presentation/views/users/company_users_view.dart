import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/bouncing_tap.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/fade_slide_transition.dart';
import 'add_company_user_screen.dart';
import 'user_details_screen.dart';

class CompanyUsersView extends StatelessWidget {
  const CompanyUsersView({super.key});

  void _showAddUserDialog(BuildContext context, String companyId) {
    AppNavigation.pushSmooth(
      context,
      AddCompanyUserScreen(
        companyId: companyId,
        onAddUser: (newUser) {
          context.read<AuthBloc>().add(CreateCompanyUserEvent(newUser));
        },
      ),
    );
  }

  void _confirmDeactivateUser(
    BuildContext context,
    UserAccount user,
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
              'Are you sure you want to deactivate ${user.name}? This user will be immediately logged out from all active sessions and will be prevented from logging into $companyName until reactivated by an owner.',
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
                    ToggleUserActiveStatusEvent(userId: user.id, isActive: false),
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
        final users = authState.companyUsers;

        if (currentUser == null || activeCompany == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!currentUser.isOwner && !currentUser.isAdmin) {
          return Center(
            child: Container(
              margin: EdgeInsets.all(isMobile ? 16 : 24),
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: AppColors.tableOccupied,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Owner Access Only',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Only Club Owners can create new users, manage roles, and activate/deactivate accounts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondaryText, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 14,
                  spacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${activeCompany.name.toUpperCase()} • USERS',
                              style: const TextStyle(
                                color: AppColors.brandAccentLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandAccent.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.brandAccentLight.withAlpha(100),
                                ),
                              ),
                              child: Text(
                                'CODE: ${activeCompany.code}',
                                style: const TextStyle(
                                  color: AppColors.brandAccentLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Associated Company Users',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: isMobile ? 20 : 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    BouncingTap(
                      onTap: () {
                        AppHaptics.light();
                        _showAddUserDialog(context, activeCompany.id);
                      },
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppHaptics.light();
                          _showAddUserDialog(context, activeCompany.id);
                        },
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text(
                          'Add User',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Users List
                Expanded(
                  child: users.isEmpty
                      ? EmptyStateCard(
                          icon: Icons.people_outline,
                          title: 'No Associated Users',
                          subtitle:
                              'No team members have been added to this club yet. Add users to grant them access.',
                          actionLabel: 'Add User',
                          onAction: () {
                            AppHaptics.light();
                            _showAddUserDialog(context, activeCompany.id);
                          },
                        )
                      : ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isSelf = user.id == currentUser.id;
                            final isOwner = user.isOwner;
                            final isActive = user.isActive;

                            return FadeSlideTransitionWidget(
                              index: index,
                              child: BouncingTap(
                                onTap: () {
                                  AppHaptics.selection();
                                  AppNavigation.pushSmooth(
                                    context,
                                    UserDetailsScreen(
                                      user: user,
                                      isSelf: isSelf,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 14 : 18),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelf
                                          ? AppColors.brandAccent.withAlpha(140)
                                          : !isActive
                                              ? AppColors.tableOccupied.withAlpha(80)
                                              : isOwner
                                                  ? const Color(0xFFFFB300).withAlpha(90)
                                                  : AppColors.cardBorderStroke,
                                      width: isSelf ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: isMobile ? 20 : 22,
                                        backgroundColor: !isActive
                                            ? AppColors.tableOccupied.withAlpha(30)
                                            : isOwner
                                                ? const Color(0xFFFFB300).withAlpha(35)
                                                : AppColors.inputSurface,
                                        child: Icon(
                                          !isActive
                                              ? Icons.person_off_outlined
                                              : isOwner
                                                  ? Icons.verified_user
                                                  : Icons.person,
                                          size: isMobile ? 20 : 24,
                                          color: !isActive
                                              ? AppColors.tableOccupied
                                              : isOwner
                                                  ? const Color(0xFFFFB300)
                                                  : AppColors.secondaryText,
                                        ),
                                      ),
                                      SizedBox(width: isMobile ? 12 : 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: TextStyle(
                                                    color: isActive
                                                        ? AppColors.primaryText
                                                        : AppColors.secondaryText,
                                                    fontSize: isMobile ? 15 : 16,
                                                    fontWeight: FontWeight.w700,
                                                    decoration: !isActive
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (isSelf) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.brandAccent.withAlpha(40),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: AppColors.brandAccentLight.withAlpha(100),
                                                      ),
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
                                                // Role Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
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
                                                    isOwner ? 'OWNER' : 'EMPLOYEE',
                                                    style: TextStyle(
                                                      color: isOwner
                                                          ? const Color(0xFFFFB300)
                                                          : AppColors.secondaryText,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.4,
                                                    ),
                                                  ),
                                                ),
                                                // Active / Deactivated Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
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
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isActive
                                                            ? Icons.check_circle
                                                            : Icons.block,
                                                        size: 10,
                                                        color: isActive
                                                            ? AppColors.tableAvailable
                                                            : AppColors.tableOccupied,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isActive ? 'ACTIVE' : 'DEACTIVATED',
                                                        style: TextStyle(
                                                          color: isActive
                                                              ? AppColors.tableAvailable
                                                              : AppColors.tableOccupied,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isActive)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: user.isOnline
                                                          ? AppColors.tableAvailable.withAlpha(25)
                                                          : AppColors.cardBorderStroke,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 3,
                                                          backgroundColor: user.isOnline
                                                              ? AppColors.tableAvailable
                                                              : AppColors.textDisabled,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          user.isOnline ? 'ONLINE' : 'OFFLINE',
                                                          style: TextStyle(
                                                            color: user.isOnline
                                                                ? AppColors.tableAvailable
                                                                : AppColors.secondaryText,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            if (isMobile) ...[
                                              Text(
                                                user.email,
                                                style: const TextStyle(
                                                  color: AppColors.secondaryText,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                user.number,
                                                style: const TextStyle(
                                                  color: AppColors.secondaryText,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ] else ...[
                                              Text(
                                                'Email: ${user.email}  •  Phone: ${user.number}',
                                                style: const TextStyle(
                                                  color: AppColors.secondaryText,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (user.sessionExpiresAt != null && isActive) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    user.isSessionValid
                                                        ? Icons.check_circle_outline
                                                        : Icons.timer_off_outlined,
                                                    size: 13,
                                                    color: user.isSessionValid
                                                        ? AppColors.tableAvailable
                                                        : AppColors.secondaryText,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      user.isSessionValid
                                                          ? 'Session active until ${DateFormat('dd MMM yyyy, hh:mm a').format(user.sessionExpiresAt!)}'
                                                          : 'Session expired',
                                                      style: TextStyle(
                                                        color: user.isSessionValid
                                                            ? AppColors.tableAvailable
                                                            : AppColors.secondaryText,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
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

                                      // Actions for Owner on other users
                                      if (currentUser.isOwner && !isSelf) ...[
                                        Wrap(
                                          direction: isMobile ? Axis.vertical : Axis.horizontal,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            // Role Switcher Menu
                                            PopupMenuButton<String>(
                                              tooltip: 'Change Role',
                                              onSelected: (role) {
                                                AppHaptics.selection();
                                                context.read<AuthBloc>().add(
                                                      UpdateUserRoleEvent(
                                                        userId: user.id,
                                                        role: role,
                                                      ),
                                                    );
                                              },
                                              itemBuilder: (_) => [
                                                PopupMenuItem(
                                                  value: 'owner',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.verified_user,
                                                        size: 16,
                                                        color: isOwner
                                                            ? const Color(0xFFFFB300)
                                                            : AppColors.secondaryText,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Text('Owner Role'),
                                                      if (isOwner) ...[
                                                        const Spacer(),
                                                        const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Color(0xFFFFB300),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'employee',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.badge_outlined,
                                                        size: 16,
                                                        color: !isOwner
                                                            ? AppColors.brandAccentLight
                                                            : AppColors.secondaryText,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Text('Employee Role'),
                                                      if (!isOwner) ...[
                                                        const Spacer(),
                                                        const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: AppColors.brandAccentLight,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.inputSurface,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AppColors.cardBorderStroke,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      isOwner ? 'Owner' : 'Employee',
                                                      style: TextStyle(
                                                        color: isOwner
                                                            ? const Color(0xFFFFB300)
                                                            : AppColors.primaryText,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.arrow_drop_down,
                                                      size: 16,
                                                      color: AppColors.secondaryText,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Deactivate / Reactivate Action Button
                                            if (isActive)
                                              OutlinedButton.icon(
                                                onPressed: () => _confirmDeactivateUser(
                                                  context,
                                                  user,
                                                  activeCompany.name,
                                                ),
                                                icon: const Icon(
                                                  Icons.block,
                                                  size: 13,
                                                  color: AppColors.tableOccupied,
                                                ),
                                                label: const Text(
                                                  'Deactivate',
                                                  style: TextStyle(
                                                    color: AppColors.tableOccupied,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color: AppColors.tableOccupied.withAlpha(120),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              )
                                            else
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  AppHaptics.selection();
                                                  context.read<AuthBloc>().add(
                                                        ToggleUserActiveStatusEvent(
                                                          userId: user.id,
                                                          isActive: true,
                                                        ),
                                                      );
                                                },
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  'Reactivate',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.tableAvailable,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.secondaryText,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


