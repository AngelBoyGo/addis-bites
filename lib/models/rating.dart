/// Three-directional ratings (tech-spec §3.6): customer↔courier,
/// customer↔restaurant, courier↔customer, courier↔restaurant.
library;

enum RateDirection {
  customerToCourier,
  customerToRestaurant,
  courierToCustomer,
  courierToRestaurant,
}

extension RateDirectionX on RateDirection {
  String get wire => switch (this) {
    RateDirection.customerToCourier => 'customer_to_courier',
    RateDirection.customerToRestaurant => 'customer_to_restaurant',
    RateDirection.courierToCustomer => 'courier_to_customer',
    RateDirection.courierToRestaurant => 'courier_to_restaurant',
  };
}

/// A rating submission for one order/direction. One rating per direction per
/// order (server enforced via UNIQUE(order_id, rater_type, ratee_type)).
class RatingSubmission {
  final String orderId;
  final RateDirection direction;
  final int stars; // 1..5
  final List<String> tags; // late, rude, cold_food, great_service …
  final String? comment;

  const RatingSubmission({
    required this.orderId,
    required this.direction,
    required this.stars,
    this.tags = const [],
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'direction': direction.wire,
    'stars': stars,
    'tags': tags,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
  };
}

/// Common rating tags surfaced in the UI.
const kRatingTags = [
  'great_service',
  'on_time',
  'cold_food',
  'late',
  'poor_packaging',
  'friendly',
  'rude',
  'good_value',
];