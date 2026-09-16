import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snooker/firebase_options.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/firestore_service.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/floor_matrix/floor_matrix_bloc.dart';
import 'presentation/views/dashboard/main_dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupServiceLocator();
  runApp(const SnookerClubApp());
}

class SnookerClubApp extends StatelessWidget {
  const SnookerClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            firestoreService: sl<FirestoreService>(),
          ),
        ),
        BlocProvider<FloorMatrixBloc>(
          create: (_) => FloorMatrixBloc(
            firestoreService: sl<FirestoreService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'CueClub OS - Snooker & Billiards Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainDashboardView(),
      ),
    );
  }
}
