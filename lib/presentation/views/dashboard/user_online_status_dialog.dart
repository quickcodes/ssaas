import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';

class UserOnlineStatusDialog extends StatefulWidget {
  final UserAccount currentUser;
  final Company activeCompany;

  const UserOnlineStatusDialog({
    super.key,
    required this.currentUser,
    required this.activeCompany,
  });

  @override
  State<UserOnlineStatusDialog> createState() => _UserOnlineStatusDialogState();
}

class _UserOnlineStatusDialogState extends State<UserOnlineStatusDialog> {
  bool _isSubmitting = false;

  void _handleShiftToggle({
    required UserAccount liveUser,
    required bool isOnline,
  }) {
    AppHaptics.medium();
    setState(() => _isSubmitting = true);

    context.read<AuthBloc>().add(
          ToggleUserOnlineStatusEvent(
            userId: liveUser.id,
            isOnline: !isOnline,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          if (mounted) setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AuthBloc>().add(ClearAuthErrorEvent());
        } else if (state.successMessage != null && _isSubmitting) {
          if (mounted) setState(() => _isSubmitting = false);
          AppHaptics.selection();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.tableAvailable,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AuthBloc>().add(ClearAuthErrorEvent());
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        // Find live user account from companyUsers if available
        final liveUser = state.companyUsers.firstWhere(
          (u) => u.id == widget.currentUser.id,
          orElse: () => state.currentUser ?? widget.currentUser,
        );

        final isOnline = liveUser.isOnline;

        // Check if another operator in the company is currently online
        UserAccount? otherOnlineUser;
        for (final u in state.companyUsers) {
          if (u.id != liveUser.id && u.isOnline) {
            otherOnlineUser = u;
            break;
          }
        }

        final hasConflict = !isOnline && otherOnlineUser != null;
        final isBusy = _isSubmitting || state.isLoading;

        return Dialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 480,
            ),
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.tableAvailable.withAlpha(30)
                              : AppColors.cardBorderStroke,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOnline ? Icons.bolt : Icons.power_settings_new,
                          size: 22,
                          color: isOnline
                              ? AppColors.tableAvailable
                              : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OPERATOR SHIFT STATUS',
                              style: TextStyle(
                                color: AppColors.secondaryText,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.secondaryText),
                        onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Current Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.tableAvailable.withAlpha(20)
                          : AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOnline
                            ? AppColors.tableAvailable.withAlpha(90)
                            : AppColors.cardBorderStroke,
                        width: isOnline ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? AppColors.tableAvailable
                                    : AppColors.textDisabled,
                                shape: BoxShape.circle,
                                boxShadow: isOnline
                                    ? [
                                        BoxShadow(
                                          color: AppColors.tableAvailable.withAlpha(120),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isOnline
                                    ? 'ACTIVE OPERATOR (ONLINE)'
                                    : 'STANDBY MODE (OFFLINE)',
                                style: TextStyle(
                                  color: isOnline
                                      ? AppColors.tableAvailable
                                      : AppColors.secondaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (isBusy)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOnline
                              ? 'You are currently the active operator. You have full authority to start table matches, add items, and checkout/close tables.'
                              : 'You are currently offline. Tables can only be opened or closed by the user who is actively Online.',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        if (isBusy) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: AppColors.cardBorderStroke,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOnline
                                    ? AppColors.tableOccupied
                                    : AppColors.tableAvailable,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Conflict Banner (if another operator is online)
                  if (hasConflict) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withAlpha(90)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ANOTHER OPERATOR IS ONLINE',
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: otherOnlineUser.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.tableAvailable,
                                        ),
                                      ),
                                      const TextSpan(
                                        text:
                                            ' is currently Online. That operator must go Offline before you can take the shift.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Toggle Button with dynamic loading feedback
                  ElevatedButton(
                    onPressed: (isBusy || hasConflict)
                        ? null
                        : () => _handleShiftToggle(
                              liveUser: liveUser,
                              isOnline: isOnline,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnline
                          ? AppColors.tableOccupied
                          : AppColors.tableAvailable,
                      foregroundColor: isOnline ? Colors.white : Colors.black,
                      disabledBackgroundColor: hasConflict
                          ? AppColors.inputSurface
                          : (isOnline
                                  ? AppColors.tableOccupied
                                  : AppColors.tableAvailable)
                              .withAlpha(150),
                      disabledForegroundColor: hasConflict
                          ? AppColors.textDisabled
                          : Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isBusy
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: isOnline ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isOnline
                                    ? 'ENDING SHIFT...'
                                    : 'TAKING SHIFT (GOING ONLINE)...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOnline
                                    ? Icons.pause_circle_outline
                                    : Icons.play_arrow,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOnline
                                    ? 'END SHIFT (GO OFFLINE)'
                                    : (hasConflict
                                        ? 'CANNOT GO ONLINE (ANOTHER OPERATOR ACTIVE)'
                                        : 'TAKE SHIFT (GO ONLINE)'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 18),

                  // All Operators Roster
                  const Text(
                    'CLUB OPERATORS & STATUS',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Column(
                        children: state.companyUsers.map((u) {
                          final isThisOnline = u.isOnline;
                          final isSelf = u.id == liveUser.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isThisOnline
                                  ? AppColors.tableAvailable.withAlpha(15)
                                  : AppColors.inputSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isThisOnline
                                    ? AppColors.tableAvailable.withAlpha(60)
                                    : AppColors.cardBorderStroke,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: isThisOnline
                                      ? AppColors.tableAvailable
                                      : AppColors.textDisabled,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${u.name}${isSelf ? " (You)" : ""}',
                                    style: TextStyle(
                                      color: isThisOnline
                                          ? AppColors.primaryText
                                          : AppColors.secondaryText,
                                      fontSize: 12,
                                      fontWeight: isThisOnline
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isThisOnline
                                        ? AppColors.tableAvailable.withAlpha(30)
                                        : AppColors.cardBorderStroke,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isThisOnline ? 'ONLINE' : 'OFFLINE',
                                    style: TextStyle(
                                      color: isThisOnline
                                          ? AppColors.tableAvailable
                                          : AppColors.textDisabled,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
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
}
