import 'package:addis_bites/core/tier_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TierEngine promotion (spec §3.3 tier ladder)', () {
    test('tier 1 meets threshold 25 but fails rating stays on tier 1', () {
      expect(
        TierEngine.shouldPromote(
          fromLevel: 1,
          deliveries: 40,
          rating: 4.0,
          onTimePct: 95,
          openStrikes: 0,
          tenureDays: 20,
          guaranteeGoodStanding: true,
        ),
        isFalse,
      );
    });

    test('tier 1 fully qualifies to tier 2', () {
      expect(
        TierEngine.shouldPromote(
          fromLevel: 1,
          deliveries: 30,
          rating: 4.4,
          onTimePct: 92,
          openStrikes: 0,
          tenureDays: 30,
          guaranteeGoodStanding: true,
        ),
        isTrue,
      );
    });

    test('tier 3->4 requires 250 deliveries and 95% on-time', () {
      // 120 deliveries qualifies for tier 3 but not tier 4 (needs 250)
      expect(
        TierEngine.shouldPromote(fromLevel: 3, deliveries: 120, rating: 4.6, onTimePct: 96, openStrikes: 0, tenureDays: 40, guaranteeGoodStanding: true),
        isFalse,
      );
      expect(
        TierEngine.shouldPromote(fromLevel: 3, deliveries: 260, rating: 4.6, onTimePct: 96, openStrikes: 0, tenureDays: 31, guaranteeGoodStanding: true),
        isTrue,
      );
    });

    test('an open strike blocks any promotion', () {
      expect(
        TierEngine.shouldPromote(fromLevel: 1, deliveries: 999, rating: 5.0, onTimePct: 100, openStrikes: 1, tenureDays: 200, guaranteeGoodStanding: true),
        isFalse,
      );
    });

    test('tier 5 is nomination-based, never auto-promotes', () {
      expect(
        TierEngine.shouldPromote(fromLevel: 5, deliveries: 999, rating: 5.0, onTimePct: 100, openStrikes: 0, tenureDays: 999, guaranteeGoodStanding: true),
        isFalse,
      );
    });
  });

  group('TierEngine demotion (spec §3.3)', () {
    test('rating below 4.0 over trailing window demotes one tier', () {
      expect(TierEngine.shouldDemote(openStrikes: 0, trailing50Rating: 3.9), isTrue);
    });

    test('an unresolved strike demotes one tier', () {
      expect(TierEngine.shouldDemote(openStrikes: 1, trailing50Rating: 4.5), isTrue);
    });

    test('healthy courier is not demoted', () {
      expect(TierEngine.shouldDemote(openStrikes: 0, trailing50Rating: 4.5), isFalse);
    });

    test('no demotion below tier 1', () {
      expect(TierEngine.cappedDemotion(fromLevel: 0, shouldDemote: true), 0);
      expect(TierEngine.cappedDemotion(fromLevel: 3, shouldDemote: true), 2);
    });
  });
}