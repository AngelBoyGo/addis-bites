import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/api_types.dart';
import '../models/catalog.dart';
import '../models/catalog_response.dart';
import 'api_client_provider.dart';
import 'session_provider.dart';

/// Holds the resolved catalog with a 3-minute TTL and pull-to-refresh, plus a
/// disk cache so menus are browsable offline after first load (§3).
final catalogProvider =
    StateNotifierProvider<CatalogNotifier, AsyncValue<CatalogResponse>>((ref) => CatalogNotifier(ref));

class CatalogNotifier extends StateNotifier<AsyncValue<CatalogResponse>> {
  CatalogNotifier(this._ref) : super(const AsyncValue.loading()) {
    _hydrate();
  }

  final Ref _ref;
  DateTime? _lastFetch;

  Future<void> _hydrate() async {
    // Offline-first: try disk cache first, then network.
    final cached = await CatalogCache.read();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }
    if (_stale()) {
      await load();
    } else if (cached == null) {
      await load();
    }
  }

  bool _stale() => _lastFetch == null || DateTime.now().difference(_lastFetch!) > const Duration(minutes: 3);

  /// Pull-to-refresh entry point.
  Future<void> refresh() => load(force: true);

  Future<void> load({bool force = false}) async {
    if (!force && !_stale()) return;
    try {
      final api = _ref.read(apiClientProvider);
      final data = await api.fetchCatalog(token: _ref.read(sessionProvider)?.token);
      _lastFetch = DateTime.now();
      state = AsyncValue.data(data);
      await CatalogCache.write(data);
    } catch (e, st) {
      // §13: 401/403 → flush session so the router redirects to /join.
      if (isUnauthenticated(e)) {
        _ref.read(sessionProvider.notifier).forceExpire();
        return;
      }
      if (state.valueOrNull != null) return; // keep cached on network failure
      state = AsyncValue.error(e, st);
    }
  }

  void setConfig(AppConfig newConfig) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(CatalogResponse(
      merchants: cur.merchants,
      items: cur.items,
      config: newConfig,
      fasting: cur.fasting,
      subCities: cur.subCities,
    ));
    CatalogCache.write(state.value!);
  }
}

extension CatalogRead on Ref {
  CatalogResponse? catalogNow() => read(catalogProvider).valueOrNull;
  List<dynamic> merchantsRaw() => catalogNow()?.merchants ?? const [];
  AppConfig config() =>
      catalogNow()?.config ??
      const AppConfig(
        serviceFee: 20, deliveryFee2km: 80, deliveryFee5km: 150, deliveryFee8km: 240,
        footFee: 45, rainSurge: 40, bunaRunFee: 50, bunaMaxOrder: 150, bunaMaxKm: 1,
        courierSharePct: 80, courierTipsPct: 100, codFloatCap: 1500,
        codSettlementHours: 24, commissionPct: 12, restaurantOfTheDayCommissionPct: 0,
        ackTimeoutSeconds: 90, smsProvider: 'afromessage', smsCostEtb: 0.45,
        rainMode: false, fastingOverride: false, vehicleCurfew: false,
        restaurantOfTheDayId: '', inflationPct: 22, feeMultiplier: 1, demoMode: false,
      );
}

/// Hive-backed disk cache for the catalog (offline-first, §3).
/// Menus are fully browsable offline after the first successful load.
class CatalogCache {
  CatalogCache._();

  static CatalogResponse? _mem;
  static Box<String>? _box;
  static bool _initAttempted = false;
  static const _key = 'catalog';

  static Future<Box<String>> _ensure() async {
    if (_box != null) return _box!;
    if (!_initAttempted) {
      _initAttempted = true;
      try {
        await Hive.initFlutter();
        // Directory.homePath fallback for non-flutter contexts is unnecessary here.
        _box = await Hive.openBox<String>('addis_bites_cache');
      } catch (_) {
        _box = null; // fall back to memory if Hive unavailable
      }
    }
    return _box!;
  }

  static Future<CatalogResponse?> read() async {
    if (_mem != null) return _mem;
    try {
      final box = await _ensure();
      final raw = box.get(_key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final catalog = CatalogResponse.fromJson(decoded);
      _mem = catalog;
      return catalog;
    } catch (_) {
      return _mem;
    }
  }

  static Future<void> write(CatalogResponse c) async {
    _mem = c;
    try {
      final box = await _ensure();
      await box.put(_key, jsonEncode(c.toJson()));
    } catch (_) {
      // memory-only if disk unavailable (tests, pre-init)
    }
  }
}