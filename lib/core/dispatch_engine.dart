/// Dispatch decision logic (tech-spec §3.4).
///
/// Pure, dependency-free so it is unit-testable and mirrors the logic the
/// worker applies at order time. Mode selection favours the cheapest
/// acceptable mode (foot first), matching the SLA (walk ETA <= 20 min) and the
/// cost moat (foot delivery is the cheapest last-150 m mode).
library;

/// Eligible delivery modes, cheapest-first priority.
enum DispatchMode { foot, bike, car }

class DispatchEngine {
  DispatchEngine._();

  static const int walkSlaMinutes = 20; // spec §3.4: mode gate
  static const int nearestNeighbors = 3; // spec §3.4: offer to nearest 3
  static const int escalationsToSwitch = 2; // "2 timeouts = auto-escalate"
  static const int upfillAlertMinutes = 3; // "unfilled 3 min = support alert"
  static const Duration offerWindow = Duration(seconds: 20);

  /// Selects the dispatch mode per spec §3.4 steps 1-4:
  ///  1. walk ETA <= 20 => nearest eligible runner
  ///  2. else bike/scooter ETA <= 20 => bike/scooter
  ///  3. else car
  static DispatchMode selectMode({required int walkEtaMin, required int bikeEtaMin}) {
    if (walkEtaMin <= walkSlaMinutes) return DispatchMode.foot;
    if (bikeEtaMin <= walkSlaMinutes) return DispatchMode.bike;
    return DispatchMode.car;
  }

  /// Returns true when the offer waterfall should escalate to the next mode
  /// (spec §3.4 step 5: `2 timeouts = auto-escalate to next mode`).
  static bool shouldEscalateMode({required int declines, required int nearestOffered}) {
    return declines >= escalationsToSwitch;
  }

  /// Returns true when no courier has accepted within the upfill window and a
  /// support alert is warranted (spec §3.4 step 5: unfilled 3 min).
  static bool upfillAlertNeeded({required int elapsedMin, required String? assigned}) {
    if (assigned != null) return false;
    return elapsedMin >= upfillAlertMinutes;
  }

  /// The ordered candidates (already nearest-first) capped to `n`.
  static List<String> nearestN({required Iterable<String> eligible, int n = nearestNeighbors}) {
    return eligible.take(n).toList();
  }
}