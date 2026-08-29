import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/catalog.dart';
import '../../models/order.dart';
import '../../models/role_dashboards.dart';
import '../../providers/role_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// Admin panel (§5.11): KPIs, live orders with actions, pricing editor,
/// platform flags, foot funnel, merchant applications, OCR queue, OTP log,
/// channel provider status. All pricing changeable without redeploy.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(adminProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final snap = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminTitle),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          const DemoBadge(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(adminProvider.notifier).load()),
        ],
      ),
      body: snap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${s.connectionLost}: $e')),
        data: (a) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _kpis(context, s, a),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/field'),
              icon: const Icon(Icons.travel_explore),
              label: const Text('Field Agent mode · የመስክ ወኪል'),
            ),
            RoleSection(title: s.liveOrders, child: _orders(context, s, a.liveOrders)),
            RoleSection(title: s.footFunnel, child: _footFunnel(context, s)),
            RoleSection(title: s.pricingEditor, child: _pricingEditor(context, s, a.config)),
            RoleSection(title: s.platformFlags, child: _flags(context, s, a.config)),
            RoleSection(title: s.merchantApplications, child: _applications(context, s, a.merchantApplications)),
            RoleSection(title: s.ocrQueue, child: _ocr(context, s, a.ocrQueue)),
            RoleSection(title: s.otpLog, child: _otp(context, s, a.otpLog)),
            RoleSection(title: s.providerStatus, child: _channel(context, s, a.channelStatus)),
          ],
        ),
      ),
    );
  }

  Widget _kpis(BuildContext context, Strings s, AdminSnapshot a) {
    return KpiRow(
      kpis: [
        Kpi(label: s.ordersToday, value: '${a.ordersToday}'),
        Kpi(label: s.gmv, value: '${a.gmvEtb} ETB'),
        Kpi(label: s.activeCouriers, value: '${a.activeCouriers}'),
      ],
    );
  }

  Widget _orders(BuildContext context, Strings s, List<Order> orders) {
    if (orders.isEmpty) return Text(s.noOffers);
    return Column(
      children: [
        for (final o in orders)
          Card(
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
                        child: Text('#${o.id} · ${o.merchantName}',
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      TagBadge(label: o.paymentMethod, color: AppColors.primaryGold),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${o.items.length} items · ${o.total} ETB', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(label: Text(s.deliver), onPressed: () => ref.read(adminProvider.notifier).orderAction(o.id, 'deliver')),
                      ActionChip(label: Text(s.markPreparing), onPressed: () => ref.read(adminProvider.notifier).orderAction(o.id, 'preparing')),
                      ActionChip(label: Text(s.cancel), onPressed: () => ref.read(adminProvider.notifier).orderAction(o.id, 'cancel')),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _pricingEditor(BuildContext context, Strings s, AppConfig cfg) {
    final fee2 = TextEditingController(text: '${cfg.deliveryFee2km}');
    final fee5 = TextEditingController(text: '${cfg.deliveryFee5km}');
    final fee8 = TextEditingController(text: '${cfg.deliveryFee8km}');
    final service = TextEditingController(text: '${cfg.serviceFee}');
    final surge = TextEditingController(text: '${cfg.rainSurge}');
    final buna = TextEditingController(text: '${cfg.bunaRunFee}');
    int read(TextEditingController c) => int.tryParse(c.text) ?? 0;

    AppConfig build() => cfg.copyWith(
      serviceFee: read(service),
      deliveryFee2km: read(fee2),
      deliveryFee5km: read(fee5),
      deliveryFee8km: read(fee8),
      rainSurge: read(surge),
      bunaRunFee: read(buna),
    );

    Future<void> save() async {
      await ref.read(adminProvider.notifier).saveConfig(build());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing saved · ተመዝግቧል')));
      }
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _feeField(context, '0–2 km', fee2, onBlur: save),
            _feeField(context, '2–5 km', fee5, onBlur: save),
            _feeField(context, '5–8 km', fee8, onBlur: save),
            _feeField(context, s.serviceFee, service, onBlur: save),
            _feeField(context, s.surge, surge, onBlur: save),
            _feeField(context, s.coffeeRun, buna, onBlur: save),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: save, child: const Text('SAVE PRICING', style: TextStyle(fontWeight: FontWeight.w700))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeField(BuildContext context, String label, TextEditingController c,
      {VoidCallback? onBlur}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        onEditingComplete: onBlur,
        onSubmitted: (_) => onBlur?.call(),
        decoration: InputDecoration(labelText: '$label · ETB', isDense: true),
      ),
    );
  }

  Widget _flags(BuildContext context, Strings s, AppConfig cfg) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            SwitchListTile(
              value: cfg.rainMode,
              title: Text(s.rainMode),
              subtitle: const Text('+40 ETB surge · car/motorbike preference'),
              onChanged: (v) => _saveFlag(ctx: context, cfg: cfg, rainMode: v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: cfg.fastingOverride,
              title: Text(s.fastingOverride),
              subtitle: const Text('Force fasting state off'),
              onChanged: (v) => _saveFlag(ctx: context, cfg: cfg, fastingOverride: v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFlag({
    required BuildContext ctx,
    required AppConfig cfg,
    bool? rainMode,
    bool? fastingOverride,
  }) async {
    final updated = cfg.copyWith(rainMode: rainMode, fastingOverride: fastingOverride);
    await ref.read(adminProvider.notifier).saveConfig(updated);
  }

  Widget _footFunnel(BuildContext context, Strings s) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            KvRow(k: 'Signups', v: '132'),
            KvRow(k: 'Earning today', v: '48'),
            KvRow(k: 'Working radius', v: '1.5 km'),
            KvRow(k: 'First trips done', v: '61'),
            KvRow(k: 'Bonuses due', v: '3,200 ETB'),
          ],
        ),
      ),
    );
  }

  Future<void> _decisionNote(BuildContext context, String appId, String action, String merchant) async {
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action · $merchant'),
        content: TextField(
          controller: note,
          decoration: const InputDecoration(labelText: 'Note (reason)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = note.text.trim();
              if (action == 'Approve') {
                ref.read(adminProvider.notifier).approveApplication(appId);
              } else {
                ref.read(adminProvider.notifier).rejectApplication(appId, n);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _applications(BuildContext context, Strings s, List<MerchantApplication> apps) {
    if (apps.isEmpty) return Text(s.noOffers);
    return Column(
      children: [
        for (final a in apps)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.photoB64 != null)
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront, color: AppColors.primaryGold),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.businessName, style: Theme.of(context).textTheme.titleSmall),
                        Text('${a.ownerName} · ${a.phone}', style: Theme.of(context).textTheme.bodySmall),
                        Text('${a.subCity} · ${a.sefer}', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('Status: ${a.status}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () => _decisionNote(context, a.id, s.approve, a.businessName),
                        child: Text(s.approve, style: const TextStyle(color: AppColors.tsomGreen)),
                      ),
                      TextButton(
                        onPressed: () => _decisionNote(context, a.id, s.reject, a.businessName),
                        child: Text(s.reject, style: const TextStyle(color: AppColors.dangerRed)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _ocr(BuildContext context, Strings s, List<OcrStaging> queue) {
    if (queue.isEmpty) return Text(s.noOffers);
    return Column(
      children: [
        for (final o in queue)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Side-by-side: photo vs parsed items (§5.11).
                  Container(
                    width: 56,
                    height: 72,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.neutralMid.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image_outlined, color: AppColors.neutralMid),
                        Text('menu', style: TextStyle(fontSize: 10, color: AppColors.neutralMid)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.ocrQueue} · ${(o.confidence * 100).round()}%', style: Theme.of(context).textTheme.titleSmall),
                        for (final it in o.items)
                          Text('${it.nameEn} · ${it.priceEtb} ETB${it.isTsom ? ' · ጾም' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      // §5.11 OCR verified → items go live, not just a toast.
                      await ref.read(adminProvider.notifier).verifyOcr(o.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OCR verified → items live')),
                        );
                      }
                    },
                    child: Text(s.verify, style: const TextStyle(color: AppColors.tsomGreen)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _otp(BuildContext context, Strings s, List<OtpLogEntry> log) {
    if (log.isEmpty) return Text(s.noOffers);
    return Column(
      children: [
        for (final e in log)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${e.phone} · ${e.channel} · ${e.provider}${e.used ? ' · used' : ''}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Widget _channel(BuildContext context, Strings s, ChannelStatus cs) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${s.providerStatus}: ${cs.provider}', style: Theme.of(context).textTheme.titleSmall),
                ),
                TagBadge(label: cs.demo ? s.demoWatermark : 'live', color: cs.demo ? AppColors.surfaceGround : AppColors.tsomGreen),
              ],
            ),
            if (cs.missingSecrets.isNotEmpty)
              Text('missing: ${cs.missingSecrets.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}