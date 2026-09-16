import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  final String companyId;
  final String userId;
  final DateTime expiresAt;

  const SessionData({
    required this.companyId,
    required this.userId,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'userId': userId,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory SessionData.fromMap(Map<String, dynamic> map) {
    return SessionData(
      companyId: map['companyId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      expiresAt: DateTime.tryParse(map['expiresAt'] as String? ?? '') ??
          DateTime.now().subtract(const Duration(seconds: 1)),
    );
  }
}

class SessionLocalStorage {
  static const String _sessionKey = 'snooker_club_user_session';

  Future<void> saveSession({
    required String companyId,
    required String userId,
    required DateTime expiresAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = SessionData(
        companyId: companyId,
        userId: userId,
        expiresAt: expiresAt,
      );
      final jsonStr = jsonEncode(data.toMap());
      await prefs.setString(_sessionKey, jsonStr);
      debugPrint('[SessionLocalStorage] Session SAVED successfully: $jsonStr');
    } catch (e) {
      debugPrint('[SessionLocalStorage] Error saving session: $e');
    }
  }

  Future<SessionData?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(_sessionKey);
      if (contents == null || contents.trim().isEmpty) {
        debugPrint('[SessionLocalStorage] No active session found.');
        return null;
      }
      final Map<String, dynamic> map = jsonDecode(contents);
      final session = SessionData.fromMap(map);
      debugPrint(
        '[SessionLocalStorage] Found session: companyId=${session.companyId}, userId=${session.userId}, expiresAt=${session.expiresAt}, isExpired=${session.isExpired}',
      );
      return session;
    } catch (e) {
      debugPrint('[SessionLocalStorage] Error reading session: $e');
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      debugPrint('[SessionLocalStorage] Session CLEARED.');
    } catch (e) {
      debugPrint('[SessionLocalStorage] Error clearing session: $e');
    }
  }
}
