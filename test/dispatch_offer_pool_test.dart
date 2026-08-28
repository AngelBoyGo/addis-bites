import 'package:addis_bites/core/dispatch_offer_pool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 27, 12, 0);

  group('DispatchOfferPool (spec §3.4 step 5 offer waterfall)', () {
    test('creates offers to the nearest candidates', () {
      final pool = DispatchOfferPool.start(
        orderId: 'ord-1',
        candidates: ['c1', 'c2', 'c3', 'c4'],
        now: now,
      );
      expect(pool.offers.length, 3);
      expect(pool.offers.map((o) => o.courierId).toList(), ['c1', 'c2', 'c3']);
    });

    test('no offers if there are no candidates', () {
      final pool = DispatchOfferPool.start(orderId: 'ord-1', candidates: const [], now: now);
      expect(pool.offers, isEmpty);
    });

    test('accepting an offer assigns the courier', () {
      final pool = DispatchOfferPool.start(orderId: 'ord-1', candidates: ['c1', 'c2', 'c3'], now: now);
      final accepted = pool.accept('c1', now);
      expect(accepted.courierId, 'c1');
      expect(pool.isAssigned, isTrue);
      // after assignment, later accepts are ignored
      expect(pool.accept('c2', now).courierId, 'c1');
    });

    test('an expired offer is not accepted (timeout -> next candidate)', () {
      final pool = DispatchOfferPool.start(orderId: 'ord-1', candidates: ['c1', 'c2'], now: now);
      // c1's 20s window has passed
      expect(pool.accept('c1', now.add(const Duration(seconds: 21))).courierId, isNull);
      expect(pool.isAssigned, isFalse);
    });

    test('expired-but-other-candidate STILL assignable within their window', () {
      final pool = DispatchOfferPool.start(orderId: 'ord-1', candidates: ['c1', 'c2'], now: now);
      // offers are issued simultaneously, so at +19s BOTH are still live
      final r = pool.accept('c2', now.add(const Duration(seconds: 19)));
      expect(r.courierId, 'c2');
    });

    test('all candidates expired -> nothing assignable', () {
      final pool = DispatchOfferPool.start(orderId: 'ord-1', candidates: ['c1', 'c2'], now: now);
      expect(pool.accept('c1', now.add(const Duration(seconds: 21))).courierId, isNull);
      expect(pool.accept('c2', now.add(const Duration(seconds: 21))).courierId, isNull);
      expect(pool.isAssigned, isFalse);
    });

    test('declined offer removes that candidate from consideration', () {
      final pool = DispatchOfferPool.start(orderId: 'ord-1', candidates: ['c1', 'c2', 'c3'], now: now);
      pool.decline('c1');
      expect(pool.offers.where((o) => o.courierId == 'c1').single.status, OfferStatus.declined);
    });
  });
}