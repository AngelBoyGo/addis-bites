import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_root.dart';
import '../models/role_dashboards.dart';
import '../theme/app_colors.dart';
import 'shared.dart';

/// Sefer Rounds: the batch-delivery savings engine (§6B). Shows scheduled
/// rounds, live per-head fee that drops as neighbors join, and a "Join the
/// Round" action. Batched orders arrive within the round window (honest aim).
class SeferRoundCard extends ConsumerWidget {
  const SeferRoundCard({super.key, required this.round});
  final SeferRound round;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = StringsScope.of(context);
    final feeNow = round.perHeadFeeEtb <= 0 ? 0 : round.perHeadFeeEtb - round.memberCount;

    Widget feeMeter({required String label, required int fee, required Color color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
              Text('$fee ETB', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups, color: AppColors.primaryGold),
                const SizedBox(width: 8),
                Expanded(child: Text(round.label, style: Theme.of(context).textTheme.titleSmall)),
                const TagBadge(label: 'ROUND', color: AppColors.primaryGold),
              ],
            ),
            feeMeter(
              label: '${round.memberCount} ${s.neighborsJoined} · ${s.youSave}',
              fee: 150,
              color: AppColors.tsomGreen,
            ),
            feeMeter(label: s.yourFeeNow, fee: feeNow, color: AppColors.neutralDark),
            if (round.joinable) ...[
              const SizedBox(height: 8),
              Text('${s.moreNeighborSaved} · ${s.roundsArriveWindow}',
                  style: const TextStyle(fontSize: 11, color: AppColors.neutralMid)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Wired into checkout's request when a round is selected.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined the Round — fee splits across the batch')),
                    );
                  },
                  child: Text(s.joinRound, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Branded shareable receipt for share-to-save (§10B); one-tap share to Telegram.
class ShareCard extends ConsumerWidget {
  const ShareCard({super.key, required this.merchant, required this.message});
  final String merchant;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = StringsScope.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share-to-save · ${s.shareOnTelegram}', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text('$merchant · $message', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.telegram, size: 16),
                  label: const Text('Share'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _referral(context),
                  icon: const Icon(Icons.link),
                  label: const Text('Referral'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${s.referralCode}: AB-8891', style: const TextStyle(fontSize: 12, color: AppColors.neutralMid)),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      await launchUrl(Uri.parse('https://t.me/share/url?url=addis-bites.app/feed'),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _referral(BuildContext context) {
    // §10B referral deep link: both sides get 50 ETB after the referee's first
    // delivery. Shared as a Telegram deep link.
    final link = 't.me/addisbitesbot?startapp=refer_AB-8891';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral link ready — both get 50 ETB'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => launchUrl(Uri.parse('https://t.me/share/url?url=$link'),
              mode: LaunchMode.externalApplication),
        ),
      ),
    );
  }
}

/// Gursha gifting modal (§10.12): send a pre-paid meal to a phone with a blessing.
void showGurshaModal(BuildContext context, {String? itemName}) {
  final s = StringsScope.of(context);
  final phone = TextEditingController(text: '+251');
  final blessing = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.gursha, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(itemName ?? '', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Recipient phone')),
            const SizedBox(height: 8),
            TextField(controller: blessing, decoration: const InputDecoration(labelText: 'Blessing · ምኞት')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Pay & Send Gursha', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Group-cart / Share Gebeta modal (§10.12): a Telegram deep link members open
/// to add dishes to one communal platter.
void showShareGebetaModal(BuildContext context, String cartToken) {
  final s = StringsScope.of(context);
  final link = 't.me/addisbitesbot?startapp=cart_$cartToken';
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.shareGebeta, style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('One shared platter, one delivery fee, split payments.'),
          const SizedBox(height: 12),
          SelectableText(link, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                await launchUrl(Uri.parse('https://t.me/share/url?url=$link'),
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: Text(s.shareOnTelegram, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

/// Nominate a missing restaurant modal (§10B.5)
void showNominateRestaurantModal(BuildContext context) {
  final s = StringsScope.of(context);
  final name = TextEditingController();
  final location = TextEditingController();
  final note = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.nominateRestaurant, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Nominate your favorite local eatery. When it activates, you earn credit!',
                style: TextStyle(color: AppColors.neutralMid, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Restaurant name · የስም መጠሪያ')),
            const SizedBox(height: 8),
            TextField(controller: location, decoration: const InputDecoration(labelText: 'Neighborhood / landmark · ሰፈር/ልዩ ቦታ')),
            const SizedBox(height: 8),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Special dish / note (optional)')),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomination submitted! We will send a field agent to verify.')),
                  );
                },
                child: const Text('SUBMIT NOMINATION', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Wallet prepay & weekly lunch pass modal (§6.14, §6.17)
void showWalletTopupModal(BuildContext context) {
  final s = StringsScope.of(context);
  int amount = 500;

  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.walletTopup, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Prepay ≥500 ETB and get +5% extra credit to eliminate COD hassle.',
                style: TextStyle(color: AppColors.neutralMid, fontSize: 12)),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final opt in [500, 1000, 2500])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$opt ETB (+${(opt * 0.05).round()})'),
                      selected: amount == opt,
                      onSelected: (_) => setModalState(() => amount = opt),
                      selectedColor: AppColors.primaryGold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Topped up $amount ETB + ${(amount * 0.05).round()} ETB bonus credit!')),
                  );
                },
                child: Text('TOP UP VIA CHAPA / TELEBIRR · ${amount} ETB', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}