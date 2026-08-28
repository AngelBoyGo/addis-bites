/// Dispatch offer pool (tech-spec §3.4 step 5).
///
/// Pure and dependency-free. Enforces the offer waterfall: each candidate gets
/// a 20s acceptance window; a courier is assigned on the first valid accept;
/// expiring or declining moves on. Safe with no candidates.
library;

enum OfferStatus { offered, declined, timedOut, accepted }

class DriverOfferSlot {
  const DriverOfferSlot({
    required this.courierId,
    required this.expiresAt,
    this.status = OfferStatus.offered,
  });
  final String courierId;
  final DateTime expiresAt;
  final OfferStatus status;

  DriverOfferSlot copyWith({OfferStatus? status}) => DriverOfferSlot(
    courierId: courierId,
    expiresAt: expiresAt,
    status: status ?? this.status,
  );
}

class OfferAcceptance {
  const OfferAcceptance({this.courierId});
  final String? courierId;
}

class DispatchOfferPool {
  DispatchOfferPool._({
    required this.orderId,
    required this.offers,
  });

  static const int nearestCount = 3;
  static const Duration offerWindow = Duration(seconds: 20);

  final String orderId;
  final List<DriverOfferSlot> offers;

  bool get isAssigned => offers.any((o) => o.status == OfferStatus.accepted);

  /// Starts an offer pool to the nearest [nearestCount] candidates.
  static DispatchOfferPool start({
    required String orderId,
    required List<String> candidates,
    required DateTime now,
  }) {
    final offerCount = candidates.length < nearestCount ? candidates.length : nearestCount;
    return DispatchOfferPool._(
      orderId: orderId,
      offers: [
        for (var i = 0; i < offerCount; i++)
          DriverOfferSlot(
            courierId: candidates[i],
            expiresAt: now.add(offerWindow),
          ),
      ],
    );
  }

  bool _isAssignable(DriverOfferSlot o, DateTime now) =>
      o.status == OfferStatus.offered && !now.isAfter(o.expiresAt);

  /// Accepts an offer if [courierId] has a live (unexpired, still-offered) slot
  /// and the order is not already assigned. Returns the assigned courier or null.
  OfferAcceptance accept(String courierId, DateTime now) {
    final idx = offers.indexWhere((o) => o.courierId == courierId && _isAssignable(o, now));
    if (idx < 0) return const OfferAcceptance();
    if (isAssigned) {
      // already assigned -> report the existing assignee
      final a = offers.firstWhere((o) => o.status == OfferStatus.accepted);
      return OfferAcceptance(courierId: a.courierId);
    }
    offers[idx] = offers[idx].copyWith(status: OfferStatus.accepted);
    return OfferAcceptance(courierId: courierId);
  }

  /// Marks an offer declined (moves on to the next candidate).
  void decline(String courierId) {
    final idx = offers.indexWhere((o) => o.courierId == courierId && o.status == OfferStatus.offered);
    if (idx >= 0) offers[idx] = offers[idx].copyWith(status: OfferStatus.declined);
  }
}