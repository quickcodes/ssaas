import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
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

        if (!currentUser.isAdmin) {
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
                    'Admin Access Only',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Only Admin users of this company can create new users and manage permissions.',
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
                                        ? AppColors.brandAccent.withAlpha(120)
                                        : user.isAdmin
                                            ? AppColors.brandAccent.withAlpha(80)
                                            : AppColors.cardBorderStroke,
                                    width: isSelf ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: isMobile ? 20 : 22,
                                      backgroundColor: user.isAdmin
                                          ? AppColors.brandAccent.withAlpha(40)
                                          : AppColors.inputSurface,
                                      child: Icon(
                                        user.isAdmin
                                            ? Icons.shield
                                            : Icons.person,
                                        size: isMobile ? 20 : 24,
                                        color: user.isAdmin
                                            ? AppColors.brandAccentLight
                                            : AppColors.secondaryText,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 12 : 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  user.name,
                                                  style: TextStyle(
                                                    color: AppColors.primaryText,
                                                    fontSize: isMobile ? 15 : 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelf) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.brandAccent.withAlpha(40),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
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
                                              const SizedBox(width: 8),
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
                                          const SizedBox(height: 4),
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
                                          if (user.sessionExpiresAt != null) ...[
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
                                                        ? 'Active until ${DateFormat('dd MMM yyyy, hh:mm a').format(user.sessionExpiresAt!)}'
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
                                    // Admin status indicator / switch
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 8 : 10,
                                        vertical: isMobile ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.isAdmin
                                            ? AppColors.brandAccent.withAlpha(30)
                                            : AppColors.inputSurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: user.isAdmin
                                              ? AppColors.brandAccent
                                              : AppColors.cardBorderStroke,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            user.isAdmin
                                                ? 'Admin'
                                                : 'Staff',
                                            style: TextStyle(
                                              color: user.isAdmin
                                                  ? AppColors.brandAccentLight
                                                  : AppColors.secondaryText,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isMobile ? 11 : 12,
                                            ),
                                          ),
                                          if (!isSelf) ...[
                                            SizedBox(width: isMobile ? 4 : 8),
                                            Transform.scale(
                                              scale: isMobile ? 0.8 : 0.9,
                                              child: Switch(
                                                value: user.isAdmin,
                                                activeThumbColor: AppColors.brandAccent,
                                                onChanged: (val) {
                                                  AppHaptics.selection();
                                                  context.read<AuthBloc>().add(
                                                        ToggleUserAdminStatusEvent(
                                                          userId: user.id,
                                                          isAdmin: val,
                                                        ),
                                                      );
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
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


