import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Tracks and buffers Firestore reads, writes, and deletes in-memory per company.
/// Flushes aggregated delta counts to `companies/{companyId}/dailyUsage/{yyyy-MM-dd}`
/// every 5 minutes (or on app pause/close) using atomic `FieldValue.increment`.
///
/// This avoids the "observer effect" where tracking individual operations directly
/// would burn through Firebase write quotas.
class CompanyUsageTracker with WidgetsBindingObserver {
  final FirebaseFirestore _firestore;
  final String companyId;

  int _pendingReads = 0;
  int _pendingWrites = 0;
  int _pendingDeletes = 0;
  Timer? _flushTimer;
  bool _isDisposed = false;

  CompanyUsageTracker(this._firestore, this.companyId) {
    WidgetsBinding.instance.addObserver(this);
    // Periodic 5-minute flush interval
    _flushTimer = Timer.periodic(const Duration(minutes: 5), (_) => flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      flush();
    }
  }

  void recordReads(int count) {
    if (_isDisposed || count <= 0) return;
    _pendingReads += count;
  }

  void recordWrite([int count = 1]) {
    if (_isDisposed || count <= 0) return;
    _pendingWrites += count;
  }

  void recordDelete([int count = 1]) {
    if (_isDisposed || count <= 0) return;
    _pendingDeletes += count;
  }

  bool _isFlushing = false;

  Future<void> flush() async {
    if (_pendingReads == 0 && _pendingWrites == 0 && _pendingDeletes == 0) {
      return;
    }
    if (_isFlushing) return;
    _isFlushing = true;

    final reads = _pendingReads;
    final writes = _pendingWrites;
    final deletes = _pendingDeletes;

    // Reset buffer immediately so incoming operations accumulate for the next flush cycle
    _pendingReads = 0;
    _pendingWrites = 0;
    _pendingDeletes = 0;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('dailyUsage')
        .doc(todayStr);

    try {
      await docRef.set({
        'date': todayStr,
        'reads': FieldValue.increment(reads),
        'writes': FieldValue.increment(writes),
        'deletes': FieldValue.increment(deletes),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // If network fails, re-add back to buffer to retry next cycle
      if (!_isDisposed) {
        _pendingReads += reads;
        _pendingWrites += writes;
        _pendingDeletes += deletes;
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _flushTimer?.cancel();
    _flushTimer = null;

    // Await any active flush in progress (up to 1s safety limit)
    int waitMs = 0;
    while (_isFlushing && waitMs < 1000) {
      await Future.delayed(const Duration(milliseconds: 50));
      waitMs += 50;
    }

    await flush();
  }
}
