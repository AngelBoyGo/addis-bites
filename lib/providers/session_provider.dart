import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_types.dart';
import '../core/session_storage.dart';
import '../models/session.dart';
import 'api_client_provider.dart';

/// Current authenticated [Session], or null when signed out. Persisted to secure
/// storage; on 401/403 the app flushes the session and redirects to /join.
final sessionProvider =
    StateNotifierProvider<SessionNotifier, Session?>((ref) => SessionNotifier(ref));

class SessionNotifier extends StateNotifier<Session?> {
  SessionNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<void> restore() async {
    final s = await SessionStorage.load();
    if (s != null && s.token.isNotEmpty) state = s;
  }

  Future<Session> join({
    required String phone,
    required String name,
    required String role,
  }) async {
    final api = _ref.read(apiClientProvider);
    final session = await api.join(phone: phone, name: name, role: role);
    state = session;
    await SessionStorage.save(session);
    return session;
  }

  Future<OtpRequestResult> otpRequest({required String phone, String channel = 'sms'}) =>
      _ref.read(apiClientProvider).otpRequest(phone: phone, channel: channel);

  Future<void> otpVerify({required String phone, required String code, required String role}) async {
    final api = _ref.read(apiClientProvider);
    final ok = await api.otpVerify(phone: phone, code: code);
    // Reuse the profile from join() once verified, if not already joined.
    if (state == null) {
      final session = await api.join(phone: ok, name: phone, role: role);
      state = session;
      await SessionStorage.save(session);
    }
  }

  Future<void> tgAuth(String initData) async {
    final api = _ref.read(apiClientProvider);
    final session = await api.tgAuth(initData: initData);
    state = session;
    await SessionStorage.save(session);
  }

  Future<void> signOut() async {
    state = null;
    await SessionStorage.clear();
  }

  /// Called when a request 401/403s — flushes session and redirects to /join.
  void forceExpire() {
    state = null;
    SessionStorage.clear();
  }
}