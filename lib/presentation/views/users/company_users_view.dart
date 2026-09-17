import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/bouncing_tap.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/fade_slide_transition.dart';

class CompanyUsersView extends StatelessWidget {
  const CompanyUsersView({super.key});

  void _showAddUserDialog(BuildContext context, String companyId) {
    showAdaptiveModal(
      context: context,
      builder: (dialogCtx) => _AddUserModal(
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
                                  ],
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

class _AddUserModal extends StatefulWidget {
  final String companyId;
  final ValueChanged<UserAccount> onAddUser;

  const _AddUserModal({
    required this.companyId,
    required this.onAddUser,
  });

  @override
  State<_AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<_AddUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isAdmin = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AppHaptics.medium();

    final newUser = UserAccount(
      id: '',
      companyId: widget.companyId,
      name: _nameCtrl.text.trim(),
      number: _numberCtrl.text.trim(),
      email: _emailCtrl.text.trim().toLowerCase(),
      password: _passwordCtrl.text,
      isAdmin: _isAdmin,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop();
    widget.onAddUser(newUser);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: isMobile
            ? MediaQuery.sizeOf(context).height * 0.88
            : MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 26,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile)
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    color: AppColors.brandAccentLight,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Add Associated User',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.secondaryText),
                onPressed: () {
                  AppHaptics.light();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _numberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Phone number is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!val.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.secondaryText,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (val) => val == null || val.length < 4
                          ? 'Password must be at least 4 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: CheckboxListTile(
                        title: const Text(
                          'Make this user Admin',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Admins can create users, change roles, and configure tables.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                        value: _isAdmin,
                        activeColor: AppColors.brandAccent,
                        onChanged: (val) {
                          AppHaptics.selection();
                          setState(() => _isAdmin = val ?? false);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BouncingTap(
                  onTap: _submit,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add User'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

