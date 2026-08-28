/// Strike engine (tech-spec §3.6).
///
/// Pure, dependency-free so it is unit-testable and mirrors the exact ladder:
///
///   leading 1 validated strike -> formal warning
///   2 -> suspended 1 week
///   3 -> suspended 1 month
///   4+ -> permanent removal
///
/// Symmetric for couriers, restaurants and customers. Strikes age out after
/// 180 clean days unless a more recent validated strike resets the window;
/// permanent removal never expires.
library;

import '../models/backend_services.dart';

class StrikeEngine {
  StrikeEngine._();

  /// The three parties the strike engine applies to (spec §3.6 symmetry).
  static const List<String> allParties = ['courier', 'restaurant', 'customer'];

  static const int cleanWindowDays = 180;

  /// Maps the number of *active (non-expired)* validated strikes to the
  /// consequent [StrikeLevel]. Returns null for a clean (0 active) record.
  static StrikeLevel? levelFor({required int activeValidatedStrikes}) {
    return switch (activeValidatedStrikes) {
      <= 0 => null,
      1 => StrikeLevel.warning,
      2 => StrikeLevel.suspendWeek,
      3 => StrikeLevel.suspendMonth,
      _ => StrikeLevel.permanent,
    };
  }

  /// True when a strike aged out (older than the clean window) and wasn't
  /// reset by a more recent re-offense.
  ///
  /// - [is] the latest strike timestamp for that subject. When passed
  ///   (the "last offense"), every strike is cleared only once this old PROVIDED
  ///   there is no fresher re-offense (see [owed] below).
  /// - [now] defaults to the current time.
  /// - [cleanSince]: when a newer offense exists, an old strike's 180-day count
  ///   is still "active" (not expired) because the window is reset.
  static bool isExpired({
    required DateTime issuedAt,
    DateTime? now,
    DateTime? cleanSince,
  }) {
    if (cleanSince != null) {
      // The most recent offense resets the window; older strikes are still
      // counted while that fresh offense is itself within the window.
      return cleanSince.difference(issuedAt).inDays > cleanWindowDays;
    }
    final reference = now ?? DateTime.now();
    return reference.difference(issuedAt).inDays > cleanWindowDays;
  }

  /// Permanent removals never age out.
  static bool isPermanent({required StrikeLevel level}) => level == StrikeLevel.permanent;
}