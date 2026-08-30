import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_types.dart';
import '../models/order.dart';
import '../providers/api_client_provider.dart';
import '../providers/session_provider.dart';

/// Active order history + tracking + offline submission retry queue.
/// - Poll /api/order/:id every 3-5s only while a tracking screen is foreground.
/// - Order submission queues with retry (2 automatic attempts then manual Retry).
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>(
  (ref) => OrdersNotifier(ref),
);

/// Reactive count of offline-queued order submissions. Updated whenever the
/// queue mutates so the orders screen banner rebuilds without stale reads.
final ordersPendingProvider = StateNotifierProvider<OrdersPendingNotifier, int>(
  (ref) => OrdersPendingNotifier(),
);

class OrdersPendingNotifier extends StateNotifier<int> {
  OrdersPendingNotifier() : super(0);
  void setCount(int n) => state = n;
}

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier(this._ref) : super(const []) {
    _restoreQueue();
  }

  final Ref _ref;
  Timer? _pollTimer;
  String? _pollingOrderId;

  void upsert(Order order) {
    final i = state.indexWhere((o) => o.id == order.id);
    final next = [...state];
    if (i >= 0) {
      next[i] = order;
    } else {
      next.insert(0, order);
    }
    state = next;
  }

  Order? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }

  // ---- polling (3-5s, foreground only) ----
  void pollOrder(String orderId) {
    if (_pollingOrderId == orderId && _pollTimer != null) return;
    _pollingOrderId = orderId;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollOnce(orderId));
  }

  Future<void> _pollOnce(String orderId) async {
    final api = _ref.read(apiClientProvider);
    final token = _ref.read(sessionProvider)?.token;
    if (token == null) return;
    try {
      final fresh = await api.fetchOrder(orderId, token);
      upsert(fresh);
    } catch (e) {
      // §13: 401/403 → flush session so the router redirects to /join.
      if (isUnauthenticated(e)) {
        _ref.read(sessionProvider.notifier).forceExpire();
      }
      // keep last known state on network failure
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingOrderId = null;
  }

  void removeOrder(String id) {
    state = state.where((o) => o.id != id).toList();
  }

  // ---- offline retry queue ----
  final List<PendingOrder> _queue = [];

  void enqueue(PendingOrder pending) {
    _queue.add(pending);
    _syncPending();
    _drain();
  }

  void _syncPending() {
    _ref.read(ordersPendingProvider.notifier).setCount(_queue.length);
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final p = _queue.first;
      if (p.attempts >= 2) break; // 2 automatic attempts, then manual Retry
      p.attempts++;
      try {
        final api = _ref.read(apiClientProvider);
        final order = await api.placeOrder(
          token: p.token,
          phone: p.phone,
          merchantId: p.merchantId,
          items: p.items,
          subCity: p.subCity,
          sefer: p.sefer,
          landmarkText: p.landmarkText,
          lat: p.lat,
          lng: p.lng,
          paymentMethod: p.paymentMethod,
        );
        _queue.removeAt(0);
        upsert(order);
        _syncPending();
        _persistQueue();
        return;
      } catch (_) {
        if (p.attempts >= 2) {
          _persistQueue();
          return; // leave for manual Retry
        }
      }
    }
  }

  List<PendingOrder> get pending => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  void manualRetry() => _drain();

  Future<void> _persistQueue() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      'pending_orders',
      jsonEncode([for (final p in _queue) p.toJson()]),
    );
  }

  Future<void> _restoreQueue() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('pending_orders');
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _queue.addAll(list.map(PendingOrder.fromJson));
      _syncPending();
      if (_queue.isNotEmpty) _drain();
    } catch (_) {
      _queue.clear();
    }
  }
}

/// A queued order submission (offline bridge).
class PendingOrder {
  final String token;
  final String phone;
  final String merchantId;
  final List<Map<String, dynamic>> items;
  final String subCity;
  final String sefer;
  final String landmarkText;
  final double? lat;
  final double? lng;
  final String paymentMethod;
  int attempts;

  PendingOrder({
    required this.token,
    required this.phone,
    required this.merchantId,
    required this.items,
    required this.subCity,
    required this.sefer,
    required this.landmarkText,
    this.lat,
    this.lng,
    required this.paymentMethod,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'phone': phone,
    'merchantId': merchantId,
    'items': items,
    'subCity': subCity,
    'sefer': sefer,
    'landmarkText': landmarkText,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    'paymentMethod': paymentMethod,
    'attempts': attempts,
  };

  factory PendingOrder.fromJson(Map<String, dynamic> j) => PendingOrder(
    token: j['token'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    merchantId: j['merchantId'] as String? ?? '',
    items: ((j['items'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    subCity: j['subCity'] as String? ?? '',
    sefer: j['sefer'] as String? ?? '',
    landmarkText: j['landmarkText'] as String? ?? '',
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    paymentMethod: j['paymentMethod'] as String? ?? 'chapa',
    attempts: (j['attempts'] as num?)?.toInt() ?? 0,
  );
}