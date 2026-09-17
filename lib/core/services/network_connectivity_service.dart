import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _heartbeatTimer;

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isChecking = ValueNotifier<bool>(false);

  void initialize() {
    // Initial verification
    checkConnection();

    // Listen for interface changes (WiFi / Cellular / Ethernet / None)
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityResults(results);
    });

    // Heartbeat: When offline, automatically probe every 4 seconds to recover seamlessly
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!isOnline.value && !isChecking.value) {
        checkConnection();
      }
    });
  }

  void _handleConnectivityResults(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (!hasNetwork) {
      isOnline.value = false;
    } else {
      checkConnection();
    }
  }

  Future<bool> checkConnection() async {
    isChecking.value = true;
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) {
        isOnline.value = false;
        isChecking.value = false;
        return false;
      }

      if (kIsWeb) {
        // Raw DNS sockets not supported on web
        isOnline.value = true;
        isChecking.value = false;
        return true;
      }

      // Check real internet via DNS lookup with 3s timeout
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final online = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      isOnline.value = online;
      isChecking.value = false;
      return online;
    } catch (_) {
      isOnline.value = false;
      isChecking.value = false;
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _heartbeatTimer?.cancel();
    isOnline.dispose();
    isChecking.dispose();
  }
}
