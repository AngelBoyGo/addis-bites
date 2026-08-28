import '../models/catalog.dart';

/// Resolves fasting state from the server `fasting` field, but also computes
/// the weekly Orthodox fasting rule (every Wednesday & Friday) and seasonal fasts
/// so the banner works accurately even when offline or before server sync.
///
/// Ethiopian Orthodox Tewahedo Church major fasts:
///  - Weekly fasts: every Wednesday and Friday (except during the 50 days of Pentecost/Kidan).
///  - Filseta (Assumption fast): August 7 – August 22 (Nahase 1 – Nahase 16).
///  - Tsome Nebiyat (Advent fast): November 25 – January 6 (Hidar 15 – Tahsas 28).
///  - Tsome Gahad (Eve of Timkat / Genna): Jan 6, Jan 18.
///  - Abiy Tsom (Great Lent): variable spring fast ~55 days before Easter/Fasika.
class FastingEngine {
  FastingEngine._();

  static bool isWednesdayOrFriday(DateTime d) =>
      d.weekday == DateTime.wednesday || d.weekday == DateTime.friday;

  /// Returns true if the date falls into a fixed seasonal fasting period.
  static bool isSeasonalFast(DateTime d) {
    final m = d.month;
    final day = d.day;

    // Filseta: August 7 – August 22
    if (m == 8 && day >= 7 && day <= 22) return true;

    // Tsome Nebiyat (Advent): Nov 25 – Dec 31, Jan 1 – Jan 6
    if (m == 11 && day >= 25) return true;
    if (m == 12) return true;
    if (m == 1 && day <= 6) return true;

    // Tsome Gahad (Eve of Timkat): Jan 18
    if (m == 1 && day == 18) return true;

    return false;
  }

  /// Combined active state: server `fasting.active` OR seasonal fast OR weekly Wed/Fri.
  static bool isActive(DateTime now, FastingState server) {
    if (server.active) return true;
    if (isSeasonalFast(now)) return true;
    if (server.weekly) return isWednesdayOrFriday(now);
    return isWednesdayOrFriday(now);
  }

  static String label(DateTime now, FastingState server, {required bool isAm}) {
    if (server.active && (isAm ? server.labelAm : server.labelEn).isNotEmpty) {
      return isAm ? server.labelAm : server.labelEn;
    }
    final m = now.month;
    final day = now.day;

    if (m == 8 && day >= 7 && day <= 22) {
      return isAm ? 'ጾመ ፍልሰታ' : 'Filseta Fast';
    }
    if ((m == 11 && day >= 25) || m == 12 || (m == 1 && day <= 6)) {
      return isAm ? 'ጾመ ነቢያት' : 'Advent Fast';
    }
    if (m == 1 && day == 18) {
      return isAm ? 'ጾመ ጋድ' : 'Gahad Fast';
    }

    if (server.weekly || isWednesdayOrFriday(now)) {
      return isAm ? 'የጾም ቀን' : 'Fasting day';
    }
    return '';
  }
}
