import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/role_dashboards.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// Admin dashboard – live snapshot of orders/GMV/couriers plus the merchant
/// application queue (backed by GET /api/admin/snapshot).
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
      ),
      body: admin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (AdminSnapshot snap) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              KpiRow(
                kpis: [
                  Kpi(label: 'Orders', value: '${snap.ordersToday}'),
                  Kpi(label: 'GMV', value: '${snap.gmvEtb} ETB'),
                  Kpi(label: 'Couriers', value: '${snap.activeCouriers}'),
                  Kpi(label: 'Apps', value: '${snap.merchantApplications.length}'),
                ],
              ),
              const SizedBox(height: 16),
              Text('Merchant applications (${snap.merchantApplications.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              for (final app in snap.merchantApplications)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    leading: const Icon(Icons.storefront, color: AppColors.primaryGold),
                    title: Text(app.businessName),
                    subtitle: Text('${app.ownerName} · ${app.subCity} · ${app.status}'),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Live orders (${snap.liveOrders.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              for (final o in snap.liveOrders.take(10))
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: AppColors.neutralMid),
                    title: Text('#${o.id} · ${o.total} ETB'),
                    subtitle: Text('${o.phone} · ${o.status}'),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Channel: ${snap.channelStatus.provider}'
                  '${snap.channelStatus.missingSecrets.isEmpty ? "" : " · missing: ${snap.channelStatus.missingSecrets.join(", ") }"}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }
}
