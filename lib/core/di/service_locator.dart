import 'package:get_it/get_it.dart';
import '../../data/datasources/firestore_service.dart';
import '../../data/datasources/session_local_storage.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Firestore Data Source
  final firestoreService = FirestoreService();
  sl.registerSingleton<FirestoreService>(firestoreService);

  // Local Session Storage
  final sessionStorage = SessionLocalStorage();
  sl.registerSingleton<SessionLocalStorage>(sessionStorage);
}
