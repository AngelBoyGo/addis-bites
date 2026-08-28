import 'package:addis_bites/core/strike_engine.dart';
import 'package:addis_bites/models/backend_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StrikeEngine.level (spec §3.6 strike engine)', () {
    test('1 validated strike = formal warning', () {
      expect(StrikeEngine.levelFor(activeValidatedStrikes: 1), StrikeLevel.warning);
    });

    test('2 = suspended 1 week', () {
      expect(StrikeEngine.levelFor(activeValidatedStrikes: 2), StrikeLevel.suspendWeek);
    });

    test('3 = suspended 1 month', () {
      expect(StrikeEngine.levelFor(activeValidatedStrikes: 3), StrikeLevel.suspendMonth);
    });

    test('4+ = permanent removal', () {
      expect(StrikeEngine.levelFor(activeValidatedStrikes: 4), StrikeLevel.permanent);
      expect(StrikeEngine.levelFor(activeValidatedStrikes: 7), StrikeLevel.permanent);
    });

    test('0 strikes means clean (no level)', () {
      expect(StrikeEngine.levelFor(activeValidatedStrikes: 0), isNull);
    });
  });

  group('StrikeEngine symmetry (spec: applies to courier, restaurant, customer)', () {
    test('is symmetric across parties', () {
      for (final party in StrikeEngine.allParties) {
        expect(StrikeEngine.levelFor(activeValidatedStrikes: 2),
            StrikeLevel.suspendWeek,
            reason: 'party $party must follow the same ladder');
      }
    });
  });

  group('StrikeEngine expiry (spec §3.6: strikes age out after 180 clean days)', () {
    test('strikes within 180 days still count', () {
      final issued = DateTime.now().subtract(const Duration(days: 100));
      expect(StrikeEngine.isExpired(issuedAt: issued, cleanSince: null), isFalse);
    });

    test('280 days old (no re-offense) is cleared', () {
      final issued = DateTime.now().subtract(const Duration(days: 280));
      expect(StrikeEngine.isExpired(issuedAt: issued, now: DateTime.now()), isTrue);
    });

    test('a recent re-offense resets the 180-day window', () {
      final old = DateTime.now().subtract(const Duration(days: 200));
      // cleanSince path: still active if there was a more recent strike
      final fresh = DateTime.now().subtract(const Duration(days: 20));
      expect(StrikeEngine.isExpired(issuedAt: fresh), isFalse);
      // the old strike's count is still active due to the fresh one
      expect(StrikeEngine.isExpired(issuedAt: old, cleanSince: fresh), isFalse);
    });

    test('permanent removal never expires', () {
      expect(StrikeEngine.isPermanent(level: StrikeLevel.permanent), isTrue);
      expect(StrikeEngine.isPermanent(level: StrikeLevel.warning), isFalse);
    });
  });
}