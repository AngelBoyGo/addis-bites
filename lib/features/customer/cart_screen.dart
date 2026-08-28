import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../core/pricing.dart';
import '../../i18n/strings.dart';
import '../../models/cart.dart';
import '../../models/catalog.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/orders_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/savings.dart';

/// The Gebeta (shared platter) cart: line steppers, delivery-band selector,
/// rain surge, buna-run tier, transparent fee breakdown.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final cart = ref.watch(cartProvider);
    final cfg = ref.watch(catalogProvider).valueOrNull?.config;

    if (cart.isEmpty || cfg == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${s.cart} · ገበታ'),
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        ),
        body: Center(
          child: Text(s.emptyCart, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
    }

    final subtotal = cart.subtotal;
    final bandFee = Pricing.deliveryFee(cfg, cart.band);
    final buna = Pricing.bunaRun(cfg, cart);
    final delivery = buna ?? bandFee;
    final surge = Pricing.surge(cfg);
    final total = subtotal + delivery + cfg.serviceFee + surge;
    final savings = Pricing.footSavings(cfg, cart);

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.cart} · ገበታ'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => showShareGebetaModal(context, 'lebgeb'),
          ),
          IconButton(
            icon: const Icon(Icons.redeem),
            onPressed: () => showGurshaModal(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('የገበታ ትዕዛዝ · Shared Platter', style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final line in cart.lines) _line(context, line),
          const SizedBox(height: 12),
          _savingsCard(context, s, cart),
          _bands(context, s, cfg, cart.band),
          if (buna != null) _bunaCard(context),
          const SizedBox(height: 12),
          _feeBreakdown(context, subtotal, delivery, surge, cfg, total, savings),
        ],
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () => context.push('/checkout'),
            child: Text('${s.placeOrder} · $total ETB',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, CartLine line) {
    final txt = Theme.of(context).textTheme;
    final s = StringsScope.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.item.nameEn, style: txt.titleSmall),
                      Text(line.item.nameAm, style: txt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text('${line.lineTotal} ETB',
                    style: const TextStyle(color: AppColors.secondaryClay, fontWeight: FontWeight.w700)),
              ],
            ),
            Row(
              children: [
                if (line.injeraCount > 0) _chip(context, '${s.injera} × ${line.injeraCount}'),
                if (line.spice > 0) _chip(context, 'spice ${line.spice}'),
                const Spacer(),
                IconButton(icon: const Icon(Icons.remove_circle_outlined, size: 18),
                    onPressed: () => ref.read(cartProvider).setQty(line.key, line.qty - 1)),
                Text('${line.qty}', style: txt.titleMedium),
                IconButton(icon: const Icon(Icons.add_circle, size: 18),
                    onPressed: () => ref.read(cartProvider).setQty(line.key, line.qty + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) =>
      Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutralDark, fontWeight: FontWeight.w600)),
      );

  Widget _savingsCard(BuildContext context, Strings s, Cart cart) {
    final deliveries = ref.watch(ordersProvider).length;
    // Per-person platter math (§6 #16): sharing is visibly cheaper than solo.
    final perHead = cart.lines.length > 0 ? cart.subtotal / cart.lines.length : cart.subtotal;
    final stampsToFree = Loyalty.stampsToNext(deliveries);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_border, size: 16, color: AppColors.primaryGold),
                const SizedBox(width: 6),
                Text('${s.loyaltyStamps}: ${deliveries % 10}/10 → ${stampsToFree} to a free delivery',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.groups, size: 16, color: AppColors.tsomGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${s.perHead}: ${perHead.round()} ETB/head when you share the ${s.cart}',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bands(BuildContext context, Strings s, AppConfig cfg, DeliveryBand current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, s.deliveryBand),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _bandChip(context, s, cfg, current, DeliveryBand.under2, '0–2 km · ${Pricing.deliveryFee(cfg, DeliveryBand.under2)} ETB'),
              _bandChip(context, s, cfg, current, DeliveryBand.mid5, '2–5 km · ${Pricing.deliveryFee(cfg, DeliveryBand.mid5)} ETB'),
              _bandChip(context, s, cfg, current, DeliveryBand.far8, '5–8 km · ${Pricing.deliveryFee(cfg, DeliveryBand.far8)} ETB'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bandChip(BuildContext context, Strings s, AppConfig cfg, DeliveryBand current, DeliveryBand band, String label) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: band == current,
          onSelected: (_) => ref.read(cartProvider.notifier).setBand(band),
          selectedColor: AppColors.primaryGold,
        ),
      );

  Widget _bunaCard(BuildContext context) {
    final s = StringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGround.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceGround),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_cafe, color: AppColors.neutralDark),
          const SizedBox(width: 8),
          Expanded(child: Text(s.coffeeRun, style: Theme.of(context).textTheme.titleSmall)),
        ],
      ),
    );
  }

  Widget _feeBreakdown(BuildContext context, int subtotal, int delivery, int surge,
      AppConfig cfg, int total, int savings) {
    final s = StringsScope.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _feeRow(context, s.subtotal, '$subtotal ETB'),
            _feeRow(context, s.deliveryFee, '$delivery ETB'),
            if (surge > 0) ...[
              Row(children: [
                const Icon(Icons.cloudy_snowing, size: 16, color: AppColors.neutralMid),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('${s.surge} — Kiremt (rainy season): extended ETA, +40 ETB',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ]),
              _feeRow(context, '', '+$surge ETB'),
            ],
            _feeRow(context, s.serviceFee, '${cfg.serviceFee} ETB'),
            if (savings > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Text('${s.deliveredOnFoot} — ${s.youSave} $total ETB',
                    style: const TextStyle(color: AppColors.tsomGreen, fontWeight: FontWeight.w700)),
              ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Row(
              children: [
                Expanded(child: Text(s.whyThisFee, style: Theme.of(context).textTheme.bodySmall)),
                const Spacer(),
                Text('${s.total} · $total ETB', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeRow(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );

  Widget _sectionTitle(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      );
}