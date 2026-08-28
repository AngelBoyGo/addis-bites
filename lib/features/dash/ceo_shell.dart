import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/role_dashboards.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// CEO dashboard (§5.12): KPI tiles, inflation engine card, unit economics
/// table, foot-carrier network, disputes queue, promotions manager.
class CeoShell extends ConsumerStatefulWidget {
  const CeoShell({super.key});

  @override
  ConsumerState<CeoShell> createState() => _CeoShellState();
}

class _CeoShellState extends ConsumerState<CeoShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(ceoProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final ceo = ref.watch(ceoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.ceoTitle),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          const DemoBadge(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(ceoProvider.notifier).load()),
        ],
      ),
      body: ceo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _kpiGrid(context, s, d),
            RoleSection(title: s.inflationEngine, child: _inflationCard(context, s, d)),
            RoleSection(title: s.unitEconomics, child: _unitEconomics(context, s)),
            RoleSection(title: s.footNetwork, child: _footNetwork(context, s)),
            RoleSection(title: s.disputes, child: _disputes(context, s, d)),
            RoleSection(title: s.promotions, child: _promos(context, s, d)),
          ],
        ),
      ),
    );
  }

  Widget _kpiGrid(BuildContext context, Strings s, CeoDashboard d) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _tile(context, s.gmv, '${d.gmvEtb} ETB'),
        _tile(context, s.ordersToday, '${d.orders}'),
        _tile(context, 'COD share', '${d.codSharePct}%'),
        _tile(context, s.activeCouriers, '${d.drivers}'),
        _tile(context, 'Customers', '${d.customers}'),
        _tile(context, 'Fee x', '${d.feeMultiplier}x'),
      ],
    );
  }

  Widget _tile(BuildContext context, String label, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.neutralDark)),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _inflationCard(BuildContext context, Strings s, CeoDashboard d) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KvRow(k: 'Annual inflation', v: '${d.inflationPct}%'),
            KvRow(k: 'Fee multiplier', v: '${d.feeMultiplier}x'),
            const KvRow(k: 'Fuel ref', v: '167.5 ETB/L'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shield, color: AppColors.tsomGreen),
                const SizedBox(width: 8),
                Expanded(child: Text(s.subsidyGuarantee, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitEconomics(BuildContext context, Strings s) {
    const rows = [
      ['Foot', '45', '43', '0', '15'],
      ['Bicycle', '80', '64', '0', '20'],
      ['Motorbike', '80', '64', '35', '12'],
      ['Car', '80', '64', '72', '18'],
    ];
    DataRow r(List<String> c) => DataRow(cells: [
          for (final v in c) DataCell(Text(v)),
        ]);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Vehicle')),
            DataColumn(label: Text('Fee')),
            DataColumn(label: Text('Keep')),
            DataColumn(label: Text('Fuel')),
            DataColumn(label: Text('ETA')),
          ],
          rows: [for (final c in rows) r(c)],
        ),
      ),
    );
  }

  Widget _footNetwork(BuildContext context, Strings s) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KvRow(k: 'Signups', v: '132'),
                  KvRow(k: 'Earning today', v: '48'),
                  KvRow(k: 'First trips done', v: '61'),
                  KvRow(k: 'Bonuses due', v: '3,200 ETB'),
                ],
              ),
            ),
            FilledButton(
              onPressed: () {},
              child: Text(s.recruits, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disputes(BuildContext context, Strings s, CeoDashboard d) {
    if (d.disputes.isEmpty) return Text(s.noOffers);
    return Column(
      children: [
        for (final ds in d.disputes)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${ds.id} · ${ds.orderId}', style: Theme.of(context).textTheme.titleSmall),
                        Text(ds.reason, style: Theme.of(context).textTheme.bodyMedium),
                        TagBadge(label: ds.status, color: ds.status == 'resolved' ? AppColors.tsomGreen : AppColors.surfaceGround),
                      ],
                    ),
                  ),
                  if (ds.status != 'resolved')
                    TextButton(
                      onPressed: () => ref.read(ceoProvider.notifier).resolveDispute(ds.id),
                      child: Text(s.resolve, style: const TextStyle(color: AppColors.tsomGreen)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _promos(BuildContext context, Strings s, CeoDashboard d) {
    return Column(
      children: [
        for (final p in d.promotions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${p.label} · −${p.discountPct}% · ${p.uses}/${p.maxUses}',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _newPromo(context, s),
          icon: const Icon(Icons.add),
          label: const Text('New promo'),
        ),
      ],
    );
  }

  void _newPromo(BuildContext context, Strings s) {
    final label = TextEditingController();
    final pct = TextEditingController(text: '10');
    final maxUses = TextEditingController(text: '100');
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
            TextField(controller: pct, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount %')),
            TextField(controller: maxUses, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max uses')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                ref.read(ceoProvider.notifier).createPromo(
                    label.text.trim(), int.tryParse(pct.text) ?? 10, int.tryParse(maxUses.text) ?? 100);
                Navigator.of(ctx).pop();
              },
              child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}