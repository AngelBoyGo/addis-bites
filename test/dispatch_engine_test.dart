import 'package:addis_bites/core/dispatch_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DispatchEngine.mode (spec §3.4 steps 1-4)', () {
    test('walk ETA <= 20 defaults to a foot runner first', () {
      expect(DispatchEngine.selectMode(walkEtaMin: 12, bikeEtaMin: 8), DispatchMode.foot);
      expect(DispatchEngine.selectMode(walkEtaMin: 20, bikeEtaMin: 10), DispatchMode.foot);
    });

    test('walk > 20 but bike/scooter ETA <= 20 selects bike', () {
      expect(DispatchEngine.selectMode(walkEtaMin: 25, bikeEtaMin: 14), DispatchMode.bike);
    });

    test('both walk and bike exceed 20 selects car', () {
      expect(DispatchEngine.selectMode(walkEtaMin: 30, bikeEtaMin: 25), DispatchMode.car);
    });

    test('bike option is ignored once foot is within 20 min', () {
      // even if bike is faster, the runner is cheapest and within SLA
      expect(DispatchEngine.selectMode(walkEtaMin: 15, bikeEtaMin: 5), DispatchMode.foot);
    });
  });

  group('DispatchEngine.waterfall (spec §3.4 step 5)', () {
    test('no offers declined escalates to next mode', () {
      // two of the three nearest declined -> auto-escalate
      expect(DispatchEngine.shouldEscalateMode(declines: 2, nearestOffered: 3), isTrue);
    });

    test('a single decline does not escalate', () {
      expect(DispatchEngine.shouldEscalateMode(declines: 1, nearestOffered: 3), isFalse);
    });

    test('unfilled after 3 minutes triggers a support alert', () {
      expect(DispatchEngine.upfillAlertNeeded(elapsedMin: 3, assigned: null), isTrue);
      expect(DispatchEngine.upfillAlertNeeded(elapsedMin: 2, assigned: null), isFalse);
    });

    test('no support alert once the order is assigned', () {
      expect(DispatchEngine.upfillAlertNeeded(elapsedMin: 9, assigned: 'courier-1'), isFalse);
    });
  });

  group('DispatchEngine.offer window (spec §3.4: 20s per courier)', () {
    test('offer to exactly the nearest three eligible couriers', () {
      expect(DispatchEngine.nearestN(eligible: ['a', 'b', 'c', 'd'], n: 3), ['a', 'b', 'c']);
    });

    test('fewer eligible than n offered fully', () {
      expect(DispatchEngine.nearestN(eligible: ['a'], n: 3), ['a']);
    });
  });
}