import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_root.dart';
import '../models/order.dart';
import '../models/rating.dart';
import '../providers/api_client_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';

/// Post-delivery rating prompt (§3.6). Customer rates the courier and the
/// restaurant; one rating per direction per order. Three-directional ratings
/// (courier→customer/restaurant) are surfaced from the courier/Runner app.
class RatingCard extends ConsumerStatefulWidget {
  const RatingCard({super.key, required this.order});
  final Order order;

  @override
  ConsumerState<RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends ConsumerState<RatingCard> {
  int _stars = 5;
  final Set<String> _tags = {};
  bool _submitted = false;

  Future<void> _submit(RateDirection direction) async {
    final token = ref.read(sessionProvider)?.token ?? '';
    await ref.read(apiClientProvider).submitRating(
      token,
      RatingSubmission(
        orderId: widget.order.id,
        direction: direction,
        stars: _stars,
        tags: _tags.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    if (_submitted) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.tsomGreen),
              const SizedBox(width: 10),
              Expanded(child: Text(s.thanks, style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.rateYourExperience, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => IconButton(
                onPressed: () => setState(() => _stars = i + 1),
                icon: Icon(i < _stars ? Icons.star : Icons.star_border,
                    color: AppColors.primaryGold, size: 30),
              )),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in kRatingTags)
                  ChoiceChip(
                    label: Text(tag.replaceAll('_', ' ')),
                    selected: _tags.contains(tag),
                    onSelected: (v) => setState(() => v ? _tags.add(tag) : _tags.remove(tag)),
                    selectedColor: AppColors.primaryGold,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _submit(RateDirection.customerToRestaurant);
                      if (mounted) setState(() => _submitted = true);
                    },
                    child: Text(s.rateRestaurant),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await _submit(RateDirection.customerToCourier);
                      if (mounted) setState(() => _submitted = true);
                    },
                    child: Text(s.rateCourier),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}