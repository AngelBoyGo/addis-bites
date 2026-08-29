import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/role_dashboards.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';
import '../../models/menu.dart';

/// Merchant console (§5.10): live queue with 90s ack countdown + accept/decline/
/// preparing, menu availability toggles (86'ing), menu-photo upload to OCR.
class MerchantShell extends ConsumerStatefulWidget {
  const MerchantShell({super.key});

  @override
  ConsumerState<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends ConsumerState<MerchantShell> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(merchantQueueProvider.notifier).load();
      ref.read(catalogProvider.notifier).load();
      // §5.10: poll the live order queue every 5s and flush buffered offline actions.
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final n = ref.read(merchantQueueProvider.notifier);
        n.load();
        n.flushPending();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _uploadMenuPhoto() async {
    final picker = ImagePicker();
    try {
      final shot = await picker.pickImage(source: ImageSource.camera);
      if (shot == null) return;
      final bytes = await shot.readAsBytes();
      final b64 = base64Encode(bytes);
      await ref.read(merchantQueueProvider.notifier).uploadMenuPhoto(b64);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu photo uploaded → OCR pipeline')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo capture unavailable')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final queue = ref.watch(merchantQueueProvider);
    final catalog = ref.watch(catalogProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.merchantTitle),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          const DemoBadge(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(merchantQueueProvider.notifier).load(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          KpiRow(
            kpis: [
              Kpi(label: s.liveQueue, value: '${queue.valueOrNull?.length ?? 0}'),
              Kpi(label: s.menuAvailability, value: '${catalog?.items.length ?? 0}'),
              Kpi(
                label: s.pendingActions,
                value: '${ref.read(merchantQueueProvider.notifier).pendingActions.length}',
                valueColor: ref.read(merchantQueueProvider.notifier).pendingActions.isNotEmpty
                    ? AppColors.surfaceGround
                    : AppColors.neutralDark,
              ),
            ],
          ),
          if (ref.read(merchantQueueProvider.notifier).pendingActions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceGround.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: AppColors.neutralDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${ref.read(merchantQueueProvider.notifier).pendingActions.length} action(s) queued offline — will flush on reconnect',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          RoleSection(
            title: '${s.liveQueue} (${queue.valueOrNull?.length ?? 0})',
            child: queue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('${s.connectionLost}: $e'),
              data: (entries) => entries.isEmpty
                  ? Text(s.noOffers)
                  : Column(
                      children: [
                        for (final m in entries) _queueCard(context, s, m),
                      ],
                    ),
            ),
          ),
          if (catalog != null && catalog.items.isNotEmpty)
            RoleSection(
              title: s.menuAvailability,
              child: _menuList(context, s, catalog.items),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _uploadMenuPhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(s.uploadMenuPhoto),
          ),
        ],
      ),
    );
  }

  Widget _queueCard(BuildContext context, Strings s, MerchantOrder m) {
    final es = m.ackSecondsLeft;
    final o = m.order;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: es < 30 ? AppColors.surfaceGround.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('#${o.id}', style: Theme.of(context).textTheme.titleSmall),
                ),
                StatusPill(status: o.status.wire),
                const SizedBox(width: 6),
                TagBadge(
                  label: o.paymentMethod == 'chapa' ? s.verified : s.codPending,
                  color: o.paymentMethod == 'chapa' ? AppColors.tsomGreen : AppColors.surfaceGround,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(o.merchantName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final it in o.items)
              Text('${it.qty}× ${it.nameEn} · ${it.price} ETB',
                  style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('📍 ${o.subCity} · ${o.sefer} — ${o.landmarkText}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${s.merchantAck} ', style: Theme.of(context).textTheme.bodySmall),
                CountdownText(seconds: es),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => ref.read(merchantQueueProvider.notifier).action(o.id, 'accept'),
                    child: Text(s.acceptOrder, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(merchantQueueProvider.notifier).action(o.id, 'decline'),
                    child: Text(s.declineOrder),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => ref.read(merchantQueueProvider.notifier).action(o.id, 'preparing'),
              child: Text(s.markPreparing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuList(BuildContext context, Strings s, List<MenuItem> items) {
    return Column(
      children: [
        for (final item in items)
          SwitchListTile(
            value: item.isAvailable,
            title: Text('${item.nameEn} · ${item.priceEtb} ETB'),
            subtitle: Text(item.nameAm, maxLines: 1, overflow: TextOverflow.ellipsis),
            onChanged: (v) {
              ref.read(merchantQueueProvider.notifier).toggleMenu(item.id, v);
              // update local catalog mirror for the demo
              ref.read(catalogProvider.notifier).load();
            },
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}