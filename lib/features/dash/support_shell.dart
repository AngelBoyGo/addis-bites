import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/backend_services.dart';
import '../../models/role_dashboards.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// Support console (tech-spec §3.6): misconduct reports with validate/reject,
/// the strike ledger, refund queue, and disputes — RBAC-gated by role.
class SupportShell extends ConsumerStatefulWidget {
  const SupportShell({super.key});

  @override
  ConsumerState<SupportShell> createState() => _SupportShellState();
}

class _SupportShellState extends ConsumerState<SupportShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(supportProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final dash = ref.watch(supportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.supportConsole),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [IconButton(onPressed: () => ref.read(supportProvider.notifier).load(), icon: const Icon(Icons.refresh))],
      ),
      body: dash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _kpis(context, d),
            RoleSection(title: s.misconductReports, child: _reports(context, s, d.reports)),
            RoleSection(title: s.strikeLedger, child: _strikes(context, s, d.strikes)),
            RoleSection(title: s.refundQueue, child: _refunds(context, s, d.refunds)),
            RoleSection(title: s.disputes, child: _disputes(context, s, d.disputes)),
          ],
        ),
      ),
    );
  }

  Widget _kpis(BuildContext context, SupportDashboard d) {
    return Row(
      children: [
        _kpi(context, 'Open reports', '${d.reports.where((r) => r.status == 'open').length}'),
        _kpi(context, 'Strikes', '${d.strikes.length}'),
        _kpi(context, 'Refunds', '${d.refunds.length}'),
        _kpi(context, '1st resp', '${d.firstResponseMin} min'),
      ],
    );
  }

  Widget _kpi(BuildContext context, String label, String value) => Expanded(
    child: Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.neutralDark)),
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
    ),
  );

  Widget _reports(BuildContext context, Strings s, List<MisconductReport> reports) {
    if (reports.isEmpty) return Text(s.noOffers);
    return Column(children: [
      for (final r in reports)
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.id} · ${r.category} · ${r.status}',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text('${r.reporterType} → ${r.subjectType} ${r.subjectId} · ${r.orderId}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
                if (r.status == 'open') ...[
                  IconButton(
                    onPressed: () => ref.read(supportProvider.notifier).validateReport(r.id, true),
                    icon: const Icon(Icons.verified, color: AppColors.tsomGreen),
                    tooltip: s.validate,
                  ),
                  IconButton(
                    onPressed: () => ref.read(supportProvider.notifier).validateReport(r.id, false),
                    icon: const Icon(Icons.close, color: AppColors.dangerRed),
                    tooltip: s.reject,
                  ),
                ],
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _strikes(BuildContext context, Strings s, List<StrikeRecord> strikes) {
    if (strikes.isEmpty) return Text(s.noOffers);
    return Column(children: [
      for (final st in strikes)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            const Icon(Icons.gavel, color: AppColors.surfaceGround, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('${st.subjectType} ${st.subjectId}: ${st.level.label}')),
          ]),
        ),
    ]);
  }

  Widget _refunds(BuildContext context, Strings s, List<RefundRecord> refunds) {
    if (refunds.isEmpty) return Text(s.noOffers);
    return Column(children: [
      for (final r in refunds)
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${r.id} · ${r.orderId} · ${r.amountEtb} ETB · ${r.status}'),
            subtitle: Text('Admin approval required'),
            trailing: r.status == 'requested'
                ? TextButton(
                    onPressed: () => ref.read(supportProvider.notifier).approveRefund(r.id),
                    child: Text(s.approve, style: const TextStyle(color: AppColors.tsomGreen)),
                  )
                : null,
          ),
        ),
    ]);
  }

  Widget _disputes(BuildContext context, Strings s, List<Dispute> disputes) {
    if (disputes.isEmpty) return Text(s.noOffers);
    return Column(children: [
      for (final d in disputes)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${d.id} · ${d.orderId} · ${d.reason}'),
          subtitle: Text(d.status),
          leading: const Icon(Icons.support_agent, color: AppColors.primaryGold),
        ),
    ]);
  }
}