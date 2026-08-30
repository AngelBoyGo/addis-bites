import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../models/order.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/orders_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/savings.dart';
import '../../widgets/rating_card.dart';
import '../../widgets/shared.dart';
import 'receipt_view.dart';

/// Live order tracking (§5.6): progress stepper, payment badge, verified-receipt
/// tile, one-tap CALL RIDER (GSM launch), honest ETA, landmark + Plus Code,
/// itemized totals, 90s merchant-ack countdown with SMS-escalation state, and
/// the guardrail buttons (disputes, SMS bridge). Polls 3-5s while foreground.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start 3-5s polling for this order (paused when backgrounded).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).pollOrder(widget.id);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // §5.6: poll only while the tracking screen is foreground; pause on background.
    if (state == AppLifecycleState.resumed) {
      ref.read(ordersProvider.notifier).pollOrder(widget.id);
    } else {
      ref.read(ordersProvider.notifier).stopPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(ordersProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final orders = ref.watch(ordersProvider);
    Order? order;
    for (final o in orders) {
      if (o.id == widget.id) {
        order = o;
        break;
      }
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back))),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('#${order.id}'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _topBadge(context, order),
          const SizedBox(height: 16),
          ReceiptView(order: order),
          if (order.status == OrderStatus.placed) _ackCountdown(context, order),
          const SizedBox(height: 8),
          _stepper(context, order.status),
          if (order.courierPhone != null) ...[
            const SizedBox(height: 16),
            _courierCard(context, order),
          ],
          const SizedBox(height: 16),
          _eta(context, s, order),
          const SizedBox(height: 8),
          _deliveryInfo(context, order),
          const SizedBox(height: 8),
          _totalsCard(context, order),
          const SizedBox(height: 16),
          Text(s.enjoyMeal, style: const TextStyle(color: AppColors.tsomGreen, fontWeight: FontWeight.w700)),
          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: 16),
            ShareCard(merchant: order.merchantName, message: s.shareToSaveNames),
            const SizedBox(height: 16),
            RatingCard(order: order),
          ],
        ],
      ),
    );
  }

  Widget _stepper(BuildContext context, OrderStatus status) {
    final s = StringsScope.of(context);
    final step = status.stepIndex;
    final labels = [s.statusPlaced, s.statusPreparing, s.statusEnRoute, s.statusArrived, s.statusDelivered];
    return Column(
      children: [
        for (int i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(i <= step ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: i <= step ? AppColors.primaryGold : AppColors.neutralMid),
                const SizedBox(width: 12),
                Text(labels[i], style: TextStyle(color: i <= step ? AppColors.neutralDark : AppColors.neutralMid)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _ackCountdown(BuildContext context, Order order) {
    final s = StringsScope.of(context);
    final remaining = order.ackDeadlineAt == null ? 0 : order.ackDeadlineAt!.difference(DateTime.now()).inSeconds;
    final secondsLeft = max(0, remaining);
    final escalated = order.smsFallbackSent;
    return Card(
      color: escalated ? AppColors.surfaceGround.withValues(alpha: 0.15) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: escalated
            ? Row(
                children: [
                  const Icon(Icons.sms, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.smsEscalated)),
                ],
              )
            : Row(
                children: [
                  Text('${s.ackNow}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  CountdownText(seconds: secondsLeft),
                ],
              ),
      ),
    );
  }

Widget _eta(BuildContext context, Strings s, Order order) {
    if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
      return const SizedBox();
    }
    // §5.8b: customer ETA extends during evening motorbike curfew.
    final curfew = ref.watch(catalogProvider).valueOrNull?.config.vehicleCurfew ?? false;
    final canCancel = order.status == OrderStatus.placed ||
        order.status == OrderStatus.merchantAck ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.courierAssigned;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.neutralMid),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.honestEta, style: Theme.of(context).textTheme.bodyMedium),
                  Text('25–40 min (ranges, never a single promise)',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (curfew || order.status == OrderStatus.courierAssigned)
                    Text(s.etaReduced,
                        style: const TextStyle(color: AppColors.neutralMid, fontSize: 11)),
                  // §11.9: ETA slip → one-tap cancel with full refund (un-picked-up only).
                  if (canCancel) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _cancelWithRefund(context, s, order),
                      icon: const Icon(Icons.replay, size: 16),
                      label: Text(s.cancelFullRefund, style: const TextStyle(color: AppColors.dangerRed)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelWithRefund(BuildContext context, Strings s, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.cancelFullRefund),
        content: Text('Cancel #${order.id} and refund ${order.total} ETB within 24 h?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep order')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
            child: const Text('Cancel & refund'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(ordersProvider.notifier).upsert(order.copyWith(status: OrderStatus.cancelled));
    }
  }

  Widget _courierCard(BuildContext context, Order order) {
    return Card(
      color: AppColors.primaryGold,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.courierName ?? 'Courier'} · ${order.courierVehicle ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.neutralDark),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.neutralDark, foregroundColor: Colors.white),
                onPressed: () => _callRider(context, order),
                icon: const Icon(Icons.call),
                label: const Text('CALL RIDER DIRECTLY · ለአበላሹ ይደውሉ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            TextButton(
              onPressed: () => _textRider(context, order),
              child: const Text('Send text message · መልዕክት ይላኩ',
                  style: TextStyle(color: AppColors.neutralDark)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callRider(BuildContext context, Order order) async {
    final phone = order.courierPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    if (phone.isEmpty) return;
    await launchUri(context, 'tel:$phone');
  }

  Future<void> _textRider(BuildContext context, Order order) async {
    final phone = order.courierPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    if (phone.isEmpty) return;
    await launchUri(context, 'sms:$phone');
  }

  Widget _deliveryInfo(BuildContext context, Order order) {
    final s = StringsScope.of(context);
    final txt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.landmark, style: txt.labelSmall),
            Text(order.landmarkText.isEmpty ? '—' : order.landmarkText, style: txt.bodyMedium),
            const SizedBox(height: 6),
            Text('${s.plusCode}: ${order.plusCode.isEmpty ? '' : order.plusCode}', style: txt.bodySmall),
            if (order.subCity.isNotEmpty) Text('${order.subCity} · ${order.sefer}', style: txt.bodySmall),
            const SizedBox(height: 8),
            LockedTotalPill(totalEtb: order.total, small: true),
            if (order.status == OrderStatus.delivered)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Delivery confirmed with your PIN · በPIN ተረጋግጧል',
                    style: TextStyle(color: AppColors.tsomGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _totalsCard(BuildContext context, Order order) {
    final s = StringsScope.of(context);
    Widget line(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [Expanded(child: Text(l)), Text(v)]),
        );
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final it in order.items)
              line('${it.qty}× ${it.nameEn}', '${it.lineTotal} ETB'),
            const Divider(height: 1, color: AppColors.cardBorder),
            line(s.subtotal, '${order.subtotal} ETB'),
            line(s.deliveryFee, '${order.deliveryFee} ETB'),
            line(s.serviceFee, '${order.serviceFee} ETB'),
            if (order.surge > 0) line(s.surge, '+${order.surge} ETB'),
            line(s.total, '${order.total} ETB'),
          ],
        ),
      ),
    );
  }

  Widget _topBadge(BuildContext context, Order order) {
    final s = StringsScope.of(context);
    final Color bg;
    final String label;
    switch (order.paymentStatus) {
      case PaymentStatus.confirmed:
        bg = AppColors.tsomGreen;
        label = s.verified;
        break;
      case PaymentStatus.codPending:
        bg = AppColors.surfaceGround;
        label = s.codPending;
        break;
      default:
        bg = AppColors.neutralMid;
        label = s.pending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}