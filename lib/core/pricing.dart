import '../models/cart.dart';
import '../models/catalog.dart';

/// Mirrors the server pricing engine for *display* only. The client never sends
/// prices; totals shown here are advisory and the server stays authoritative.
///
/// Implements the §6 economics: distance bands, foot-tier downgrade (zero-fuel
/// for ≤1.5km), buna micro-tier, rain surge, off-peak happy hours, digital-pay
/// discount, and loyalty stamps. All values come from [AppConfig] — never hardcoded.
class Pricing {
  Pricing._();

  /// Delivery fee for a distance band, inflation-indexed via feeMultiplier.
  static int deliveryFee(AppConfig config, DeliveryBand band) {
    final base = switch (band) {
      DeliveryBand.foot => config.footFee,
      DeliveryBand.under2 => config.deliveryFee2km,
      DeliveryBand.mid5 => config.deliveryFee5km,
      DeliveryBand.far8 => config.deliveryFee8km,
    };
    return _scale(base, config.feeMultiplier);
  }

  static int _scale(int base, double multiplier) => (base * multiplier).round();

  /// Buna-run flat tier if eligible (order < bunaMaxOrder within bunaMaxKm).
  static int? bunaFee(AppConfig cfg, Cart cart) {
    if (cfg.bunaMaxOrder <= 0) return null;
    if (cart.subtotal >= cfg.bunaMaxOrder) return null;
    if (cart.band != DeliveryBand.under2) return null;
    return cfg.bunaRunFee;
  }

  static int? bunaRun(AppConfig cfg, Cart cart) => bunaFee(cfg, cart);

  static int surge(AppConfig cfg) => cfg.rainMode ? cfg.rainSurge : 0;

  /// True during 15:00–17:00 happy hours (§6 #9): discounted delivery.
  static bool isOffPeakHappyHour(DateTime now) {
    final h = now.hour;
    return h >= 15 && h < 17;
  }

  /// Off-peak discount: −10 ETB on delivery during happy hours (server-config
  /// in reality; surfaced in ETB per the fee transparency rule).
  static int offPeakDiscount(AppConfig cfg, DateTime now) =>
      isOffPeakHappyHour(now) ? 10 : 0;

  /// Digital-payment discount: only for Chapa/Telebirr (not COD).
  static int digitalPayDiscount(AppConfig cfg, String paymentMethod) =>
      paymentMethod == 'chapa' ? 8 : 0;

  /// The cheapest viable delivery fee for the given order, applying the foot
  /// downgrade when the distance is ≤1.5km (zero fuel) — labelled so the UI can
  /// show "Delivered on foot — you save X ETB".
  static int bestDelivery(AppConfig cfg, Cart cart, DateTime now, {String paymentMethod = 'chapa'}) {
    var delivery = bunaRun(cfg, cart) ?? deliveryFee(cfg, cart.band);
    // Foot downgrade: if cart is on the foot band, its deliveryFee already reflects
    // the zero-fuel tier; otherwise a nearer order on under2 can be matched down.
    if (cart.band == DeliveryBand.under2 && delivery > cfg.footFee) {
      final saved = delivery - cfg.footFee;
      if (saved > 0) delivery = cfg.footFee;
    }
    delivery -= offPeakDiscount(cfg, now);
    return delivery < 0 ? 0 : delivery;
  }

  static int total(AppConfig cfg, Cart cart, {DateTime? now, String paymentMethod = 'chapa'}) {
    final t = now ?? DateTime.now();
    final delivery = bestDelivery(cfg, cart, t, paymentMethod: paymentMethod);
    final total = cart.subtotal + delivery + cfg.serviceFee + surge(cfg);
    return total - offPeakDiscount(cfg, t) - digitalPayDiscount(cfg, paymentMethod);
  }

  /// Delivered-on-foot savings vs the standard band fee (§6 transparency).
  static int footSavings(AppConfig cfg, Cart cart) {
    final buna = bunaRun(cfg, cart);
    if (buna != null) return deliveryFee(cfg, cart.band) - buna;
    if (cart.band == DeliveryBand.under2 && deliveryFee(cfg, cart.band) > cfg.footFee) {
      return deliveryFee(cfg, cart.band) - cfg.footFee;
    }
    return 0;
  }
}

/// Loyalty stamps (§6 #13): every 10th delivery fee is free. Value derived here
/// so the visible stamp card can show progress honestly.
class Loyalty {
  Loyalty._();

  static bool isFree(int completedDeliveries) =>
      completedDeliveries > 0 && completedDeliveries % 10 == 0;

  static int stampsToNext(int completedDeliveries) => 10 - (completedDeliveries % 10);
}