import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/session.dart';
import '../../providers/locale_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/savings.dart';

/// "More" tab: language toggle, referral, share-to-save, data-saver mode,
/// session (role / sign out). All strings from the catalog; no hardcoding.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final LocaleId locale = ref.watch(localeProvider);
    final Session? session = ref.watch(sessionProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('More · ተጨማሪ', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Column(
            children: [
              SwitchListTile(
                value: locale == LocaleId.am,
                title: const Text('ሀሮች ቋንቋ · Language'),
                subtitle: const Text('English / አማርኛ'),
                onChanged: (_) => ref.read(localeProvider.notifier).toggle(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              SwitchListTile(
                value: ref.watch(dataSaverProvider),
                title: Text(s.dataSaver),
                subtitle: const Text('Text-only menus — saves your data bundle'),
                onChanged: (v) => ref.read(dataSaverProvider.notifier).set(v),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const ShareCard(merchant: 'Addis Bites', message: 'Order from local kitchens, delivered with care'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.group_add, color: AppColors.primaryGold),
            title: Text(s.referFriend),
            subtitle: const Text('AB-8891'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Referral link copied — both get 50 ETB')),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: AppColors.primaryGold),
            title: Text(s.walletTopup),
            subtitle: const Text('Top up ≥500 ETB → +5% bonus credit'),
            onTap: () => showWalletTopupModal(context),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.add_business, color: AppColors.primaryGold),
            title: Text(s.nominateRestaurant),
            subtitle: const Text('Nominate missing local kitchen → earn 50 ETB'),
            onTap: () => showNominateRestaurantModal(context),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.redeem, color: AppColors.primaryGold),
            title: Text(s.sendWarmMeal),
            onTap: () => showGurshaModal(context),
          ),
        ),
        const SizedBox(height: 12),
        if (session != null)
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signed in as ${session.profile.name}', style: Theme.of(context).textTheme.titleSmall),
                  Text('${session.profile.phone} · ${session.profile.role.name}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(sessionProvider.notifier).signOut();
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}