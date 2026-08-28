import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

/// Persists the session token + profile.
///
/// The token itself goes to platform secure storage (Keychain/Keystore); the
/// language preference and cached data go to shared_preferences. No secrets in
/// source; token never logged.
class SessionStorage {
  SessionStorage._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'session_token';
  static const _profileKey = 'session_profile';

  static Future<void> save(Session session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(
      key: _profileKey,
      value: jsonEncode({
        'id': session.profile.id,
        'phone': session.profile.phone,
        'name': session.profile.name,
        'role': session.profile.role.name,
        if (session.profile.vehicle != null) 'vehicle': session.profile.vehicle,
      }),
    );
  }

  static Future<Session?> load() async {
    final token = await _storage.read(key: _tokenKey);
    final profileRaw = await _storage.read(key: _profileKey);
    if (token == null || profileRaw == null) return null;
    try {
      final p = jsonDecode(profileRaw) as Map<String, dynamic>;
      return Session(
        token: token,
        profile: Profile.fromJson(p),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _profileKey);
  }

  // ---- language preference ----
  static Future<String> locale() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('locale') ?? 'en';
  }

  static Future<void> setLocale(String l) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('locale', l);
  }

  // ---- verified payment receipt cache (offline-persisted, §10 "Verified
  // payment receipt … offline-persisted" / §14) ----
  static Future<void> saveVerifiedReceipt(String orderId, String ref, int totalEtb) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonDecode(sp.getString('verified_receipts') ?? '{}') as Map<String, dynamic>;
    final all = Map<String, dynamic>.from(raw);
    all[orderId] = {'ref': ref, 'total': totalEtb, 'savedAt': DateTime.now().toIso8601String()};
    await sp.setString('verified_receipts', jsonEncode(all));
  }

  /// Returns the persisted verified receipt for [orderId], or null.
  /// This lets the high-contrast payment receipt display fully offline.
  static Future<Map<String, dynamic>?> verifiedReceipt(String orderId) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonDecode(sp.getString('verified_receipts') ?? '{}') as Map<String, dynamic>;
    final all = Map<String, dynamic>.from(raw);
    final entry = all[orderId];
    return entry is Map<String, dynamic> ? entry : null;
  }
}