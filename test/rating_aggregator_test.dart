import 'package:addis_bites/core/rating_aggregator.dart';
import 'package:addis_bites/models/rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RatingAggregator (spec §3.6 ratings -> metrics)', () {
    test('average across valid ratings', () {
      const ratings = [
        RatingSubmission(orderId: 'a', direction: RateDirection.customerToCourier, stars: 5),
        RatingSubmission(orderId: 'b', direction: RateDirection.customerToCourier, stars: 3),
        RatingSubmission(orderId: 'c', direction: RateDirection.customerToCourier, stars: 4),
      ];
      expect(RatingAggregator.averageStars(ratings), closeTo(4.0, 0.001));
    });

    test('average starts at 0 for no ratings', () {
      expect(RatingAggregator.averageStars(const []), 0.0);
    });

    test('trailing-50 average drops rating spikes', () {
      // 10 five-star + 40 four-star = 4.2
      final ratings = [
        for (var i = 0; i < 10; i++) RatingSubmission(orderId: 'r$i', direction: RateDirection.customerToCourier, stars: 5),
        for (var i = 10; i < 50; i++) RatingSubmission(orderId: 'r$i', direction: RateDirection.customerToCourier, stars: 4),
      ];
      expect(RatingAggregator.averageStars(ratings, lastN: 50), closeTo(4.2, 0.001));
    });

    test('on-time percentage splits on-time vs late deliveries', () {
      expect(RatingAggregator.onTimePercent(onTime: 95, late: 5), 95.0);
      expect(RatingAggregator.onTimePercent(onTime: 0, late: 0), 100.0);
      expect(RatingAggregator.onTimePercent(onTime: 0, late: 3), 0.0);
    });
  });
}