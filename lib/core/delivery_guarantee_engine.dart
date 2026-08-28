/// Delivery guarantees (tech-spec §3.4 step 7).
///
/// Automatic, server-computed credits when a delivery misses its promised time:
///   - breach > 15 min  -> automatic buna-fee credit (50 ETB)
///   - breach > 30 min  -> delivery-fee refund (auto-approved, logged)
/// Pure and dependency-free for unit-testing.
library;

class DeliveryGuarantee {
  const DeliveryGuarantee({
    required this.bunaCreditEtb,
    required this.deliveryRefundEtb,
    required this.autoApproved,
  });

  final int bunaCreditEtb;
  final int deliveryRefundEtb;
  final bool autoApproved;

  bool get hasAny => bunaCreditEtb > 0 || deliveryRefundEtb > 0;
}

class DeliveryGuaranteeEngine {
  DeliveryGuaranteeEngine._();

  static const int bunaFeeEtb = 50;
  static const int deliveryFeeEtb = 80;
  static const int bunaThresholdMin = 15; // > 15 min -> buna credit
  static const int deliveryRefundThresholdMin = 30; // > 30 min -> delivery refund

  /// Evaluates guarantee credits for a delivery. When `deliveredAt` is null
  /// (not yet delivered) no credit is granted.
  static DeliveryGuarantee evaluate({
    required DateTime promisedAt,
    required DateTime? deliveredAt,
  }) {
    if (deliveredAt == null) {
      return const DeliveryGuarantee(bunaCreditEtb: 0, deliveryRefundEtb: 0, autoApproved: false);
    }
    final lateMin = deliveredAt.difference(promisedAt).inMinutes;
    if (lateMin <= bunaThresholdMin) {
      return const DeliveryGuarantee(bunaCreditEtb: 0, deliveryRefundEtb: 0, autoApproved: false);
    }
    final buna = bunaFeeEtb;
    final refund = lateMin > deliveryRefundThresholdMin ? deliveryFeeEtb : 0;
    return DeliveryGuarantee(
      bunaCreditEtb: buna,
      deliveryRefundEtb: refund,
      autoApproved: true,
    );
  }
}