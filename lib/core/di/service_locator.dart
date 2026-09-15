import 'package:get_it/get_it.dart';
import '../../data/datasources/local_data_store.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/canteen_repository_impl.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../data/repositories/equipment_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../domain/repositories/i_audit_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_canteen_repository.dart';
import '../../domain/repositories/i_club_repository.dart';
import '../../domain/repositories/i_equipment_repository.dart';
import '../../domain/repositories/i_expense_repository.dart';
import '../../domain/repositories/i_shift_repository.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Data Source
  final localDataStore = LocalDataStore();
  sl.registerSingleton<LocalDataStore>(localDataStore);

  // Repositories
  sl.registerLazySingleton<IClubRepository>(() => ClubRepositoryImpl(sl<LocalDataStore>()));
  sl.registerLazySingleton<ICanteenRepository>(() => CanteenRepositoryImpl(sl<LocalDataStore>()));
  sl.registerLazySingleton<IEquipmentRepository>(() => EquipmentRepositoryImpl(sl<LocalDataStore>()));
  sl.registerLazySingleton<IShiftRepository>(() => ShiftRepositoryImpl(sl<LocalDataStore>()));
  sl.registerLazySingleton<IExpenseRepository>(() => ExpenseRepositoryImpl(sl<LocalDataStore>()));
  sl.registerLazySingleton<IAuditRepository>(() => AuditRepositoryImpl(sl<LocalDataStore>()));
  sl.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl(sl<LocalDataStore>()));
}
