import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/interactive_feedback.dart';
import '../../data/datasources/firestore_service.dart';
import '../../domain/entities/app_download_config.dart';

/// Wraps the application and restricts usage if the installed app version
/// is strictly less than the `minVersion` specified in the `appConfig` Firestore collection.
class AppVersionGuard extends StatefulWidget {
  final Widget child;

  const AppVersionGuard({super.key, required this.child});

  @override
  State<AppVersionGuard> createState() => _AppVersionGuardState();
}

class _AppVersionGuardState extends State<AppVersionGuard> {
  bool _isDevBypassed = false;

  Future<void> _openDownloadLink(BuildContext context, String downloadUrl) async {
    AppHaptics.selection();
    if (downloadUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download link is not configured yet. Please contact support.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(downloadUrl.trim());
    if (uri == null || !uri.hasScheme) {
      await Clipboard.setData(ClipboardData(text: downloadUrl));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL copied to clipboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: downloadUrl));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download URL copied to clipboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: downloadUrl));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download link copied to clipboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDevBypassed && Constants.isAdmin) {
      return widget.child;
    }

    return StreamBuilder<AppDownloadConfig>(
      stream: sl<FirestoreService>().watchAppDownloadConfig(),
      builder: (context, snapshot) {
        // If still loading initial snapshot or an error occurred, allow normal flow
        if (!snapshot.hasData || snapshot.hasError) {
          return widget.child;
        }

        final config = snapshot.data!;
        final isUpdateRequired = config.isUpdateRequired(Constants.appVersion);

        if (!isUpdateRequired || (_isDevBypassed && Constants.isAdmin)) {
          return widget.child;
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.brandAccent.withAlpha(90),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(160),
                        blurRadius: 36,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing update icon
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandAccent.withAlpha(28),
                          border: Border.all(
                            color: AppColors.brandAccent.withAlpha(120),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandAccent.withAlpha(50),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.brandAccentLight,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'App Update Required',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        'A newer version of ${Constants.appName} is required to continue. Please update to ensure data accuracy, billing safety, and system compatibility.',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),

                      // Version chips container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundBase,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorderStroke),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Current version
                            Column(
                              children: [
                                const Text(
                                  'Your Version',
                                  style: TextStyle(
                                    color: AppColors.textDisabled,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.tableOccupied.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.tableOccupied.withAlpha(80),
                                    ),
                                  ),
                                  child: const Text(
                                    'v${Constants.appVersion}',
                                    style: TextStyle(
                                      color: AppColors.tableOccupied,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.textDisabled,
                              size: 18,
                            ),

                            // Required version
                            Column(
                              children: [
                                const Text(
                                  'Minimum Required',
                                  style: TextStyle(
                                    color: AppColors.textDisabled,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676).withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF00E676).withAlpha(90),
                                    ),
                                  ),
                                  child: Text(
                                    'v${config.minVersion}',
                                    style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Release notes if available
                      if (config.notes != null && config.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.brandAccent.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.brandAccent.withAlpha(50),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.new_releases_outlined,
                                    size: 15,
                                    color: AppColors.brandAccentLight,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'What\'s New in this update:',
                                    style: TextStyle(
                                      color: AppColors.brandAccentLight,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                config.notes!.trim(),
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 26),

                      // Update CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _openDownloadLink(context, config.downloadUrl),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text(
                            'Download & Update App',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Copy link button
                      if (config.hasValidUrl)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              AppHaptics.light();
                              Clipboard.setData(ClipboardData(text: config.downloadUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download link copied to clipboard.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text(
                              'Copy Download Link',
                              style: TextStyle(fontSize: 12.5),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondaryText,
                            ),
                          ),
                        ),

                      // Dev admin bypass link (only visible if Constants.isAdmin == true)
                      if (Constants.isAdmin) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            AppHaptics.medium();
                            setState(() => _isDevBypassed = true);
                          },
                          child: const Text(
                            'Dev Admin: Bypass Guard (Dev Only)',
                            style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
