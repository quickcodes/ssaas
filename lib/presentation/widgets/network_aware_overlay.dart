import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/network_connectivity_service.dart';
import '../../core/theme/app_colors.dart';

class NetworkAwareOverlay extends StatelessWidget {
  final Widget child;

  const NetworkAwareOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectivity = sl<NetworkConnectivityService>();

    return ValueListenableBuilder<bool>(
      valueListenable: connectivity.isOnline,
      builder: (context, isOnline, _) {
        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            // Underlying application screen
            IgnorePointer(
              ignoring: !isOnline,
              child: child,
            ),

            // Blocking full-screen overlay when offline
            if (!isOnline)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    color: AppColors.backgroundBase.withAlpha(240),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.tableOccupied.withAlpha(120),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tableOccupied.withAlpha(40),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withAlpha(150),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glowing Offline Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.tableOccupied.withAlpha(25),
                                border: Border.all(
                                  color: AppColors.tableOccupied.withAlpha(120),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.wifi_off_rounded,
                                  size: 40,
                                  color: AppColors.tableOccupied,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Heading
                            const Text(
                              'No Internet Connection',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            const Text(
                              'CueClub OS requires an active internet connection to synchronize tables, match timers, billing, and cloud records.\n\nPlease check your Wi-Fi or mobile data network to continue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Retry Button
                            ValueListenableBuilder<bool>(
                              valueListenable: connectivity.isChecking,
                              builder: (context, isChecking, _) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: isChecking
                                        ? null
                                        : () => connectivity.checkConnection(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: isChecking
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.refresh_rounded, size: 20),
                                    label: Text(
                                      isChecking
                                          ? 'CHECKING CONNECTION...'
                                          : 'RETRY CONNECTION',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Auto-retry status note
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.tableOccupied,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Waiting for network to reconnect...',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
