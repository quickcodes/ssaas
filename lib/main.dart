import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/i_audit_repository.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'domain/repositories/i_canteen_repository.dart';
import 'domain/repositories/i_club_repository.dart';
import 'domain/repositories/i_equipment_repository.dart';
import 'domain/repositories/i_expense_repository.dart';
import 'domain/repositories/i_shift_repository.dart';
import 'presentation/blocs/analytics/analytics_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/canteen_pos/canteen_pos_bloc.dart';
import 'presentation/blocs/equipment/equipment_bloc.dart';
import 'presentation/blocs/expense/expense_bloc.dart';
import 'presentation/blocs/floor_matrix/floor_matrix_bloc.dart';
import 'presentation/blocs/shift_audit/shift_audit_bloc.dart';
import 'presentation/views/dashboard/main_dashboard_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
            authRepo: sl<IAuthRepository>(),
            clubRepo: sl<IClubRepository>(),
          ),
        ),
        BlocProvider<FloorMatrixBloc>(
          create: (_) => FloorMatrixBloc(clubRepo: sl<IClubRepository>()),
        ),
        BlocProvider<CanteenPosBloc>(
          create: (_) => CanteenPosBloc(
            canteenRepo: sl<ICanteenRepository>(),
            shiftRepo: sl<IShiftRepository>(),
          ),
        ),
        BlocProvider<EquipmentBloc>(
          create: (_) =>
              EquipmentBloc(equipmentRepo: sl<IEquipmentRepository>()),
        ),
        BlocProvider<ShiftAuditBloc>(
          create: (_) => ShiftAuditBloc(
            shiftRepo: sl<IShiftRepository>(),
            auditRepo: sl<IAuditRepository>(),
          ),
        ),
        BlocProvider<ExpenseBloc>(
          create: (_) => ExpenseBloc(expenseRepo: sl<IExpenseRepository>()),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (_) => AnalyticsBloc(
            clubRepo: sl<IClubRepository>(),
            canteenRepo: sl<ICanteenRepository>(),
            expenseRepo: sl<IExpenseRepository>(),
            shiftRepo: sl<IShiftRepository>(),
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
