import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_root.dart';
import '../../core/session_storage.dart';
import '../../i18n/strings.dart';
import '../../models/order.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// Verified-receipt view: high-contrast "VERIFIED / ፀድቋል" card with QR for the
/// driver + ref code, refund tracker on cancellations, dispute tickets
/// ("I never received this" / "I was overcharged") and the SMS order bridge.
class ReceiptView extends ConsumerStatefulWidget {
  const ReceiptView({super.key, required this.order});
  final Order order;

  @override
  ConsumerState<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends ConsumerState<ReceiptView> {
  Map<String, dynamic>? _persisted;

  @override
  void initState() {
    super.initState();
    // §10/§14: persist a confirmed receipt locally so it displays fully offline.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final o = widget.order;
    if (o.paymentStatus == PaymentStatus.confirmed) {
      final ref = o.paymentRef ?? 'FT${o.id.replaceAll(RegExp(r'\D'), '').padLeft(8, '0')}';
      await SessionStorage.saveVerifiedReceipt(o.id, ref, o.total);
    }
    final p = await SessionStorage.verifiedReceipt(o.id);
    if (mounted) setState(() => _persisted = p);
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final o = widget.order;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (o.paymentStatus == PaymentStatus.confirmed) _verifiedCard(context, s, o),
          if (o.paymentStatus == PaymentStatus.codPending) _codCard(context, s, o),
          if (o.isCancelled) _refundTracker(context, s, o),
          const SizedBox(height: 16),
          _guardrailButtons(context, s, o),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.landmark, style: Theme.of(context).textTheme.bodySmall),
                  Text(o.landmarkText.isEmpty ? '—' : o.landmarkText, style: Theme.of(context).textTheme.bodyMedium),
                  Text('${s.plusCode}: ${o.plusCode}', style: Theme.of(context).textTheme.bodySmall),
                  LockedTotalPill(totalEtb: o.total, small: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedCard(BuildContext context, Strings s, Order o) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tsomGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: Colors.white),
              SizedBox(width: 8),
              Text('VERIFIED · ፀድቋል',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ref: ${o.paymentRef ?? (_persisted?['ref'] as String?) ?? '—'}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Center(
            child: QrImageView(
              data: '${o.id}|${o.total}|${o.paymentRef}',
              size: 160,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Scan this QR at the restaurant · ይህን QR ያስቃኙ',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _codCard(BuildContext context, Strings s, Order o) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceGround.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.money, color: AppColors.neutralDark),
          const SizedBox(width: 8),
          Expanded(child: Text('${s.cod} — ${s.codNote}', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _refundTracker(BuildContext context, Strings s, Order o) {
    // §11.1: a cancelled prepaid order shows the Refund Tracker status chip
    // (Initiated → Processing → Returned), the "within 24 h" promise and ref code.
    final refCode =
        'RF${o.id.replaceAll(RegExp(r'\D'), '').padLeft(6, '0').substring(0, 6)}';
    final stages = [s.refundInitiated, s.refundProcessing, s.refundReturned];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.refundBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.refundBlue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.refundTracker} · ${s.refundInitiated} · ${s.refundRef} $refCode',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.refundBlue)),
          const SizedBox(height: 8),
          for (int i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(i == 0 ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 16, color: i == 0 ? AppColors.refundBlue : AppColors.neutralMid),
                  const SizedBox(width: 8),
                  Text(stages[i],
                      style: TextStyle(fontSize: 13,
                          color: i == 0 ? AppColors.neutralDark : AppColors.neutralMid,
                          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text('Refund within 24 h · በ24 ሰዓት ውስጥ',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _guardrailButtons(BuildContext context, Strings s, Order o) {
    final session = ref.read(sessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (o.status == OrderStatus.delivered)
          OutlinedButton.icon(
            onPressed: () => _openDispute(context, s, o.id, s.neverReceived),
            icon: const Icon(Icons.inventory_2),
            label: Text(s.neverReceived),
          ),
        if (o.status == OrderStatus.delivered)
          OutlinedButton.icon(
            onPressed: () => _openDispute(context, s, o.id, s.overcharged),
            icon: const Icon(Icons.flag_outlined),
            label: Text(s.overcharged),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _composeSms(context, s, o),
          icon: const Icon(Icons.sms),
          label: Text('${s.orderBySms} · ${s.smsBridgeNote}'),
        ),
        if (session != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s.voiceOrderLine, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Future<void> _openDispute(BuildContext context, Strings s, String orderId, String reason) async {
    // §11.5 ticketed disputes: visible ticket ID + status; the CEO dashboard
    // resolves the exact same ticket.
    String ticketId = 'tkt-${orderId.hashCode.abs()}';
    try {
      final token = ref.read(sessionProvider)?.token ?? '';
      final t = await ref.read(apiClientProvider).openDispute(token, orderId, reason);
      ticketId = t.id;
    } catch (_) {
      // offline: ticket id derived locally, still surfaced
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.disputeTicket),
        content: Text('$reason\nTicket: $ticketId · Status: Open → In review → Resolved'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _composeSms(BuildContext context, Strings s, Order o) {
    final body = 'ORD-${o.merchantName.replaceAll(RegExp(r'\s+'), '-')}-${o.total}-CASH';
    final uri = 'sms:?body=${Uri.encodeComponent(body)}';
    return launchUri(context, uri);
  }
}

Future<bool> launchUri(BuildContext context, String uri) async {
  try {
    final ok = await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
    if (!ok) throw 'launch failed';
    return ok;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
    return false;
  }
}