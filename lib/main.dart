import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/constants/constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/firestore_service.dart';
import 'data/datasources/session_local_storage.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/floor_matrix/floor_matrix_bloc.dart';
import 'presentation/views/dashboard/main_dashboard_view.dart';
import 'presentation/widgets/network_aware_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter framework error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // Global uncaught platform / asynchronous error handling
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[UncaughtAsyncError] $error\n$stack');
    return true; // Mark as handled to avoid crashing the app process
  };

  // Safe UI fallback widget for any widget rendering errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppColors.backgroundBase,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorderStroke),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Temporary Display Issue',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupServiceLocator();
  runApp(const SsaasApp());
}

class SsaasApp extends StatelessWidget {
  const SsaasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            firestoreService: sl<FirestoreService>(),
            sessionLocalStorage: sl<SessionLocalStorage>(),
          ),
        ),
        BlocProvider<FloorMatrixBloc>(
          create: (_) => FloorMatrixBloc(
            firestoreService: sl<FirestoreService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: '${Constants.appName} - Snooker & Billiards Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainDashboardView(),
        builder: (context, child) => NetworkAwareOverlay(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Backward compatibility alias for [SsaasApp].
typedef SnookerClubApp = SsaasApp;
