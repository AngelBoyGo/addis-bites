import 'package:addis_bites/core/delivery_guarantee_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final promised = DateTime(2026, 8, 27, 12, 0);

  group('DeliveryGuaranteeEngine (spec §3.4 step 7)', () {
    test('delivery on time -> no guarantee credit', () {
      final guarantee = DeliveryGuaranteeEngine.evaluate(
        promisedAt: promised,
        deliveredAt: promised.add(const Duration(minutes: 10)),
      );
      expect(guarantee.bunaCreditEtb, 0);
      expect(guarantee.deliveryRefundEtb, 0);
    });

    test('breach 15-30 min -> automatic buna-fee credit (50 ETB)', () {
      final guarantee = DeliveryGuaranteeEngine.evaluate(
        promisedAt: promised,
        deliveredAt: promised.add(const Duration(minutes: 25)),
      );
      expect(guarantee.bunaCreditEtb, 50);
      expect(guarantee.deliveryRefundEtb, 0);
    });

    test('breach >30 min -> delivery-fee refund (auto-approved)', () {
      final guarantee = DeliveryGuaranteeEngine.evaluate(
        promisedAt: promised,
        deliveredAt: promised.add(const Duration(minutes: 45)),
      );
      expect(guarantee.bunaCreditEtb, 50);
      expect(guarantee.deliveryRefundEtb, 80);
      expect(guarantee.autoApproved, isTrue);
    });

    test('exactly 15 min is boundary and does NOT breach', () {
      final guarantee = DeliveryGuaranteeEngine.evaluate(
        promisedAt: promised,
        deliveredAt: promised.add(const Duration(minutes: 15)),
      );
      expect(guarantee.deliveryRefundEtb, 0);
    });

    test('exactly 30 min does NOT yet trigger the delivery refund (>30 rule)', () {
      final guarantee = DeliveryGuaranteeEngine.evaluate(
        promisedAt: promised,
        deliveredAt: promised.add(const Duration(minutes: 30)),
      );
      expect(guarantee.deliveryRefundEtb, 0);
      expect(guarantee.bunaCreditEtb, 50); // >15 still credits buna
    });

    test('31 min crosses the >30 delivery-refund threshold', () {
      final guarantee = DeliveryGuaranteeEngine.evaluate(
        promisedAt: promised,
        deliveredAt: promised.add(const Duration(minutes: 31)),
      );
      expect(guarantee.deliveryRefundEtb, 80);
      expect(guarantee.autoApproved, isTrue);
    });

    test('undelivered cancels all guarantee logic', () {
      final guarantee = DeliveryGuaranteeEngine.evaluate(promisedAt: promised, deliveredAt: null);
      expect(guarantee.bunaCreditEtb, 0);
      expect(guarantee.deliveryRefundEtb, 0);
    });
  });
}