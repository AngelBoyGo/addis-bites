/// Courier tier ladder (tech-spec §3.3).
library;

class CourierTier {
  final int level;
  final String name;
  final String radius;
  final String risk;
  final String unlocks;
  final int deliveryThreshold;

  const CourierTier({
    required this.level,
    required this.name,
    required this.radius,
    required this.risk,
    required this.unlocks,
    required this.deliveryThreshold,
  });
}

const kTierLadder = [
  CourierTier(level: 0, name: 'Trainee', radius: '—', risk: 'shadow runs',
      unlocks: 'stipend 150 ETB/day', deliveryThreshold: 0),
  CourierTier(level: 1, name: 'Runner', radius: '≤1.5 km', risk: 'prepaid only, basket ≤600 ETB',
      unlocks: 'earnings + gear', deliveryThreshold: 25),
  CourierTier(level: 2, name: 'Runner+', radius: '≤1.5 km', risk: 'prepaid, basket ≤2,000 ETB, Sefer Rounds',
      unlocks: 'priority dispatch', deliveryThreshold: 100),
  CourierTier(level: 3, name: 'Trusted', radius: '≤3 km', risk: 'COD 1,500 ETB cap',
      unlocks: 'mechanical-bike financing (after 90 days)', deliveryThreshold: 250),
  CourierTier(level: 4, name: 'Rider', radius: '≤5 km', risk: 'COD uncapped',
      unlocks: 'scooter financing, night shifts', deliveryThreshold: 500),
  CourierTier(level: 5, name: 'Captain', radius: '≤8 km', risk: 'all',
      unlocks: 'trainer/mentor bonus, hub deputy', deliveryThreshold: -1),
];