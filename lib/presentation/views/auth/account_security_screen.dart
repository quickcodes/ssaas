import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/bouncing_tap.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
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
    _newPasswordCtrl.addListener(_onFormUpdated);
    _confirmPasswordCtrl.addListener(_onFormUpdated);
    _currentPasswordCtrl.addListener(_onFormUpdated);
  }

  void _onFormUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newPasswordCtrl.removeListener(_onFormUpdated);
    _confirmPasswordCtrl.removeListener(_onFormUpdated);
    _currentPasswordCtrl.removeListener(_onFormUpdated);

    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
          content: const Text('Current password is incorrect. Please verify and try again.'),
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
          content: const Text('New password cannot be identical to your current password.'),
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
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
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

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          appBar: AppBar(
            backgroundColor: AppColors.cardSurface,
            elevation: 0,
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
                  Icons.shield_outlined,
                  color: AppColors.brandAccentLight,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Password & Security',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Account & Current Password Card
                    _buildAccountDetailsCard(currentUser, activeCompany?.name),

                    const SizedBox(height: 24),

                    // Change Password Form Card
                    _buildChangePasswordCard(currentUser, authState.isLoading),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountDetailsCard(UserAccount user, String? companyName) {
    final roleName = user.isOwner
        ? 'Owner'
        : (user.isAdmin ? 'Admin' : 'Operator');

    final roleColor = user.isOwner
        ? AppColors.tableAvailable
        : (user.isAdmin ? AppColors.brandAccentLight : const Color(0xFF64B5F6));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.number.isNotEmpty ? user.number : user.email,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (companyName != null && companyName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        companyName,
                        style: TextStyle(
                          color: AppColors.brandAccentLight.withAlpha(200),
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

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.cardBorderStroke),
          const SizedBox(height: 18),

          // Current Password Viewer Section
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
                    _showSavedPassword ? user.password : '•' * (user.password.length > 3 ? user.password.length : 8),
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: _showSavedPassword ? 15 : 20,
                      letterSpacing: _showSavedPassword ? 0.5 : 2.0,
                      fontWeight: _showSavedPassword ? FontWeight.w700 : FontWeight.w900,
                      fontFamily: _showSavedPassword ? null : 'Courier',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _showSavedPassword ? 'Hide Password' : 'Show Password',
                  icon: Icon(
                    _showSavedPassword ? Icons.visibility_off : Icons.visibility,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 4),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose a new strong password for your account',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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
                    _obscureCurrentInput ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () {
                    setState(() => _obscureCurrentInput = !_obscureCurrentInput);
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

            const SizedBox(height: 16),

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

            const SizedBox(height: 16),

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
                    _obscureConfirmInput ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmInput = !_obscureConfirmInput);
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

            const SizedBox(height: 16),

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

            const SizedBox(height: 24),

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
                          fontSize: 14,
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
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
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
