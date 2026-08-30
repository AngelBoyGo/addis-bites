import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/driver.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';
import '../../widgets/tier_card.dart';

/// Driver dashboard (§5.8): vehicle tabs with economics, wallet + COD float,
/// live offers with per-trip economics, and proof-of-delivery (photo + PIN).
class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key});

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  DeliveryVehicle _tab = DeliveryVehicle.motorbike;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(driverDashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final dash = ref.watch(driverDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.driverTitle),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: dash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (d) =>
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Align(alignment: Alignment.centerRight, child: DemoBadge()),
                const SizedBox(height: 4),
                _vehicleTabs(context, s, d),
                const SizedBox(height: 12),
                _economyCard(context, s, d),
                const SizedBox(height: 16),
                _walletCard(context, s, d),
                const SizedBox(height: 12),
                TierCard(level: 2, completedDeliveries: d.wallet.balanceEtb ~/ 20),
                if (d.curfewActive) _curfewBanner(context, s),
                RoleSection(title: s.liveOffers, child: _offers(context, s, d)),
                RoleSection(title: s.activeOrder, child: _activeOrderCard(context, s, d)),
              ],
            ),
      ),
    );
  }

  Widget _vehicleTabs(BuildContext context, Strings s, DriverDashboard d) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final econ in d.econByVehicle)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(econ.label),
                selected: _tab == econ.vehicle,
                onSelected: (_) => setState(() => _tab = econ.vehicle),
                selectedColor: AppColors.primaryGold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _economyCard(BuildContext context, Strings s, DriverDashboard d) {
    final econ = d.econByVehicle.where((e) => e.vehicle == _tab).firstOrNull;
    if (econ == null) return const SizedBox();
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${econ.label} · ${s.economicsCard}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            KvRow(k: s.costPerKm, v: '${econ.costPerKm} ETB/km'),
            KvRow(k: s.effectiveRange, v: '${econ.rangeKm} km'),
            KvRow(k: s.keeperShare, v: '${econ.keeperSharePct}%'),
          ],
        ),
      ),
    );
  }

  Widget _walletCard(BuildContext context, Strings s, DriverDashboard d) {
    final w = d.wallet;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.walletCard, style: Theme.of(context).textTheme.titleMedium)),
                TagBadge(label: s.balance, color: AppColors.primaryGold),
              ],
            ),
            const SizedBox(height: 8),
            KpiRow(
              kpis: [
                Kpi(label: s.balance, value: '${w.balanceEtb}'),
                Kpi(
                  label: s.codFloat,
                  value: '${w.floatEtb}/${w.floatCap}',
                  valueColor: w.codBlocked ? AppColors.dangerRed : AppColors.neutralDark,
                ),
                Kpi(label: s.payoutDue, value: '${w.payoutDue}'),
              ],
            ),
            if (w.codBlocked)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s.codBlockedNote,
                    style: const TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _curfewBanner(BuildContext context, Strings s) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGround.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight, color: AppColors.neutralDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(s.curfewNote,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _offers(BuildContext context, Strings s, DriverDashboard d) {
    if (d.offers.isEmpty) return Text(s.noOffers, style: Theme.of(context).textTheme.bodyMedium);
    return Column(
      children: [
        for (final offer in d.offers) Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${offer.merchant} · ${offer.sefer}',
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    if (offer.footEligible) const TagBadge(label: 'Foot OK', color: AppColors.tsomGreen),
                  ],
                ),
                const SizedBox(height: 6),
                KvRow(k: '${offer.distanceKm} km · ETA ${offer.etaMin} min', v: '${offer.grossFee} ETB gross'),
                KvRow(k: s.keeperShare, v: '${offer.keeperShare} ETB'),
                KvRow(k: s.fuelBurn, v: '-${offer.fuelCost} ETB'),
                if (offer.subsidy > 0)
                  TagBadge(label: '${s.platformSubsidy} ${offer.subsidy} ETB', color: AppColors.surfaceGround),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text('${s.netEarnings}: ${offer.net + offer.tipsEtb} ETB',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neutralDark)),
                    ),
                    const SizedBox(width: 4),
                    Text('+${offer.tipsEtb} tips',
                        style: const TextStyle(fontSize: 12, color: AppColors.neutralMid)),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    // §5.8: foot-eligible offers route into the foot-carrier track.
                    if (offer.footEligible) {
                      if (mounted) context.go('/carrier');
                      return;
                    }
                    await ref.read(driverDashboardProvider.notifier).accept(offer.orderId);
                  },
                  child: Text(s.accept,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeOrderCard(BuildContext context, Strings s, DriverDashboard d) {
    // §11.3 Price Lock mirrored on the driver side: render only when there is a
    // real active pickup, and collect the locked total the customer paid —
    // never a hardcoded demo constant.
    final collect = d.activeOrderTotalEtb;
    final hasActive = collect != null && collect > 0;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasActive ? s.activeOrder : s.noActiveOrder,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (hasActive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryGold),
                ),
                child: Text(
                  s.collectExactly(collect),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.neutralDark),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  _showPODSheet(context, s);
                },
                icon: const Icon(Icons.photo_camera),
                label: Text(s.proofOfDelivery),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPODSheet(BuildContext context, Strings s) {
    int pin = 0;
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
              Text(s.proofOfDelivery, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Photo: tap camera · PIN: 4 digits', style: TextStyle(color: AppColors.neutralMid)),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Customer PIN'),
                onChanged: (v) => pin = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    // §5.8 POD: delivered is unreachable without a POD photo + PIN.
                    String b64 = 'demo';
                    try {
                      final shot = await ImagePicker().pickImage(source: ImageSource.camera);
                      if (shot != null) b64 = base64Encode(await shot.readAsBytes());
                    } catch (_) {}
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    await ref.read(driverDashboardProvider.notifier).submitPOD(
                      ProofOfDelivery(orderId: 'ord-demo', photoB64: b64, pin: '$pin'),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delivered — POD recorded')),
                      );
                    }
                  },
                  child: const Text('TAKE PHOTO & MARK DELIVERED', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}