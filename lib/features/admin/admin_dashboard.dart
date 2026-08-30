import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/role_dashboards.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';

/// Admin dashboard (A§§) — quick overview of key metrics and pending items.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final admin = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: s.alerts,
            onPressed: () {
              // TODO: navigate to alerts / dispute queue
            },
          ),
        ],
      ),
      body: admin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (adminSnapshot) {
          // adminSnapshot: ordersToday, gmvEtb, activeCouriers,
          // merchantApplications, liveOrders, config, etc.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Key metrics ──────────────────────────────────────
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.quickStats, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: KpiRow(
                                kpis: [
                                  Kpi(label: s.ordersToday, value: '${adminSnapshot.ordersToday}'),
                                  Kpi(label: s.gmv, value: '${adminSnapshot.gmvEtb} ETB'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: KpiRow(
                                kpis: [
                                  Kpi(label: s.activeCouriers, value: '${adminSnapshot.activeCouriers}'),
                                  Kpi(label: s.merchantApps, value: '${adminSnapshot.merchantApplications.length}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Pending merchant applications ────────────────────
                if (adminSnapshot.merchantApplications.isNotEmpty) ...[
                  Text(
                    s.pendingMerchantApps,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...adminSnapshot.merchantApplications.map((app) => _MerchantAppTile(app)),
                  const SizedBox(height: 24),
                ]

                // ── Live orders snapshot ─────────────────────────────
                if (adminSnapshot.liveOrders.isNotEmpty) ...[
                  Text(
                    s.liveOrders,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...adminSnapshot.liveOrders.map((o) => _OrderSummary(o)),
                  const SizedBox(height: 24),
                ]

                // ── Config / channel status ──────────────────────────
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.channelConfig, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Provider: ${adminSnapshot.channelStatus.provider}'),
                        if (adminSnapshot.channelStatus.missingSecrets.isNotEmpty)
                          Text('Missing secrets: ${adminSnapshot.channelStatus.missingSecrets.join(', ')}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MerchantAppTile extends ConsumerWidget {
  final MerchantApplication app;
  const _MerchantAppTile(this.app);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = StringsScope.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${app.businessName} (${app.tin})'),
        subtitle: Text('${app.subCity} • ${app.status}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => ref.read(adminProvider.notifier).orderAction(app.id, 'approve'),
              child: const Text('Approve'),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () => ref.read(adminProvider.notifier).orderAction(app.id, 'reject'),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  final Order order;
  const _OrderSummary(this.order);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = StringsScope.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Order #${order.id} • ${order.total} ETB'),
        subtitle: Text('${order.phone} • ${order.status.name}'),
        trailing: OutlinedButton(
          onPressed: () => context.go('/order/${order.id}'),
          child: const Text('View'),
        ),
      ),
    );
  }
}