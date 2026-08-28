/// Courier tier promotion & demotion engine (tech-spec §3.3).
///
/// Pure and dependency-free so the ladder is unit-testable anywhere the worker
/// or client runs. Promotion requires every criterion for the TARGET tier to be
/// met; demotion is a single unresolved strike or a trailing-50 rating < 4.0.
library;

class TierEngine {
  TierEngine._();

  /// Promotion criteria (spec §3.3 tier ladder). Keys: target level.
  /// [deliveries, minRating, minOnTimePct, minTenureDays, needsGuaranteeGoodStanding]
  static const Map<int, _Promo> _promoC = {
    2: _Promo(25, 4.3, 90, 0, false), // tier 1 -> 2
    3: _Promo(100, 4.5, 93, 30, false), // tier 2 -> 3
    4: _Promo(250, 4.6, 95, 0, true), // tier 3 -> 4 (guarantee group)
    5: _Promo(500, 4.6, 0, 90, false), // tier 4 -> 5 (clean 90-day record)
  };

  /// True when the courier should promote from `fromLevel` to `fromLevel + 1`.
  static bool shouldPromote({
    required int fromLevel,
    required int deliveries,
    required double rating,
    required int onTimePct,
    required int openStrikes,
    required int tenureDays,
    required bool guaranteeGoodStanding,
  }) {
    if (openStrikes > 0) return false; // an open strike blocks promotion
    if (fromLevel >= 5) return false; // tier 5 is admin nomination only

    final target = _promoC[fromLevel + 1];
    if (target == null) return false;

    if (deliveries < target.deliveries) return false;
    if (rating < target.minRating) return false;
    if (onTimePct < target.minOnTimePct) return false;
    if (tenureDays < target.minTenureDays) return false;
    if (target.needsGuarantee && !guaranteeGoodStanding) return false;
    return true;
  }

  /// True when the courier should drop one tier: an unresolved strike or a
  /// rating below 4.0 over the trailing 50 deliveries (spec §3.3 demotion).
  static bool shouldDemote({required int openStrikes, required double trailing50Rating}) {
    return openStrikes > 0 || trailing50Rating < 4.0;
  }

  /// Demote one tier but never below level 0.
  static int cappedDemotion({required int fromLevel, required bool shouldDemote}) {
    if (!shouldDemote) return fromLevel;
    return fromLevel <= 0 ? 0 : fromLevel - 1;
  }
}

class _Promo {
  const _Promo(this.deliveries, this.minRating, this.minOnTimePct, this.minTenureDays, this.needsGuarantee);
  final int deliveries;
  final double minRating;
  final int minOnTimePct;
  final int minTenureDays;
  final bool needsGuarantee;
}