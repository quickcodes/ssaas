import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/constants/constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/firestore_service.dart';
import 'data/datasources/session_local_storage.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/floor_matrix/floor_matrix_bloc.dart';
import 'presentation/views/dashboard/main_dashboard_view.dart';
import 'presentation/widgets/network_aware_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
