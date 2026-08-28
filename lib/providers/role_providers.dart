import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_types.dart';
import '../models/backend_services.dart';
import '../models/catalog.dart';
import '../models/driver.dart';
import '../models/role_dashboards.dart';
import 'api_client_provider.dart';
import 'catalog_provider.dart';
import 'session_provider.dart';

String? _token(Ref ref) => ref.read(sessionProvider)?.token;

// ---------------- Driver ----------------
final driverDashboardProvider = StateNotifierProvider<DriverNotifier, AsyncValue<DriverDashboard>>(
  (ref) => DriverNotifier(ref),
);

class DriverNotifier extends StateNotifier<AsyncValue<DriverDashboard>> {
  DriverNotifier(this._ref) : super(const AsyncValue.loading());
  final Ref _ref;

  Future<void> load() async {
    final t = _token(_ref);
    if (t == null) return;
    try {
      state = AsyncValue.data(await _ref.read(apiClientProvider).driverDashboard(t));
    } catch (e, st) {
      // �13: 401/403 ? flush session so the router redirects to /join.
      if (isUnauthenticated(e)) _ref.read(sessionProvider.notifier).forceExpire();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> accept(String orderId) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).driverAccept(t, orderId);
    await load();
  }

  Future<void> submitPOD(ProofOfDelivery pod) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).submitPOD(t, pod);
    await load();
  }
}

// ---------------- Merchant ----------------
final merchantQueueProvider = StateNotifierProvider<MerchantNotifier, AsyncValue<List<MerchantOrder>>>(
  (ref) => MerchantNotifier(ref),
);

class MerchantNotifier extends StateNotifier<AsyncValue<List<MerchantOrder>>> {
  MerchantNotifier(this._ref) : super(const AsyncValue.loading());
  final Ref _ref;

  Future<void> load() async {
    final t = _token(_ref);
    if (t == null) return;
    try {
      state = AsyncValue.data(await _ref.read(apiClientProvider).merchantQueue(t));
    } catch (e, st) {
      // �13: 401/403 ? flush session so the router redirects to /join.
      if (isUnauthenticated(e)) _ref.read(sessionProvider.notifier).forceExpire();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> action(String orderId, String action) async {
    final t = _token(_ref);
    if (t == null) return;
    try {
      await _ref.read(apiClientProvider).merchantAction(t, orderId, action);
      _offlineActions.removeWhere((a) => a.$1 == orderId && a.$2 == action);
    } catch (_) {
      // §5.10 offline-first: queue the action locally; flush on reconnect.
      _offlineActions.add((orderId, action));
    }
    await load();
    await flushPending();
  }

  // Buffered actions applied once connectivity returns (tablet power-cuts).
  final List<(String, String)> _offlineActions = [];

  Future<void> flushPending() async {
    final t = _token(_ref);
    if (t == null || _offlineActions.isEmpty) return;
    final api = _ref.read(apiClientProvider);
    final remaining = <(String, String)>[];
    for (final (orderId, action) in _offlineActions) {
      try {
        await api.merchantAction(t, orderId, action);
      } catch (_) {
        remaining.add((orderId, action));
      }
    }
    _offlineActions
      ..clear()
      ..addAll(remaining);
    if (_offlineActions.isNotEmpty) await load();
  }

  List<(String, String)> get pendingActions => List.unmodifiable(_offlineActions);

  Future<void> toggleMenu(String itemId, bool available) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).toggleMenuAvailability(t, itemId, available);
  }

  Future<void> uploadMenuPhoto(String photoB64) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).uploadMenuPhoto(t, '', photoB64);
  }
}

// ---------------- Admin ----------------
final adminProvider = StateNotifierProvider<AdminNotifier, AsyncValue<AdminSnapshot>>(
  (ref) => AdminNotifier(ref),
);

class AdminNotifier extends StateNotifier<AsyncValue<AdminSnapshot>> {
  AdminNotifier(this._ref) : super(const AsyncValue.loading());
  final Ref _ref;

  Future<void> load() async {
    final t = _token(_ref);
    if (t == null) return;
    try {
      state = AsyncValue.data(await _ref.read(apiClientProvider).adminSnapshot(t));
    } catch (e, st) {
      // �13: 401/403 ? flush session so the router redirects to /join.
      if (isUnauthenticated(e)) _ref.read(sessionProvider.notifier).forceExpire();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveConfig(AppConfig c) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).adminConfig(t, c);
    _ref.read(catalogProvider.notifier).setConfig(c);
    await load();
  }

  Future<void> orderAction(String orderId, String action) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).adminOrderAction(t, orderId, action);
    await load();
  }

  /// §5.11: verify a parsed OCR menu — items go live (server-authoritative).
  Future<void> verifyOcr(String stagingId) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).adminVerifyOcr(t, stagingId);
    await load();
  }

  /// §5.11: approve a merchant application → merchant goes active.
  Future<void> approveApplication(String id) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).approveMerchantApplication(t, id);
    await load();
  }

  /// §5.11: reject a merchant application with a note.
  Future<void> rejectApplication(String id, String note) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).rejectMerchantApplication(t, id, note);
    await load();
  }
}

// ---------------- CEO ----------------
final ceoProvider = StateNotifierProvider<CeoNotifier, AsyncValue<CeoDashboard>>(
  (ref) => CeoNotifier(ref),
);

class CeoNotifier extends StateNotifier<AsyncValue<CeoDashboard>> {
  CeoNotifier(this._ref) : super(const AsyncValue.loading());
  final Ref _ref;

  Future<void> load() async {
    final t = _token(_ref);
    if (t == null) return;
    try {
      state = AsyncValue.data(await _ref.read(apiClientProvider).ceoDashboard(t));
    } catch (e, st) {
      // �13: 401/403 ? flush session so the router redirects to /join.
      if (isUnauthenticated(e)) _ref.read(sessionProvider.notifier).forceExpire();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resolveDispute(String id) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).resolveDispute(t, id);
    await load();
  }

  Future<void> createPromo(String label, int pct, int maxUses) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).createPromo(t, label, pct, maxUses);
    await load();
  }
}

// ---------------- Foot carrier ----------------
final footProvider = StateNotifierProvider<FootNotifier, AsyncValue<FootStatus>>(
  (ref) => FootNotifier(ref),
);

class FootNotifier extends StateNotifier<AsyncValue<FootStatus>> {
  FootNotifier(this._ref) : super(const AsyncValue.loading());
  final Ref _ref;

  Future<void> start(String phone) async {
    try {
      state = AsyncValue.data(await _ref.read(apiClientProvider).footStart(phone));
    } catch (e, st) {
      // �13: 401/403 ? flush session so the router redirects to /join.
      if (isUnauthenticated(e)) _ref.read(sessionProvider.notifier).forceExpire();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> orientation() async {
    final t = _token(_ref);
    if (t == null) return;
    state = AsyncValue.data(await _ref.read(apiClientProvider).footOrientation(t));
  }

  Future<void> earnToday() async {
    final t = _token(_ref);
    if (t == null) return;
    state = AsyncValue.data(await _ref.read(apiClientProvider).footEarnToday(t));
  }
}

// ---------------- Foot earnings (live bonus ledger + trip history) ----------------
final footEarningsProvider = FutureProvider<FootEarnings>((ref) async {
  final t = _token(ref);
  if (t == null) return const FootEarnings(walletBalanceEtb: 0, bonuses: [], trips: []);
  return ref.read(apiClientProvider).footEarnings(t);
});

// ---------------- Support console ----------------
final supportProvider = StateNotifierProvider<SupportNotifier, AsyncValue<SupportDashboard>>(
  (ref) => SupportNotifier(ref),
);

class SupportNotifier extends StateNotifier<AsyncValue<SupportDashboard>> {
  SupportNotifier(this._ref) : super(const AsyncValue.loading());
  final Ref _ref;

  Future<void> load() async {
    final t = _token(_ref);
    if (t == null) return;
    try {
      state = AsyncValue.data(await _ref.read(apiClientProvider).supportDashboard(t));
    } catch (e, st) {
      if (isUnauthenticated(e)) _ref.read(sessionProvider.notifier).forceExpire();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> validateReport(String reportId, bool valid) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).validateReport(t, reportId, valid);
    await load();
  }

  Future<void> approveRefund(String refundId) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).approveRefund(t, refundId);
    await load();
  }
}

// ---------------- Finance console ----------------
final financeProvider = StateNotifierProvider<FinanceNotifier, AsyncValue<FinanceDashboard>>(
  (ref) => FinanceNotifier(ref),
);

class FinanceNotifier extends StateNotifier<AsyncValue<FinanceDashboard>> {
  FinanceNotifier(this._ref) : super(const AsyncValue.loading());
  final Ref _ref;

  Future<void> load() async {
    final t = _token(_ref);
    if (t == null) return;
    try {
      state = AsyncValue.data(await _ref.read(apiClientProvider).financeDashboard(t));
    } catch (e, st) {
      if (isUnauthenticated(e)) _ref.read(sessionProvider.notifier).forceExpire();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> runPayoutBatch(String batchId) async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).runPayoutBatch(t, batchId);
    await load();
  }

  Future<void> reconcile() async {
    final t = _token(_ref);
    if (t == null) return;
    await _ref.read(apiClientProvider).reconcile(t);
    await load();
  }
}
// ---------------- Sefer Rounds ----------------
class RoundsNotifier extends StateNotifier<List<SeferRound>> {
  RoundsNotifier(this._ref) : super(const []);
  final Ref _ref;

  Future<void> load(String hub) async {
    state = await _ref.read(apiClientProvider).roundsForHub(hub);
  }
}

final roundsProvider = StateNotifierProvider<RoundsNotifier, List<SeferRound>>(
  (ref) => RoundsNotifier(ref),
);