/// Ratings & tier-metric aggregator (tech-spec §3.6, §3.3 tier promotion).
///
/// Pure and dependency-free. Feed the ratings the tier engine consumes
/// (average / trailing-50 rating, on-time %); safe with empty inputs.
library;

import '../models/rating.dart';

class RatingAggregator {
  RatingAggregator._();

  /// Average stars over the most recent [lastN] ratings (all if null).
  /// Returns 0.0 when there are no ratings or [lastN] is zero.
  static double averageStars(List<RatingSubmission> ratings, {int? lastN}) {
    if (ratings.isEmpty) return 0.0;
    final n = lastN ?? ratings.length;
    if (n <= 0) return 0.0;
    final window = ratings.length <= n ? ratings : ratings.skip(ratings.length - n);
    final sum = window.fold<int>(0, (acc, r) => acc + r.stars);
    return sum / window.length;
  }

  /// On-time percentage from counts of on-time and late deliveries.
  static double onTimePercent({required int onTime, required int late}) {
    final total = onTime + late;
    if (total == 0) return 100.0;
    return (onTime / total) * 100;
  }
}