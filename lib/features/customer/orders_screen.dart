import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../models/order.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';

/// Order history (§5.7): session-phone lookup OR manual phone entry. Rows show
/// merchant, date, total, payment method and a status chip; tap → tracking.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _phone = TextEditingController();
  List<Order> _remote = [];
  bool _lookupBusy = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    if (session != null) {
      _phone.text = session.profile.phone;
      _lookup(session.profile.phone);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _lookup(String phone) async {
    final token = ref.read(sessionProvider)?.token;
    if (token == null || phone.trim().isEmpty) return;
    setState(() => _lookupBusy = true);
    try {
      final api = ref.read(apiClientProvider);
      final fetched = await api.fetchOrders(phone.trim(), token);
      if (!mounted) return;
      setState(() {
        _remote = fetched;
        _lookupBusy = false;
      });
      for (final o in fetched) {
        ref.read(ordersProvider.notifier).upsert(o);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _lookupBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${StringsScope.of(context).connectionLost}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final sessionOrders = ref.watch(ordersProvider);
    final pendingCount = ref.watch(ordersPendingProvider);

    // Deduplicate by id; prefer the freshest (manual lookup results first).
    final seen = <String>{};
    final rows = <Order>[
      for (final o in _remote)
        if (seen.add(o.id)) o,
      for (final o in sessionOrders)
        if (seen.add(o.id)) o,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.orders),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: s.phone,
              suffixIcon: IconButton(
                icon: _lookupBusy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                onPressed: () => _lookup(_phone.text),
              ),
            ),
            onSubmitted: (v) => _lookup(v),
          ),
          const SizedBox(height: 12),
          // §3 offline retry queue: surface pending queued submissions with a manual Retry.
          if (pendingCount > 0)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.tsomGreen.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.tsomGreen.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: AppColors.tsomGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${ref.read(ordersProvider.notifier).pending.length} order(s) queued offline',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(ordersProvider.notifier).manualRetry(),
                      child: Text(StringsScope.of(context).retry,
                          style: const TextStyle(color: AppColors.tsomGreen, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(child: Text(s.noOrders, style: Theme.of(context).textTheme.titleMedium)),
            )
          else
            for (final o in rows) _row(context, o),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Order order) {
    final txt = Theme.of(context).textTheme;
    final created = order.createdAt;
    final dateStr = created == null
        ? '—'
        : '${created.day}/${created.month}/${created.year} ${created.hour}:${created.minute.toString().padLeft(2, '0')}';
    final pm = order.paymentMethod == 'chapa'
        ? (order.paymentStatus == PaymentStatus.confirmed ? 'Chapa · ✓' : 'Chapa')
        : 'Cash';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGold.withValues(alpha: 0.9),
          child: const Icon(Icons.shopping_bag, color: AppColors.neutralDark, size: 20),
        ),
        title: Text(order.merchantName.isEmpty ? order.id : order.merchantName),
        subtitle: Text(
          '$dateStr · $pm · ${_statusLabel(order.status)} · ${order.total} ETB',
          style: txt.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/order/${order.id}'),
      ),
    );
  }

  String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.placed => 'Placed',
        OrderStatus.merchantAck => 'In kitchen',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.courierAssigned => 'Rider assigned',
        OrderStatus.pickedUp => 'Picked up',
        OrderStatus.enRoute => 'En route',
        OrderStatus.arrived => 'Arrived',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
}