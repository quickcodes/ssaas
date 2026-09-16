import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';

class CompanyUsersView extends StatelessWidget {
  const CompanyUsersView({super.key});

  void _showAddUserDialog(BuildContext context, String companyId) {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add_outlined, color: AppColors.brandAccentLight),
              SizedBox(width: 10),
              Text(
                'Add Associated User',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberCtrl,
                    decoration: const InputDecoration(labelText: 'Phone Number *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password *'),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text(
                      'Make this user Admin',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                    subtitle: const Text(
                      'Admins can create users, make other admins, and configure tables.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    value: isAdmin,
                    activeColor: AppColors.brandAccent,
                    onChanged: (val) => setState(() => isAdmin = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
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
                if (nameCtrl.text.trim().isEmpty ||
                    numberCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty ||
                    passwordCtrl.text.isEmpty) {
                  return;
                }

                final newUser = UserAccount(
                  id: '',
                  companyId: companyId,
                  name: nameCtrl.text.trim(),
                  number: numberCtrl.text.trim(),
                  email: emailCtrl.text.trim().toLowerCase(),
                  password: passwordCtrl.text,
                  isAdmin: isAdmin,
                  createdAt: DateTime.now(),
                );

                Navigator.of(dialogCtx).pop();
                context.read<AuthBloc>().add(CreateCompanyUserEvent(newUser));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
              ),
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
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
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header
                Wrap(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  runSpacing: 10,
                  spacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 4),
                        const Text(
                          'Associated Company Users',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddUserDialog(context, activeCompany.id),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Users List
                Expanded(
                  child: users.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found in this company.',
                            style: TextStyle(color: AppColors.secondaryText),
                          ),
                        )
                      : ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isSelf = user.id == currentUser.id;

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: user.isAdmin
                                      ? AppColors.brandAccent.withAlpha(80)
                                      : AppColors.cardBorderStroke,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: user.isAdmin
                                        ? AppColors.brandAccent.withAlpha(40)
                                        : AppColors.inputSurface,
                                    child: Icon(
                                      user.isAdmin
                                          ? Icons.shield
                                          : Icons.person,
                                      color: user.isAdmin
                                          ? AppColors.brandAccentLight
                                          : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
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
                                                style: const TextStyle(
                                                  color: AppColors.primaryText,
                                                  fontSize: 16,
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
                                                  color: AppColors.inputSurface,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'YOU',
                                                  style: TextStyle(
                                                    color: AppColors
                                                        .brandAccentLight,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Email: ${user.email}  •  Phone: ${user.number}',
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                  // Admin status indicator / switch
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
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
                                              : 'Associate',
                                          style: TextStyle(
                                            color: user.isAdmin
                                                ? AppColors.brandAccentLight
                                                : AppColors.secondaryText,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (!isSelf) ...[
                                          const SizedBox(width: 8),
                                          Switch(
                                            value: user.isAdmin,
                                            activeThumbColor: AppColors.brandAccent,
                                            onChanged: (val) {
                                              context.read<AuthBloc>().add(
                                                    ToggleUserAdminStatusEvent(
                                                      userId: user.id,
                                                      isAdmin: val,
                                                    ),
                                                  );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
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
