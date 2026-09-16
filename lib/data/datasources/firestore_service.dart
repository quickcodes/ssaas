import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/club_table.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/table_billing_item.dart';
import '../../domain/entities/table_history_record.dart';
import '../../domain/entities/table_session.dart';
import '../../domain/entities/user_account.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // -------------------------------------------------------------
  // COMPANIES COLLECTION
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _companiesCol =>
      _firestore.collection('companies');

  Stream<List<Company>> watchCompanies() {
    return _companiesCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Company.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<List<Company>> getCompanies() async {
    final snapshot = await _companiesCol.get();
    return snapshot.docs.map((doc) => Company.fromMap(doc.id, doc.data())).toList();
  }

  Stream<Company?> watchCompany(String companyId) {
    return _companiesCol.doc(companyId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Company.fromMap(doc.id, doc.data()!);
    });
  }

  Future<Company?> getCompanyById(String companyId) async {
    final doc = await _companiesCol.doc(companyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Company.fromMap(doc.id, doc.data()!);
  }

  /// Dev-only company creation with initial admin user
  Future<Company> createCompanyWithInitialAdmin({
    required String name,
    required String number,
    required DateTime expiryDate,
    required String initialUserName,
    required String initialUserNumber,
    required String initialUserEmail,
    required String initialUserPassword,
  }) async {
    final companyDoc = _companiesCol.doc();
    final companyId = companyDoc.id;
    final now = DateTime.now();

    final company = Company(
      id: companyId,
      name: name.trim(),
      number: number.trim(),
      expiryDate: expiryDate,
      createdAt: now,
    );

    // Batch write to atomically create company and initial admin user
    final batch = _firestore.batch();
    batch.set(companyDoc, company.toMap());

    final userDoc = companyDoc.collection('users').doc();
    final initialAdmin = UserAccount(
      id: userDoc.id,
      companyId: companyId,
      name: initialUserName.trim(),
      number: initialUserNumber.trim(),
      email: initialUserEmail.trim().toLowerCase(),
      password: initialUserPassword,
      isAdmin: true, // Always admin by default as required
      createdAt: now,
    );
    batch.set(userDoc, initialAdmin.toMap());

    await batch.commit();
    return company;
  }

  // -------------------------------------------------------------
  // USERS SUBCOLLECTION: companies/{companyId}/users
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _usersCol(String companyId) =>
      _companiesCol.doc(companyId).collection('users');

  Stream<List<UserAccount>> watchCompanyUsers(String companyId) {
    return _usersCol(companyId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserAccount.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<UserAccount>> getCompanyUsers(String companyId) async {
    final snapshot = await _usersCol(companyId).get();
    return snapshot.docs
        .map((doc) => UserAccount.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<UserAccount?> loginUser(
    String companyId,
    String emailOrNumber,
    String password,
  ) async {
    final normalized = emailOrNumber.trim().toLowerCase();
    final users = await getCompanyUsers(companyId);
    try {
      final user = users.firstWhere(
        (u) =>
            (u.email.toLowerCase() == normalized || u.number.trim() == normalized) &&
            u.password == password,
      );
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> createUser(UserAccount user) async {
    final doc = user.id.isEmpty
        ? _usersCol(user.companyId).doc()
        : _usersCol(user.companyId).doc(user.id);
    await doc.set(user.toMap());
  }

  Future<void> updateUserAdminStatus(
    String companyId,
    String userId,
    bool isAdmin,
  ) async {
    await _usersCol(companyId).doc(userId).update({'isAdmin': isAdmin});
  }

  Future<UserAccount?> getUserById(String companyId, String userId) async {
    try {
      final doc = await _usersCol(companyId).doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserAccount.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserSession(
    String companyId,
    String userId,
    DateTime? sessionExpiresAt,
  ) async {
    await _usersCol(companyId).doc(userId).set({
      'sessionExpiresAt': sessionExpiresAt != null
          ? Timestamp.fromDate(sessionExpiresAt)
          : null,
    }, SetOptions(merge: true));
  }

  // -------------------------------------------------------------
  // SNOOKER TABLES SUBCOLLECTION: companies/{companyId}/snookerTables
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _tablesCol(String companyId) =>
      _companiesCol.doc(companyId).collection('snookerTables');

  Stream<List<ClubTable>> watchTables(String companyId) {
    return _tablesCol(companyId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ClubTable.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<ClubTable>> getTables(String companyId) async {
    final snapshot = await _tablesCol(companyId).get();
    return snapshot.docs
        .map((doc) => ClubTable.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<ClubTable?> getTableById(String companyId, String tableId) async {
    final doc = await _tablesCol(companyId).doc(tableId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ClubTable.fromMap(doc.id, doc.data()!);
  }

  Future<void> saveTable(ClubTable table) async {
    final doc = table.id.isEmpty
        ? _tablesCol(table.companyId).doc()
        : _tablesCol(table.companyId).doc(table.id);
    await doc.set(table.toMap());
  }

  Future<void> updateTableStatus(
    String companyId,
    String tableId,
    TableStatus status, {
    String? sessionId,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.displayName,
      'currentSessionId': sessionId,
    };
    await _tablesCol(companyId).doc(tableId).update(updateData);
  }

  Future<void> deleteTable(String companyId, String tableId) async {
    await _tablesCol(companyId).doc(tableId).delete();
  }

  // -------------------------------------------------------------
  // RUNNING TABLES SUBCOLLECTION: companies/{companyId}/runningTables
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _runningCol(String companyId) =>
      _companiesCol.doc(companyId).collection('runningTables');

  Stream<List<TableSession>> watchRunningTables(String companyId) {
    return _runningCol(companyId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TableSession.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<TableSession?> getRunningSession(String companyId, String sessionId) async {
    final doc = await _runningCol(companyId).doc(sessionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TableSession.fromMap(doc.id, doc.data()!);
  }

  Future<void> startSession(TableSession session) async {
    final batch = _firestore.batch();
    final runningDoc = _runningCol(session.companyId).doc(session.id);
    batch.set(runningDoc, session.toMap());

    final tableDoc = _tablesCol(session.companyId).doc(session.tableId);
    batch.update(tableDoc, {
      'status': TableStatus.occupied.displayName,
      'currentSessionId': session.id,
    });

    await batch.commit();
  }

  Future<void> updateRunningSession(TableSession session) async {
    await _runningCol(session.companyId).doc(session.id).set(session.toMap());
  }

  Future<void> pauseSession(String companyId, String sessionId) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    await sessionDoc.update({
      'isPaused': true,
      'lastPauseTime': Timestamp.now(),
    });
  }

  Future<void> resumeSession(String companyId, String sessionId) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    final doc = await sessionDoc.get();
    if (!doc.exists || doc.data() == null) return;
    final session = TableSession.fromMap(doc.id, doc.data()!);
    if (!session.isPaused || session.lastPauseTime == null) return;

    final additionalPause =
        DateTime.now().difference(session.lastPauseTime!).inSeconds;
    final totalPaused = session.pausedSeconds + additionalPause;

    await sessionDoc.update({
      'isPaused': false,
      'lastPauseTime': null,
      'pausedSeconds': totalPaused,
    });
  }

  Future<void> addItemToRunningSession(
    String companyId,
    String sessionId,
    TableBillingItem item,
  ) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    final doc = await sessionDoc.get();
    if (!doc.exists || doc.data() == null) return;
    final session = TableSession.fromMap(doc.id, doc.data()!);
    final updatedItems = List<TableBillingItem>.from(session.items)..add(item);
    await sessionDoc.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
    });
  }

  /// Closes the running session, saves the history record, and frees the table
  Future<void> closeSession({
    required String companyId,
    required String sessionId,
    required TableHistoryRecord historyRecord,
  }) async {
    final batch = _firestore.batch();

    // 1. Write to tablesHistory
    final historyDoc = _historyCol(companyId).doc(historyRecord.id);
    batch.set(historyDoc, historyRecord.toMap());

    // 2. Remove from runningTables
    final runningDoc = _runningCol(companyId).doc(sessionId);
    batch.delete(runningDoc);

    // 3. Reset table status to Available
    final tableDoc = _tablesCol(companyId).doc(historyRecord.tableId);
    batch.update(tableDoc, {
      'status': TableStatus.available.displayName,
      'currentSessionId': null,
    });

    await batch.commit();
  }

  // -------------------------------------------------------------
  // EQUIPMENT / STOCK SUBCOLLECTION: companies/{companyId}/equipmentStock
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _equipmentCol(String companyId) =>
      _companiesCol.doc(companyId).collection('equipmentStock');

  Stream<List<StockItem>> watchEquipmentStock(String companyId) {
    return _equipmentCol(companyId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StockItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> saveEquipmentItem(StockItem item) async {
    final doc = item.id.isEmpty
        ? _equipmentCol(item.companyId).doc()
        : _equipmentCol(item.companyId).doc(item.id);
    await doc.set(item.toMap());
  }

  Future<void> deleteEquipmentItem(String companyId, String itemId) async {
    await _equipmentCol(companyId).doc(itemId).delete();
  }

  // -------------------------------------------------------------
  // FOOD / CANTEEN SUBCOLLECTION: companies/{companyId}/foodCanteen
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _foodCol(String companyId) =>
      _companiesCol.doc(companyId).collection('foodCanteen');

  Stream<List<StockItem>> watchFoodCanteen(String companyId) {
    return _foodCol(companyId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StockItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> saveFoodItem(StockItem item) async {
    final doc = item.id.isEmpty
        ? _foodCol(item.companyId).doc()
        : _foodCol(item.companyId).doc(item.id);
    await doc.set(item.toMap());
  }

  Future<void> decrementFoodStock(
    String companyId,
    String itemId,
    int quantity,
  ) async {
    final doc = _foodCol(companyId).doc(itemId);
    final snapshot = await doc.get();
    if (!snapshot.exists || snapshot.data() == null) return;
    final currentStock = (snapshot.data()!['stock'] as num?)?.toInt() ?? 0;
    final updated = (currentStock - quantity).clamp(0, 999999);
    await doc.update({'stock': updated});
  }

  Future<void> deleteFoodItem(String companyId, String itemId) async {
    await _foodCol(companyId).doc(itemId).delete();
  }

  // -------------------------------------------------------------
  // TABLES HISTORY SUBCOLLECTION: companies/{companyId}/tablesHistory
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _historyCol(String companyId) =>
      _companiesCol.doc(companyId).collection('tablesHistory');

  Stream<List<TableHistoryRecord>> watchTablesHistory(String companyId) {
    return _historyCol(companyId)
        .orderBy('closedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TableHistoryRecord.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<TableHistoryRecord>> getTablesHistory(String companyId) async {
    final snapshot = await _historyCol(companyId)
        .orderBy('closedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TableHistoryRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateTableHistoryRecord(TableHistoryRecord record) async {
    await _historyCol(record.companyId)
        .doc(record.id)
        .set(record.toMap(), SetOptions(merge: true));
  }
}

