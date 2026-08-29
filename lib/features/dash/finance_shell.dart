import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/backend_services.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// Finance console (tech-spec §3.5): payout batches (two-person release),
/// double-entry ledger (imbalance must be 0), reconciliation, take-rate.
class FinanceShell extends ConsumerStatefulWidget {
  const FinanceShell({super.key});

  @override
  ConsumerState<FinanceShell> createState() => _FinanceShellState();
}

class _FinanceShellState extends ConsumerState<FinanceShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(financeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final dash = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.financeConsole),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [IconButton(onPressed: () => ref.read(financeProvider.notifier).load(), icon: const Icon(Icons.refresh))],
      ),
      body: dash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _kpis(context, d),
            RoleSection(title: s.payoutBatches, child: _batches(context, s, d.batches)),
            RoleSection(title: s.ledger, child: _ledger(context, s, d.ledger)),
          ],
        ),
      ),
    );
  }

  Widget _kpis(BuildContext context, FinanceDashboard d) {
    return KpiRow(
      kpis: [
        Kpi(label: 'Ledger Δ', value: '${d.ledgerImbalance}'),
        Kpi(label: 'Unreconciled', value: '${d.unreconciled24h}'),
        Kpi(label: 'Payout failures', value: '${d.payoutFailureCount}'),
        Kpi(label: 'Take rate', value: '${d.takeRateNetPromos}%'),
      ],
    );
  }

  

  Widget _batches(BuildContext context, Strings s, List<PayoutBatch> batches) {
    if (batches.isEmpty) return Text(s.noOffers);
    return Column(children: [
      for (final b in batches)
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.account_balance, color: AppColors.primaryGold),
            title: Text('${b.id} · ${b.method} · ${b.totalEtb} ETB (${b.count})'),
            subtitle: Row(children: [StatusPill(status: b.status), const SizedBox(width: 6), Expanded(child: Text('10:00/13:00/18:00 EAT · two-person release'))]),
            trailing: b.status == 'pending'
                ? TextButton(
                    onPressed: () => ref.read(financeProvider.notifier).runPayoutBatch(b.id),
                    child: Text('Run', style: const TextStyle(color: AppColors.tsomGreen, fontWeight: FontWeight.w700)),
                  )
                : null,
          ),
        ),
    ]);
  }

  Widget _ledger(BuildContext context, Strings s, List<LedgerEntry> ledger) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final e in ledger)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(child: Text(e.account, style: Theme.of(context).textTheme.bodySmall)),
                  Text(e.signed >= 0 ? '+${e.signed}' : '${e.signed}',
                      style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.w700,
                        color: e.signed >= 0 ? AppColors.tsomGreen : AppColors.dangerRed,
                      )),
                ]),
              ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Expanded(child: Text(s.ledgerZeroNote, style: Theme.of(context).textTheme.bodySmall)),
                TextButton(onPressed: () => ref.read(financeProvider.notifier).reconcile(), child: Text(s.reconcileNow)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}