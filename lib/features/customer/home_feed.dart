import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../core/search.dart';
import '../../i18n/strings.dart';
import '../../models/catalog.dart';
import '../../models/catalog_response.dart';
import '../../models/menu.dart';
import '../../models/merchant.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/fasting_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards.dart';
import '../../widgets/savings.dart';
import '../../widgets/shared.dart';

/// Customer home feed.
///
/// Includes the two core batteries requested:
///  - an **Open Now** toggle (filters merchants to those currently open), and
///  - a **search bar** matching across restaurant names, menu items, food
///    categories and lifestyle descriptors (vegan, keto, halal, tsom…).
/// Also honours fasting mode (green banner + "Show all" override), the
/// independent halal filter, the Restaurant of the Day hero, and a bouncing
/// tag list that navigates to faceted results.
class HomeFeed extends ConsumerStatefulWidget {
  const HomeFeed({super.key});

  @override
  ConsumerState<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends ConsumerState<HomeFeed> {
  CatalogFilter _filter = const CatalogFilter();
  bool _trueCost = false; // §6 #18: sort by food + delivery total, not food alone

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final catalogAsync = ref.watch(catalogProvider);
    final fasting = ref.watch(fastingProvider);

    return catalogAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('${s.connectionLost} — $e'))),
      data: (catalog) {
        final showFasting = fasting.active;
        final all = catalog.merchants;
        // Coverage gating (§11.4): only render merchants whose hub the user can
        // reach; here we surface all but mark clearly the deliverable ones.
        final filtered0 = all.where(_filter.matches).toList();
        // §6 #18 true-cost sort: order by food + delivery total, not food alone.
        final filtered = _trueCost
            ? (List<Merchant>.from(filtered0)
                ..sort((a, b) => _roughTotal(a, catalog).compareTo(_roughTotal(b, catalog))))
            : filtered0;
        final ofTheDay =
            all.where((m) => m.isRestaurantOfTheDay).toList().isEmpty
                ? null
                : all.firstWhere((m) => m.isRestaurantOfTheDay);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _header(context),
                _search(context),
                _dealRow(context, filtered, catalog),
                if (showFasting) _fastingBanner(context, catalog.fasting),
                _filters(context),
                if (catalog.config.demoMode)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(alignment: Alignment.centerRight, child: DemoBadge()),
                  ),
                const Divider(height: 1, color: AppColors.cardBorder),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(catalogProvider.notifier).refresh(),
                    child: filtered.isEmpty
                        ? _empty(context)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final m = filtered[i];
                              final hero = m == ofTheDay;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hero) _heroCard(context, m),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: MerchantCard(
                                      merchant: m,
                                      onTap: () => context.push('/restaurant/${m.id}'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- header ----
  Widget _header(BuildContext context) {
    final s = StringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: AppColors.primaryGold, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Addis Bites\nአዲስ ባይትስ',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            tooltip: s.sendGursha,
            onPressed: () => showGurshaModal(context),
            icon: const Icon(Icons.redeem, color: AppColors.neutralDark),
          ),
          IconButton(
            tooltip: 'EN / አማ',
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            icon: const Icon(Icons.translate, color: AppColors.neutralDark),
          ),
          IconButton(
            onPressed: () => context.push('/orders'),
            icon: const Icon(Icons.history, color: AppColors.neutralDark),
          ),
        ],
      ),
    );
  }

  // ---- search bar ----
  Widget _search(BuildContext context) {
    final s = StringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        textInputAction: TextInputAction.search,
        onChanged: (q) => setState(() => _filter = _filter.copyWith(query: q)),
        onSubmitted: (_) => context.push('/search'),
        decoration: InputDecoration(
          hintText: s.searchPlaceholder,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => setState(() {}),
          ),
        ),
      ),
    );
  }

  // ---- fasting banner ----
  Widget _fastingBanner(BuildContext context, FastingState f) {
    final s = StringsScope.of(context);
    final label = f.labelEn.isEmpty ? s.fasting : f.labelEn;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tsomGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label · ${s.fastingModeActive}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => ref.read(fastingOverrideProvider.notifier).toggle(),
            child: Text('${s.showAll} · ${s.fastingTag}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ---- filter chips: All / Tsom / Halal + Open Now + area ----
  List<Widget> _hubChips(BuildContext context, CatalogResponse catalog) {
    final subs = catalog.subCities.take(6).toList();
    return [
      for (final sc in subs)
        _chip(sc.nameEn, _filter.hub == sc.nameEn,
            () => setState(() => _filter = _filter.copyWith(hub: _filter.hub == sc.nameEn ? '' : sc.nameEn))),
    ];
  }

  // ---- deal row: Yezare Liyu (flash deals), true-cost sort, cheaper-nearby ----
  Widget _dealRow(BuildContext context, List<Merchant> filtered, CatalogResponse? catalog) {
    final s = StringsScope.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // "Yezare Liyu" surplus flash deals (§6 #10).
          ActionChip(
            avatar: const Icon(Icons.local_offer, size: 16),
            label: const Text('የዛሬ ልዩ · Yezare Liyu'),
            onPressed: () {
              final deals = (catalog?.items ?? const <MenuItem>[])
                  .where((i) => i.priceEtb <= 150)
                  .toList();
              showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(s.dailySpecial, style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (deals.isEmpty)
                      Text('Nothing on flash right now', style: Theme.of(ctx).textTheme.bodySmall)
                    else
                      for (final it in deals)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.rice_bowl),
                          title: Text('${it.nameEn} · ${it.priceEtb} ETB'),
                          subtitle: Text(it.nameAm, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // True-cost sort: sort by food + delivery total, not food alone (§6 #18).
          FilterChip(
            avatar: Icon(_trueCost ? Icons.sort : Icons.sort_by_alpha, size: 16),
            label: Text(s.trueCost),
            selected: _trueCost,
            onSelected: (_) => setState(() => _trueCost = !_trueCost),
          ),
          if (catalog != null)
            for (final cheaper in _cheaperNearby(catalog, filtered)) _cheaperNearbyChip(context, s, cheaper),
        ],
      ),
    );
  }


  int _roughTotal(Merchant m, CatalogResponse? catalog) {
    final items = (catalog?.items ?? const <MenuItem>[])
        .where((i) => i.merchantId == m.id)
        .toList();
    final subtotal = items.fold<int>(0, (acc, it) => acc + it.priceEtb);
    return subtotal + 80; // rough delivery band
  }

  List<Merchant> _cheaperNearby(CatalogResponse? catalog, List<Merchant> shown) {
    final out = <Merchant>[];
    for (final m in shown) {
      if (m.deliveryZones.isEmpty) continue;
      for (final other in shown) {
        if (other.id == m.id) continue;
        final mine = _roughTotal(m, catalog);
        final theirs = _roughTotal(other, catalog);
        if (theirs < mine - 40) {
          out.add(m);
          break;
        }
      }
    }
    return out;
  }

  Widget _cheaperNearbyChip(BuildContext context, Strings s, Merchant m) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: '${m.nameEn} may be pricier — a similar dish is cheaper nearby',
        child: const ActionChip(
          avatar: Icon(Icons.savings, size: 16),
          label: Text('cheaper nearby'),
          onPressed: null,
        ),
      ),
    );
  }

  Widget _filters(BuildContext context) {
    final s = StringsScope.of(context);
    final catalog = ref.watch(catalogProvider).valueOrNull;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _chip(s.all, !_filter.isActive,
              () => setState(() => _filter = const CatalogFilter())),
          _chip('${s.openNow} ${_filter.openNow ? '· ✓' : ''}', _filter.openNow,
              () => setState(() => _filter = _filter.copyWith(openNow: !_filter.openNow))),
          _chip(s.fasting, _filter.onlyTsomOrVegan,
              () => setState(() => _filter = _filter.copyWith(onlyTsomOrVegan: !_filter.onlyTsomOrVegan))),
          _chip(s.halal, _filter.onlyHalal,
              () => setState(() => _filter = _filter.copyWith(onlyHalal: !_filter.onlyHalal))),
          if (catalog != null) ..._hubChips(context, catalog),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryGold,
        labelStyle: TextStyle(
          color: selected ? AppColors.neutralDark : AppColors.neutralMid,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final s = StringsScope.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: EmptyState(
            icon: Icons.search_off,
            title: s.noResults,
            subtitle: s.tryClearFilters,
          ),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context, Merchant m) {
    final s = StringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            hexColor(m.accent),
            hexColor(m.accent, fallback: AppColors.primaryGold).withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.dailySpecial} · ${s.restaurants}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.neutralDark)),
                const SizedBox(height: 4),
                Text(m.nameEn,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neutralDark, fontSize: 18)),
                const SizedBox(height: 2),
                Text('${m.nameAm} · ${m.sefer}',
                    style: const TextStyle(color: AppColors.neutralDark)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.neutralDark.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
            child: const Text('0% commission',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}