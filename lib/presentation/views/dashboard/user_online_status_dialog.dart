import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';

class UserOnlineStatusDialog extends StatelessWidget {
  final UserAccount currentUser;
  final Company activeCompany;

  const UserOnlineStatusDialog({
    super.key,
    required this.currentUser,
    required this.activeCompany,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<AuthBloc>().add(ClearAuthErrorEvent());
        }
      },
      builder: (context, state) {
        // Find live user account from companyUsers if available
        final liveUser = state.companyUsers.firstWhere(
          (u) => u.id == currentUser.id,
          orElse: () => state.currentUser ?? currentUser,
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

        return Dialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: EdgeInsets.all(isMobile ? 18 : 24),
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
                      onPressed: () => Navigator.of(context).pop(),
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
                          Text(
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
                                          ' is currently Online. That user must go offline before you can go online.',
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

                // Action Toggle Button
                ElevatedButton.icon(
                  onPressed: () {
                    AppHaptics.medium();
                    if (isOnline) {
                      // Toggle offline
                      context.read<AuthBloc>().add(
                            ToggleUserOnlineStatusEvent(
                              userId: liveUser.id,
                              isOnline: false,
                            ),
                          );
                      Navigator.of(context).pop();
                    } else {
                      // Toggle online
                      if (hasConflict) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${otherOnlineUser?.name ?? "Another operator"} is currently Online. That user must go offline before you can go online.',
                            ),
                            backgroundColor: AppColors.tableOccupied,
                          ),
                        );
                        return;
                      }

                      context.read<AuthBloc>().add(
                            ToggleUserOnlineStatusEvent(
                              userId: liveUser.id,
                              isOnline: true,
                            ),
                          );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(
                    isOnline ? Icons.pause_circle_outline : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(
                    isOnline ? 'END SHIFT (GO OFFLINE)' : 'TAKE SHIFT (GO ONLINE)',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline
                        ? AppColors.tableOccupied
                        : (hasConflict
                            ? AppColors.inputSurface
                            : AppColors.tableAvailable),
                    foregroundColor: hasConflict ? AppColors.secondaryText : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
        );
      },
    );
  }
}
