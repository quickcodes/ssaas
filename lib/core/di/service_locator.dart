import 'package:get_it/get_it.dart';
import '../../data/datasources/firestore_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Firestore Data Source
  final firestoreService = FirestoreService();
  sl.registerSingleton<FirestoreService>(firestoreService);
}
