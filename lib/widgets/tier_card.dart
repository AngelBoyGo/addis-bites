import 'package:flutter/material.dart';

import '../app_root.dart';
import '../models/tier.dart';
import '../theme/app_colors.dart';

/// Courier tier progress card (§3.3). Shows the current tier, next-tier
/// threshold and progress bar derived from a delivery/count signal.
class TierCard extends StatelessWidget {
  const TierCard({super.key, required this.level, required this.completedDeliveries});
  final int level;
  final int completedDeliveries;

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final tier = kTierLadder[level.clamp(0, kTierLadder.length - 1)];
    final next = level < kTierLadder.length - 1 ? kTierLadder[level + 1] : null;

    double progress;
    if (next == null || next.deliveryThreshold <= 0) {
      progress = 1.0;
    } else {
      final from = tier.deliveryThreshold;
      final span = next.deliveryThreshold - from;
      progress = ((completedDeliveries - from) / span).clamp(0.0, 1.0);
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${s.tier}: ${tier.name} (L${tier.level})',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$completedDeliveries',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.neutralDark)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${tier.risk} · ${tier.radius} · ${tier.unlocks}',
                style: Theme.of(context).textTheme.bodySmall),
            if (next != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.cardBorder,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 4),
              Text(next.deliveryThreshold > 0
                  ? '${s.nextTier}: ${next.name} at ${next.deliveryThreshold} deliveries'
                  : s.crewLeader,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}