import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/app_download_config.dart';
import '../../domain/entities/club_reminder.dart';
import '../../domain/entities/club_table.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/table_billing_item.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/table_history_record.dart';
import '../../domain/entities/table_session.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/entities/company_daily_usage.dart';
import 'company_usage_tracker.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final Map<String, CompanyUsageTracker> _usageTrackers = {};

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CompanyUsageTracker _getOrCreateTracker(String companyId) {
    return _usageTrackers.putIfAbsent(
      companyId,
      () => CompanyUsageTracker(_firestore, companyId),
    );
  }

  void trackRead(String? companyId, [int count = 1]) {
    if (companyId == null || companyId.isEmpty || count <= 0) return;
    _getOrCreateTracker(companyId).recordReads(count);
  }

  void trackWrite(String? companyId, [int count = 1]) {
    if (companyId == null || companyId.isEmpty || count <= 0) return;
    _getOrCreateTracker(companyId).recordWrite(count);
  }

  void trackDelete(String? companyId, [int count = 1]) {
    if (companyId == null || companyId.isEmpty || count <= 0) return;
    _getOrCreateTracker(companyId).recordDelete(count);
  }

  Future<void> flushAllUsage() async {
    for (final tracker in _usageTrackers.values) {
      await tracker.flush();
    }
  }

  Future<void> disposeTracker(String companyId) async {
    final tracker = _usageTrackers.remove(companyId);
    if (tracker != null) {
      await tracker.dispose();
    }
  }

  Future<void> disposeAllTrackers() async {
    for (final tracker in _usageTrackers.values) {
      await tracker.dispose();
    }
    _usageTrackers.clear();
  }

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
      trackRead(companyId, 1);
      return Company.fromMap(doc.id, doc.data()!);
    });
  }

  Future<Company?> getCompanyById(String companyId) async {
    final doc = await _companiesCol.doc(companyId).get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return null;
    return Company.fromMap(doc.id, doc.data()!);
  }

  /// Checks if a unique company code already exists
  Future<bool> isCompanyCodeTaken(String code) async {
    final clean = code.trim().toUpperCase();
    final query =
        await _companiesCol.where('code', isEqualTo: clean).limit(1).get();
    return query.docs.isNotEmpty;
  }

  /// Retrieves a company by its unique code (with doc ID fallback)
  Future<Company?> getCompanyByCode(String code) async {
    final clean = code.trim().toUpperCase();
    final query =
        await _companiesCol.where('code', isEqualTo: clean).limit(1).get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Company.fromMap(doc.id, doc.data());
    }

    // Fallback: check by doc ID for existing companies created prior to unique codes
    try {
      final directDoc = await _companiesCol.doc(code.trim()).get();
      if (directDoc.exists && directDoc.data() != null) {
        return Company.fromMap(directDoc.id, directDoc.data()!);
      }
    } catch (_) {}

    return null;
  }

  Future<Company> ensureCompanyDueBuffer(Company company) async {
    try {
      final doc = await _companiesCol.doc(company.id).get();
      trackRead(company.id, 1);
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (!data.containsKey('dueBufferAmount')) {
          await _companiesCol.doc(company.id).set({
            'dueBufferAmount': Constants.dueBufferAmount,
          }, SetOptions(merge: true));
          trackWrite(company.id, 1);
          return company.copyWith(dueBufferAmount: Constants.dueBufferAmount);
        } else {
          final buffer = (data['dueBufferAmount'] as num?)?.toDouble() ??
              Constants.dueBufferAmount;
          return company.copyWith(dueBufferAmount: buffer);
        }
      }
    } catch (_) {}
    return company;
  }

  /// Updates the company's due buffer threshold in Firestore
  Future<void> updateCompanyDueBufferAmount(
    String companyId,
    double amount,
  ) async {
    await _companiesCol.doc(companyId).set({
      'dueBufferAmount': amount,
    }, SetOptions(merge: true));
    trackWrite(companyId, 1);
  }

  /// Dev-only company creation with initial admin user
  Future<Company> createCompanyWithInitialAdmin({
    required String name,
    required String code,
    required String number,
    required DateTime expiryDate,
    required String initialUserName,
    required String initialUserNumber,
    required String initialUserEmail,
    required String initialUserPassword,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    final isTaken = await isCompanyCodeTaken(cleanCode);
    if (isTaken) {
      throw Exception(
        'Company code "$cleanCode" is already in use. Please enter a different unique code.',
      );
    }

    final companyDoc = _companiesCol.doc();
    final companyId = companyDoc.id;
    final now = DateTime.now();

    final company = Company(
      id: companyId,
      name: name.trim(),
      code: cleanCode,
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
      role: 'owner',
      isAdmin: true, // Always owner & admin by default
      isActive: true,
      createdAt: now,
    );
    batch.set(userDoc, initialAdmin.toMap());

    await batch.commit();
    trackWrite(companyId, 2);
    return company;
  }

  // -------------------------------------------------------------
  // USERS SUBCOLLECTION: companies/{companyId}/users
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _usersCol(String companyId) =>
      _companiesCol.doc(companyId).collection('users');

  Stream<List<UserAccount>> watchCompanyUsers(String companyId) {
    return _usersCol(companyId).snapshots().map((snapshot) {
      trackRead(companyId, snapshot.docs.length);
      return snapshot.docs
          .map((doc) => UserAccount.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<UserAccount>> getCompanyUsers(String companyId) async {
    final snapshot = await _usersCol(companyId).get();
    trackRead(companyId, snapshot.docs.length);
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
    trackWrite(user.companyId, 1);
  }

  Future<void> updateUserAdminStatus(
    String companyId,
    String userId,
    bool isAdmin,
  ) async {
    await _usersCol(companyId).doc(userId).set({
      'isAdmin': isAdmin,
      'role': isAdmin ? 'owner' : 'employee',
    }, SetOptions(merge: true));
    trackWrite(companyId, 1);
  }

  Future<void> updateUserActiveStatus(
    String companyId,
    String userId,
    bool isActive,
  ) async {
    final updates = <String, dynamic>{
      'isActive': isActive,
      'isDeactivated': !isActive,
    };
    if (!isActive) {
      updates['sessionExpiresAt'] = null;
      updates['isOnline'] = false;
    }
    await _usersCol(companyId).doc(userId).set(
      updates,
      SetOptions(merge: true),
    );
    trackWrite(companyId, 1);
  }

  Future<void> updateUserRole(
    String companyId,
    String userId,
    String role,
  ) async {
    final isOwnerRole = role.toLowerCase() == 'owner';
    await _usersCol(companyId).doc(userId).set({
      'role': role.toLowerCase(),
      'isAdmin': isOwnerRole,
    }, SetOptions(merge: true));
    trackWrite(companyId, 1);
  }

  Future<void> updateUserPassword(
    String companyId,
    String userId,
    String newPassword,
  ) async {
    await _usersCol(companyId).doc(userId).set({
      'password': newPassword.trim(),
    }, SetOptions(merge: true));
    trackWrite(companyId, 1);
  }

  Future<void> updateCompanyExpiryDate(
    String companyId,
    DateTime newExpiryDate,
  ) async {
    await _companiesCol.doc(companyId).set({
      'expiryDate': Timestamp.fromDate(newExpiryDate),
    }, SetOptions(merge: true));
    trackWrite(companyId, 1);
  }

  Future<void> updateCompanyBasicInfo(
    String companyId, {
    String? name,
    String? number,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (number != null) updates['number'] = number.trim();
    if (updates.isNotEmpty) {
      await _companiesCol.doc(companyId).set(updates, SetOptions(merge: true));
      trackWrite(companyId, 1);
    }
  }

  Future<UserAccount?> getUserById(String companyId, String userId) async {
    try {
      final doc = await _usersCol(companyId).doc(userId).get();
      trackRead(companyId, 1);
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
    trackWrite(companyId, 1);
  }

  Future<({bool success, String? conflictingUserName})> setUserOnlineStatus({
    required String companyId,
    required String userId,
    required bool isOnline,
  }) async {
    final usersCol = _usersCol(companyId);

    if (isOnline) {
      // Concurrency rule: Check if any other user is currently online
      final allUsersSnap = await usersCol.get();
      for (final doc in allUsersSnap.docs) {
        if (doc.id != userId) {
          final data = doc.data();
          if (data['isOnline'] == true) {
            final name = (data['name'] as String?)?.trim();
            return (
              success: false,
              conflictingUserName:
                  (name != null && name.isNotEmpty) ? name : 'Another operator',
            );
          }
        }
      }
    }

    final userDoc = await usersCol.doc(userId).get();
    final existingData = userDoc.data() ?? {};
    final rawShifts = List<Map<String, dynamic>>.from(
      (existingData['shifts'] as List<dynamic>?)?.map(
            (e) => Map<String, dynamic>.from(e as Map),
          ) ??
          [],
    );

    final now = Timestamp.now();

    if (isOnline) {
      // Close any previously open shift if found
      for (final shift in rawShifts) {
        if (shift['offlineAt'] == null) {
          shift['offlineAt'] = now;
        }
      }
      // Append new active shift
      rawShifts.add({
        'id': const Uuid().v4(),
        'onlineAt': now,
        'offlineAt': null,
      });
    } else {
      // Close active shift
      for (final shift in rawShifts) {
        if (shift['offlineAt'] == null) {
          shift['offlineAt'] = now;
        }
      }
    }

    await usersCol.doc(userId).set({
      'isOnline': isOnline,
      'shifts': rawShifts,
    }, SetOptions(merge: true));
    trackWrite(companyId, 1);

    return (success: true, conflictingUserName: null);
  }

  // -------------------------------------------------------------
  // SNOOKER TABLES SUBCOLLECTION: companies/{companyId}/snookerTables
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _tablesCol(String companyId) =>
      _companiesCol.doc(companyId).collection('snookerTables');

  Stream<List<ClubTable>> watchTables(String companyId) {
    return _tablesCol(companyId).snapshots().map((snapshot) {
      trackRead(companyId, snapshot.docs.length);
      return snapshot.docs
          .map((doc) => ClubTable.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<ClubTable>> getTables(String companyId) async {
    final snapshot = await _tablesCol(companyId).get();
    trackRead(companyId, snapshot.docs.length);
    return snapshot.docs
        .map((doc) => ClubTable.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<ClubTable?> getTableById(String companyId, String tableId) async {
    final doc = await _tablesCol(companyId).doc(tableId).get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return null;
    return ClubTable.fromMap(doc.id, doc.data()!);
  }

  Future<void> saveTable(ClubTable table) async {
    final doc = table.id.isEmpty
        ? _tablesCol(table.companyId).doc()
        : _tablesCol(table.companyId).doc(table.id);
    await doc.set(table.toMap());
    trackWrite(table.companyId, 1);
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
    trackWrite(companyId, 1);
  }

  Future<void> deleteTable(String companyId, String tableId) async {
    await _tablesCol(companyId).doc(tableId).delete();
    trackDelete(companyId, 1);
  }

  // -------------------------------------------------------------
  // RUNNING TABLES SUBCOLLECTION: companies/{companyId}/runningTables
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _runningCol(String companyId) =>
      _companiesCol.doc(companyId).collection('runningTables');

  Stream<List<TableSession>> watchRunningTables(String companyId) {
    return _runningCol(companyId).snapshots().map((snapshot) {
      trackRead(companyId, snapshot.docs.length);
      return snapshot.docs
          .map((doc) => TableSession.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<TableSession?> getRunningSession(String companyId, String sessionId) async {
    final doc = await _runningCol(companyId).doc(sessionId).get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return null;
    return TableSession.fromMap(doc.id, doc.data()!);
  }

  Future<void> startSession(TableSession session) async {
    final batch = _firestore.batch();
    final runningDoc = _runningCol(session.companyId).doc(session.id);
    final playedSec = session.playedSecondsAt(session.startTime);
    final tableFee = session.computeTableChargeAt(session.startTime);
    final grandTotal = session.computeGrandTotalAt(session.startTime);
    final sessionMap = session.copyWith(
      lastPlayedSeconds: playedSec,
      lastTableCharge: tableFee,
      lastGrandTotal: grandTotal,
    ).toMap();
    sessionMap['lastUpdated'] = Timestamp.now();

    batch.set(runningDoc, sessionMap);

    final tableDoc = _tablesCol(session.companyId).doc(session.tableId);
    batch.update(tableDoc, {
      'status': TableStatus.occupied.displayName,
      'currentSessionId': session.id,
    });

    await batch.commit();
    trackWrite(session.companyId, 2);
  }

  Future<void> updateRunningSession(TableSession session) async {
    final now = DateTime.now();
    final sessionMap = session.copyWith(
      lastPlayedSeconds: session.playedSecondsAt(now),
      lastTableCharge: session.computeTableChargeAt(now),
      lastGrandTotal: session.computeGrandTotalAt(now),
    ).toMap();
    sessionMap['lastUpdated'] = Timestamp.now();
    await _runningCol(session.companyId).doc(session.id).set(sessionMap);
    trackWrite(session.companyId, 1);
  }

  Future<void> pauseSession(String companyId, String sessionId) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    final doc = await sessionDoc.get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return;
    final session = TableSession.fromMap(doc.id, doc.data()!);
    // Prevent overwriting lastPauseTime if already paused
    if (session.isPaused) return;

    final now = DateTime.now();
    final playedSeconds = session.playedSecondsAt(now);
    final tableCharge = session.computeTableChargeAt(now);
    final grandTotal = session.computeGrandTotalAt(now);

    await sessionDoc.update({
      'isPaused': true,
      'lastPauseTime': Timestamp.fromDate(now),
      'lastPlayedSeconds': playedSeconds,
      'lastTableCharge': tableCharge,
      'lastGrandTotal': grandTotal,
      'lastUpdated': Timestamp.fromDate(now),
    });
    trackWrite(companyId, 1);
  }

  Future<void> resumeSession(String companyId, String sessionId) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    final doc = await sessionDoc.get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return;
    final session = TableSession.fromMap(doc.id, doc.data()!);
    if (!session.isPaused || session.lastPauseTime == null) return;

    final now = DateTime.now();
    // Guard against device clock skew between pausing device and resuming device
    final additionalPause =
        now.difference(session.lastPauseTime!).inSeconds.clamp(0, 86400 * 30);
    final totalPaused = session.pausedSeconds + additionalPause;

    // Calculate played seconds up to the pause point
    final playedSeconds = session.playedSecondsAt(session.lastPauseTime!);
    final tableCharge = session.computeTableChargeAt(session.lastPauseTime!);
    final grandTotal = session.computeGrandTotalAt(session.lastPauseTime!);

    await sessionDoc.update({
      'isPaused': false,
      'lastPauseTime': null,
      'pausedSeconds': totalPaused,
      'lastPlayedSeconds': playedSeconds,
      'lastTableCharge': tableCharge,
      'lastGrandTotal': grandTotal,
      'lastUpdated': Timestamp.fromDate(now),
    });
    trackWrite(companyId, 1);
  }

  Future<void> addItemToRunningSession(
    String companyId,
    String sessionId,
    TableBillingItem item,
  ) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    final doc = await sessionDoc.get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return;
    final session = TableSession.fromMap(doc.id, doc.data()!);
    final updatedItems = List<TableBillingItem>.from(session.items)..add(item);
    final updatedSession = session.copyWith(items: updatedItems);
    final now = DateTime.now();

    await sessionDoc.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'lastGrandTotal': updatedSession.computeGrandTotalAt(now),
      'lastUpdated': Timestamp.fromDate(now),
    });
    trackWrite(companyId, 1);
  }

  Future<void> updateBillingItemInRunningSession(
    String companyId,
    String sessionId,
    TableBillingItem updatedItem,
  ) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    final doc = await sessionDoc.get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return;
    final session = TableSession.fromMap(doc.id, doc.data()!);
    final updatedItems = session.items
        .map((i) => i.id == updatedItem.id ? updatedItem : i)
        .toList();
    final updatedSession = session.copyWith(items: updatedItems);
    final now = DateTime.now();

    await sessionDoc.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'lastGrandTotal': updatedSession.computeGrandTotalAt(now),
      'lastUpdated': Timestamp.fromDate(now),
    });
    trackWrite(companyId, 1);
  }

  Future<void> removeBillingItemFromRunningSession(
    String companyId,
    String sessionId,
    String itemId,
  ) async {
    final sessionDoc = _runningCol(companyId).doc(sessionId);
    final doc = await sessionDoc.get();
    trackRead(companyId, 1);
    if (!doc.exists || doc.data() == null) return;
    final session = TableSession.fromMap(doc.id, doc.data()!);
    final updatedItems = session.items.where((i) => i.id != itemId).toList();
    final updatedSession = session.copyWith(items: updatedItems);
    final now = DateTime.now();

    await sessionDoc.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'lastGrandTotal': updatedSession.computeGrandTotalAt(now),
      'lastUpdated': Timestamp.fromDate(now),
    });
    trackWrite(companyId, 1);
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
    trackWrite(companyId, 2);
    trackDelete(companyId, 1);
  }

  // -------------------------------------------------------------
  // EQUIPMENT / STOCK SUBCOLLECTION: companies/{companyId}/equipmentStock
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _equipmentCol(String companyId) =>
      _companiesCol.doc(companyId).collection('equipmentStock');

  Stream<List<StockItem>> watchEquipmentStock(String companyId) {
    return _equipmentCol(companyId).snapshots().map((snapshot) {
      trackRead(companyId, snapshot.docs.length);
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
    trackWrite(item.companyId, 1);
  }

  Future<void> deleteEquipmentItem(String companyId, String itemId) async {
    await _equipmentCol(companyId).doc(itemId).delete();
    trackDelete(companyId, 1);
  }

  // -------------------------------------------------------------
  // FOOD / CANTEEN SUBCOLLECTION: companies/{companyId}/foodCanteen
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _foodCol(String companyId) =>
      _companiesCol.doc(companyId).collection('foodCanteen');

  Stream<List<StockItem>> watchFoodCanteen(String companyId) {
    return _foodCol(companyId).snapshots().map((snapshot) {
      trackRead(companyId, snapshot.docs.length);
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
    trackWrite(item.companyId, 1);
  }

  Future<void> decrementFoodStock(
    String companyId,
    String itemId,
    int quantity,
  ) async {
    final doc = _foodCol(companyId).doc(itemId);
    final snapshot = await doc.get();
    trackRead(companyId, 1);
    if (!snapshot.exists || snapshot.data() == null) return;
    final currentStock = (snapshot.data()!['stock'] as num?)?.toInt() ?? 0;
    final updated = (currentStock - quantity).clamp(0, 999999);
    await doc.update({'stock': updated});
    trackWrite(companyId, 1);
  }

  Future<void> incrementFoodStock(
    String companyId,
    String itemId,
    int quantity,
  ) async {
    final doc = _foodCol(companyId).doc(itemId);
    final snapshot = await doc.get();
    trackRead(companyId, 1);
    if (!snapshot.exists || snapshot.data() == null) return;
    final currentStock = (snapshot.data()!['stock'] as num?)?.toInt() ?? 0;
    final updated = (currentStock + quantity).clamp(0, 999999);
    await doc.update({'stock': updated});
    trackWrite(companyId, 1);
  }

  Future<void> deleteFoodItem(String companyId, String itemId) async {
    await _foodCol(companyId).doc(itemId).delete();
    trackDelete(companyId, 1);
  }

  // -------------------------------------------------------------
  // TABLES HISTORY SUBCOLLECTION: companies/{companyId}/tablesHistory
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _historyCol(String companyId) =>
      _companiesCol.doc(companyId).collection('tablesHistory');

  Stream<List<TableHistoryRecord>> watchTablesHistory(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _historyCol(companyId);
    if (startDate != null) {
      query = query.where(
        'closedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'closedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }
    return query
        .orderBy('closedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      trackRead(companyId, snapshot.docs.length);
      return snapshot.docs
          .map((doc) => TableHistoryRecord.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<TableHistoryRecord>> getTablesHistory(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _historyCol(companyId);
    if (startDate != null) {
      query = query.where(
        'closedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'closedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }
    final snapshot = await query.orderBy('closedAt', descending: true).get();
    trackRead(companyId, snapshot.docs.length);
    return snapshot.docs
        .map((doc) => TableHistoryRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateTableHistoryRecord(TableHistoryRecord record) async {
    await _historyCol(record.companyId)
        .doc(record.id)
        .set(record.toMap(), SetOptions(merge: true));
    trackWrite(record.companyId, 1);
  }

  // -------------------------------------------------------------
  // REMINDERS SUBCOLLECTION: companies/{companyId}/reminders
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _remindersCol(String companyId) =>
      _companiesCol.doc(companyId).collection('reminders');

  Stream<List<ClubReminder>> watchCompanyReminders(String companyId) {
    return _remindersCol(companyId)
        .orderBy('remindAt', descending: false)
        .snapshots()
        .map((snapshot) {
      trackRead(companyId, snapshot.docs.length);
      return snapshot.docs
          .map((doc) => ClubReminder.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> saveReminder(String companyId, ClubReminder reminder) async {
    final docId = reminder.id.isEmpty
        ? _remindersCol(companyId).doc().id
        : reminder.id;
    final toSave = reminder.copyWith(id: docId, companyId: companyId);
    await _remindersCol(companyId)
        .doc(docId)
        .set(toSave.toMap(), SetOptions(merge: true));
    trackWrite(companyId, 1);
  }

  Future<void> dismissReminder(String companyId, String reminderId) async {
    await _remindersCol(companyId)
        .doc(reminderId)
        .set({'isDismissed': true}, SetOptions(merge: true));
    trackWrite(companyId, 1);
  }

  Future<void> deleteReminder(String companyId, String reminderId) async {
    await _remindersCol(companyId).doc(reminderId).delete();
    trackDelete(companyId, 1);
  }

  // -------------------------------------------------------------
  // APP CONFIG / DOWNLOAD URL (Separate top-level collection: appConfig)
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _appConfigCol =>
      _firestore.collection('appConfig');

  /// Stream real-time app download configuration (Google Drive / APK link)
  Stream<AppDownloadConfig> watchAppDownloadConfig() {
    return _appConfigCol.doc('appDownload').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return const AppDownloadConfig(downloadUrl: '');
      }
      return AppDownloadConfig.fromMap(doc.data()!);
    });
  }

  /// Get the current app download configuration one-time
  Future<AppDownloadConfig> getAppDownloadConfig() async {
    try {
      final doc = await _appConfigCol.doc('appDownload').get();
      if (!doc.exists || doc.data() == null) {
        return const AppDownloadConfig(downloadUrl: '');
      }
      return AppDownloadConfig.fromMap(doc.data()!);
    } catch (_) {
      return const AppDownloadConfig(downloadUrl: '');
    }
  }

  /// Updates or uploads the app download URL, minimum required version, and metadata
  Future<void> updateAppDownloadUrl({
    required String downloadUrl,
    String? minVersion,
    String? updatedBy,
    String? notes,
  }) async {
    await _appConfigCol.doc('appDownload').set({
      'downloadUrl': downloadUrl.trim(),
      if (minVersion != null) 'minVersion': minVersion.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null && updatedBy.trim().isNotEmpty)
        'updatedBy': updatedBy.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    }, SetOptions(merge: true));
  }

  // -------------------------------------------------------------
  // USAGE MONITORING SUBCOLLECTION: companies/{companyId}/dailyUsage
  // -------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _usageCol(String companyId) =>
      _companiesCol.doc(companyId).collection('dailyUsage');

  Stream<CompanyDailyUsage?> watchTodayUsage(String companyId) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _usageCol(companyId).doc(todayStr).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CompanyDailyUsage.fromMap(doc.id, doc.data()!);
    });
  }

  Future<CompanyDailyUsage?> getTodayUsage(String companyId) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final doc = await _usageCol(companyId).doc(todayStr).get();
    if (!doc.exists || doc.data() == null) return null;
    return CompanyDailyUsage.fromMap(doc.id, doc.data()!);
  }

  Stream<List<CompanyDailyUsage>> watchUsageHistory(
    String companyId, {
    int limit = 30,
  }) {
    return _usageCol(companyId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CompanyDailyUsage.fromMap(doc.id, doc.data()))
            .toList());
  }
}

