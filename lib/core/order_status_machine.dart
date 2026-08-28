/// Order lifecycle state machine (tech-spec §3.4 orders).
///
/// Pure and dependency-free so the transition table is unit-testable and can be
/// enforced identically on the client and the worker. Rejects illegal jumps
/// (e.g. courierAssigned -> delivered without pickup/en-route) rather than
/// silently accepting them.
library;

import '../models/order.dart';

class OrderStatusMachine {
  OrderStatusMachine._();

  /// Ordered happy-path chain: placed -> merchantAck -> preparing ->
  /// courierAssigned -> pickedUp -> enRoute -> arrived -> delivered.
  /// cancelled is the only other reachable state (from any active state).
  static const List<OrderStatus> _chain = [
    OrderStatus.placed,
    OrderStatus.merchantAck,
    OrderStatus.preparing,
    OrderStatus.courierAssigned,
    OrderStatus.pickedUp,
    OrderStatus.enRoute,
    OrderStatus.arrived,
    OrderStatus.delivered,
  ];

  static bool _isActive(OrderStatus s) =>
      s != OrderStatus.cancelled && s != OrderStatus.delivered;

  /// True when `from` may legally transition to `to`.
  static bool allows(OrderStatus from, OrderStatus to) {
    if (from == to) return true; // idempotent
    if (to == OrderStatus.cancelled) return _isActive(from);
    if (from == OrderStatus.delivered || from == OrderStatus.cancelled) return false;
    // normal path: must be the immediate-next in the chain
    final i = _chain.indexOf(from);
    if (i < 0 || i + 1 >= _chain.length) return false;
    return _chain[i + 1] == to;
  }

  /// Returns the next legal status in the happy path, or null (terminal:
  /// delivered or cancelled).
  static OrderStatus? advance(OrderStatus from) {
    final next = _next(from);
    if (next == null) return null;
    return allows(from, next) ? next : null;
  }

  static OrderStatus? _next(OrderStatus from) {
    final i = _chain.indexOf(from);
    if (i < 0 || i + 1 >= _chain.length) return null;
    return _chain[i + 1];
  }
}