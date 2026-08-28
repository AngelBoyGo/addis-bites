import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../models/menu.dart';
import '../../models/merchant.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards.dart';
import '../../widgets/savings.dart';
import '../../widgets/shared.dart';

/// Restaurant menu with the communal platter (gebeta) configurator: quantity,
/// injera-roll stepper and spice-level picker per §5.3. Adds to the shared cart.
class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  bool _configuring = false;
  MenuItem? _configuringItem;
  int _qty = 1;
  int _injera = 2;
  int _spice = 1;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    return catalogAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('${StringsScope.of(context).connectionLost} — $e'))),
      data: (catalog) {
        Merchant? merchant;
        for (final m in catalog.merchants) {
          if (m.id == widget.id) {
            merchant = m;
            break;
          }
        }
        if (merchant == null) {
          return Scaffold(body: Center(child: Text(StringsScope.of(context).noResults)));
        }
        final m = merchant;
        final menu = catalog.items.where((i) => i.merchantId == m.id).toList();
        final categories = <String>{};
        for (final i in menu) {
          if (i.category.isNotEmpty) categories.add(i.category);
        }
        final catList = categories.toList();
        catList.sort();

        return Scaffold(
          appBar: AppBar(
            title: Text(m.nameEn),
            leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add_outlined),
                onPressed: () => showShareGebetaModal(context, m.id),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(context, merchant),
              const Divider(height: 1, color: AppColors.cardBorder),
              for (final cat in catList) ...[
                _section(context, cat),
                for (final item in menu.where((i) => i.category == cat).toList())
                  MenuItemTile(item: item, onTap: () => setState(() {
                    _configuring = true;
                    _configuringItem = item;
                    _qty = 1;
                    _injera = item.hasInjeraStepper ? 1 : 0;
                    _spice = item.spiceLevels > 0 ? 1 : 0;
                  })),
              ],
            ],
          ),
          bottomNavigationBar: _configuring ? _sheet(context) : null,
        );
      },
    );
  }

  Widget _header(BuildContext context, Merchant m) {
    final txt = Theme.of(context).textTheme;
    final accent = hexColor(m.accent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 12,
                left: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.nameEn,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22)),
                    Text('${m.nameAm} · ${m.sefer}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (m.isRestaurantOfTheDay)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.neutralDark.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8)),
                    child: const Text('0% commission today', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            const Icon(Icons.star, size: 16, color: AppColors.primaryGold),
            const SizedBox(width: 4),
            Text(m.rating.toStringAsFixed(1), style: txt.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            const Icon(Icons.schedule, size: 15, color: AppColors.neutralMid),
            const SizedBox(width: 4),
            Text('${m.prepMin} min', style: txt.labelSmall),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${m.sefer} · ${m.subCity}',
                  style: txt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            if (m.tsomCertified)
              const TagBadge(label: '🌿 Tsom Certified', color: AppColors.tsomGreen),
            if (m.halalCertified)
              const TagBadge(label: '✓ Halal', color: AppColors.halalTeal),
            if (m.thermal)
              const TagBadge(label: '❄ Thermal Transit Verified', color: AppColors.surfaceGround),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _section(BuildContext context, String title) =>
      Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text(title, style: Theme.of(context).textTheme.titleLarge));

  // ---- platter configurator bottom sheet ----
  Widget _sheet(BuildContext context) {
    final item = _configuringItem!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nameEn, style: Theme.of(context).textTheme.titleLarge),
                    Text(item.nameAm, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(onPressed: () => setState(() => _configuring = false), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 12),
          if (item.isRawMeat)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceGround.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.ac_unit, size: 16, color: AppColors.surfaceGround),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Thermal transit verified · dispatch to thermal-bag couriers.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          _row(context,
              label: StringsScope.of(context).quantity,
              plus: () => setState(() {
                if (_qty < 20) _qty++;
              }),
              minus: () => setState(() {
                if (_qty > 1) _qty--;
              }),
              display: '$_qty'),
          if (item.hasInjeraStepper) ...[
            const SizedBox(height: 8),
            _row(context,
                label: StringsScope.of(context).injeraRolls,
                plus: () => setState(() {
                  if (_injera < 24) _injera += 2;
                }),
                minus: () => setState(() {
                  if (_injera > 1) _injera -= 2;
                }),
                display: '$_injera'),
          ],
          if (item.spiceLevels > 0) ...[
            const SizedBox(height: 8),
            _spicePicker(context, item.spiceLevels),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              ref.read(cartProvider.notifier).add(item, qty: _qty, injeraCount: _injera, spice: _spice);
              setState(() => _configuring = false);
            },
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Align(
                alignment: Alignment.center,
                child: Text('${StringsScope.of(context).addFor} ${item.priceEtb * _qty} ETB',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, {required String label, required VoidCallback minus, required VoidCallback plus, required String display}) {
    final txt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: txt.titleSmall)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outlined, color: AppColors.neutralDark, size: 20),
          onPressed: minus,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 46,
          child: Text(display, style: txt.titleMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppColors.neutralDark, size: 20),
          onPressed: plus,
        ),
      ],
    );
  }

  Widget _spicePicker(BuildContext context, int levels) {
    final txt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(StringsScope.of(context).spiceLevel, style: txt.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < levels; i++)
              ChoiceChip(
                label: Text(_spiceLabel(i)),
                selected: _spice == i,
                onSelected: (_) => setState(() => _spice = i),
              ),
          ],
        ),
      ],
    );
  }

  String _spiceLabel(int lvl) {
    if (lvl == 3) return 'Extra Hot';
    if (lvl == 2) return 'Berbere Hot';
    if (lvl == 1) return 'Medium';
    return 'Mild';
  }
}