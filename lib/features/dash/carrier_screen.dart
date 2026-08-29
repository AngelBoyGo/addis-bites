import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/driver.dart';
import '../../models/role_dashboards.dart';
import '../../providers/role_providers.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// Foot-carrier track (§5.9): phone-only signup, 1-minute orientation checklist,
/// "Start earning today" activation (1.5 km radius + bonuses), earnings ledger.
class CarrierScreen extends ConsumerStatefulWidget {
  const CarrierScreen({super.key, this.initialStep = 0});
  final int initialStep;

  @override
  ConsumerState<CarrierScreen> createState() => _CarrierScreenState();
}

class _CarrierScreenState extends ConsumerState<CarrierScreen> {
  late int _step;
  bool _a = false;
  bool _b = false;
  bool _c = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  Future<void> _start() async {
    final session = ref.read(sessionProvider);
    final phone = session?.profile.phone ?? '+251911000001';
    await ref.read(footProvider.notifier).start(phone);
    setState(() => _step = 1);
  }

  Future<void> _orientation() async {
    await ref.read(footProvider.notifier).orientation();
    setState(() => _step = 2);
  }

  Future<void> _earnToday() async {
    await ref.read(footProvider.notifier).earnToday();
    setState(() => _step = 3);
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final foot = ref.watch(footProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.footCarrierTitle),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: foot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (f) {
          final Widget body;
          if (_step == 0) {
            body = _signup(context, s);
          } else if (_step == 1) {
            body = _checklist(context, s);
          } else if (_step == 2) {
            body = _activation(context, s);
          } else {
            body = _earnings(context, s, f);
          }
          return body;
        },
      ),
    );
  }

  Widget _signup(BuildContext context, Strings s) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.footCarrierTitle} — 1, 2, 3', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(s.carrierWelcome, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'No email. No documents. Phone only. You pick up deliveries within 1.5 km and keep 95% of every fee. (+50 ETB signup, +100 ETB first trip.)',
            style: TextStyle(color: AppColors.neutralMid),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _start,
            child: const Text('SIGN UP WITH PHONE ONLY', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Text(s.carrierKeep95, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tsomGreen)),
        ],
      ),
    );
  }

  Widget _checklist(BuildContext context, Strings s) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.orientationChecklist, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _a,
            title: const Text('Count money back correctly — give full change.'),
            onChanged: (v) => setState(() => _a = v ?? false),
          ),
          CheckboxListTile(
            value: _b,
            title: const Text('Always confirm the order ID and landmark before leaving.'),
            onChanged: (v) => setState(() => _b = v ?? false),
          ),
          CheckboxListTile(
            value: _c,
            title: const Text('Never accept cash beyond the locked total.'),
            onChanged: (v) => setState(() => _c = v ?? false),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_a && _b && _c) ? _orientation : null,
            child: const Text('COMPLETE ORIENTATION', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _activation(BuildContext context, Strings s) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.carrierWelcome, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text('One tap and the system assigns your working radius (1.5 km). Bonuses are created immediately.', style: TextStyle(color: AppColors.neutralMid)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _earnToday,
            child: const Text('START EARNING TODAY', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _earnings(BuildContext context, Strings s, FootStatus f) {
    if (_step < 3) return const SizedBox();
    final earnings = ref.watch(footEarningsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.carrierEarnings, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                earnings.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('${s.connectionLost}: $e'),
                  data: (e) {
                    final balance = e.walletBalanceEtb;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$balance ETB', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900), key: ValueKey('carrier-balance')),
                        const SizedBox(height: 8),
                        KpiRow(
                          kpis: [
                            Kpi(label: s.balance, value: '$balance'),
                            Kpi(label: s.radius, value: '${f.radiusKm} km'),
                            Kpi(label: f.earningToday ? s.earningToday : s.inactive, value: f.earningToday ? '✓' : '○'),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        RoleSection(
          title: s.bonusesLedger,
          child: earnings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('${s.connectionLost}: $e'),
            data: (final e) => e.bonuses.isEmpty
                ? Text(s.noOffers)
                : Column(children: [
                    for (final b in e.bonuses)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(b.status == 'released' ? Icons.celebration : Icons.lock_clock),
                        title: Text('${b.kind} +${b.amountEtb} ETB'),
                        subtitle: Text('${b.status} · ${b.deliveredEtb} delivered'),
                      ),
                  ]),
          ),
        ),
        RoleSection(
          title: s.tripHistory,
          child: earnings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const SizedBox(),
            data: (final e) => e.trips.isEmpty
                ? Text(s.noOffers)
                : Column(children: [
                    for (final t in e.trips)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delivery_dining),
                        title: Text('${t.id} · ${t.total} ETB'),
                        subtitle: Text('${t.status.wire} · ${t.subCity}'),
                      ),
                  ]),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            // §5.9: mark delivered with POD — delivered stays reachable and the
            // first-trip bonus (+100 ETB) releases once this is recorded.
            await ref.read(driverDashboardProvider.notifier).submitPOD(
              const ProofOfDelivery(orderId: 'ord-demo-1', photoB64: 'demo', pin: '0000'),
            );
            ref.invalidate(footEarningsProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delivered — first-trip bonus released (+100 ETB)')),
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark delivered'),
        ),
      ],
    );
  }
}