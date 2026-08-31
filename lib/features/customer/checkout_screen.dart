import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../core/api_types.dart';
import '../../core/pricing.dart';
import '../../i18n/strings.dart';
import '../../models/catalog.dart';
import '../../models/catalog_response.dart';
import '../../models/cart.dart';
import '../../models/session.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/role_providers.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/map_pin_field.dart';
import '../../widgets/savings.dart';
import '../../widgets/shared.dart';
import 'receipt_view.dart';

/// Checkout (§5.5): two-tier landmark addressing (sub-city + sefer admin hub
/// autosuggest + mandatory micro-landmark), optional map pin, savings options
/// (buna / pickup / meet-point / schedule-ahead / digital-payment discount /
/// Sefer Round join), price lock, fee transparency, and Chapa vs COD.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _landmark = TextEditingController();
  String _subCity = '';
  String _sefer = '';
  String _payment = 'chapa';
  bool _submitting = false;

  bool _pickup = false;
  bool _meetPoint = false;
  bool _schedule = false;
  bool _digitalPayDiscount = false;
  String? _selectedRoundId;
  final GlobalKey<MapPinFieldState> _mapKey = GlobalKey<MapPinFieldState>();

  final List<String> _hubs = const [
    'Bole Medhanealem', 'Kazanchis', 'Piazza', 'Sarbet', 'CMC St. Michael',
    'Megenagna', 'Edna Mall', 'Gotera Condominium', 'Tor Hailoch', 'Merkato',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roundsProvider.notifier).load('Bole');
    });
  }

  @override
  void dispose() {
    _landmark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final session = ref.watch(sessionProvider);
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final cart = ref.watch(cartProvider);
    final rounds = ref.watch(roundsProvider);

    final subtotal = cart.subtotal;
    final cfg = catalog?.config;
    final buna = cfg == null ? null : Pricing.bunaRun(cfg, cart);
    final bandFee = cfg == null ? 0 : Pricing.deliveryFee(cfg, cart.band);
    final delivery = _pickup ? 0 : (buna ?? bandFee);
    final surge = cfg == null ? 0 : Pricing.surge(cfg);
    final meetSavings = _meetPoint ? 12 : 0;
    final scheduleSavings = _schedule ? 15 : 0;
    final digitalSavings = _digitalPayDiscount && _payment == 'chapa' ? 8 : 0;
    final roundSavings = _selectedRoundId != null ? 10 : 0;
    final savingsTotal = meetSavings + scheduleSavings + digitalSavings + roundSavings;
    final estimate = subtotal + delivery + (cfg?.serviceFee ?? 0) + surge - savingsTotal;

    final landmarkReady = _landmark.text.trim().length >= 3;
    final canSubmit = landmarkReady && _subCity.isNotEmpty && !cart.isEmpty && !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.orderCheckout),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _landmarkSection(context, s, session, catalog),
          const SizedBox(height: 12),
          _mapSection(context, s),
          const SizedBox(height: 12),
          _savings(context, s, cart, cfg),
          if (rounds.isNotEmpty)
            RoleSection(
              title: 'Sefer Rounds', // batched deliveries savings
              child: Column(children: [
                for (final r in rounds)
                  SeferRoundCard(round: r),
                for (final r in rounds)
                  RadioListTile<String>(
                    title: Text('${r.label} · join'),
                    value: r.id,
                    groupValue: _selectedRoundId,
                    onChanged: (v) => setState(() => _selectedRoundId = v),
                  ),
              ]),
            ),
          const SizedBox(height: 12),
          _section(context, s.paymentMethod),
          _paymentSelector(context, s),
          const SizedBox(height: 16),
          _summary(context, s, subtotal, delivery, cfg, surge, savingsTotal, estimate),
          const SizedBox(height: 8),
          Text(s.priceLockNote, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.verified, size: 16, color: AppColors.tsomGreen),
              const SizedBox(width: 6),
              Expanded(child: Text(s.deliveryGuaranteeNote, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: canSubmit ? () => _submit(context, session) : null,
            child: _submitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('${s.placeOrder} · $estimate ETB',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _landmarkSection(BuildContext context, Strings s, Session? session, CatalogResponse? catalog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(context, s.deliverTo),
        if (session != null) _info(context, '${s.phone}: ${session.profile.phone}'),
        if (catalog != null && catalog.subCities.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _subCity.isEmpty ? null : _subCity,
            items: [
              for (final c in catalog.subCities)
                DropdownMenuItem(value: c.nameEn, child: Text(c.nameEn)),
            ],
            onChanged: (v) => setState(() => _subCity = v ?? ''),
            decoration: InputDecoration(labelText: s.selectNeighborhood),
          ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _sefer,
          decoration: const InputDecoration(labelText: 'Sefer / hub'),
          onChanged: (v) => setState(() => _sefer = v),
        ),
        _hubSuggestionChips(context, s),
        const SizedBox(height: 8),
        TextFormField(
          controller: _landmark,
          minLines: 2,
          maxLines: 4,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: s.landmarkLabel, hintText: s.landmarkPlaceholder),
        ),
      ],
    );
  }

  Widget _hubSuggestionChips(BuildContext context, Strings s) {
    final shown = _hubs.where((h) => h.toLowerCase().contains(_sefer.toLowerCase())).toList();
    if (_sefer.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final h in shown.take(4))
          ActionChip(label: Text(h), onPressed: () => setState(() => _sefer = h)),
      ],
    );
  }

  Widget _mapSection(BuildContext context, Strings s) {
    return MapPinField(key: _mapKey);
  }

  Widget _savings(BuildContext context, Strings s, Cart cart, AppConfig? cfg) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: [
            SwitchListTile(
              value: _pickup,
              title: Text('${s.pickupMode} · 0 ETB'),
              onChanged: (v) => setState(() => _pickup = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _meetPoint,
              title: Text('${s.meetPoint} · ${s.youSave} 12 ETB'),
              onChanged: (v) => setState(() => _meetPoint = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _schedule,
              title: Text('${s.scheduleAhead} · ${s.youSave} 15 ETB'),
              onChanged: (v) => setState(() => _schedule = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _digitalPayDiscount,
              title: Text('${s.digitalPaymentDiscount} · ${s.youSave} 8 ETB'),
              onChanged: (v) => setState(() => _digitalPayDiscount = v),
              contentPadding: EdgeInsets.zero,
              subtitle: const Text('Chapa / Telebirr only'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSelector(BuildContext context, Strings s) {
    return Column(
      children: [
        RadioListTile<String>(
          title: Text(s.chapa),
          subtitle: Text(s.chapaSub),
          value: 'chapa',
          groupValue: _payment,
          onChanged: (v) => setState(() => _payment = v!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: Text(s.cod),
          subtitle: Text(s.codNote),
          value: 'cod',
          groupValue: _payment,
          onChanged: (v) => setState(() => _payment = v!),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _summary(BuildContext context, Strings s, int subtotal, int delivery,
      AppConfig? cfg, int surge, int savingsTotal, int estimate) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _feeLine(context, s.subtotal, '$subtotal ETB'),
            _feeLine(context, s.deliveryFee, '$delivery ETB'),
            _feeLine(context, s.serviceFee, '${cfg?.serviceFee ?? 0} ETB'),
            if (surge > 0) _feeLine(context, s.surge, '+$surge ETB'),
            if (savingsTotal > 0)
              _feeLine(context, s.youSave, '−$savingsTotal ETB', color: AppColors.tsomGreen),
            const Divider(height: 1, color: AppColors.cardBorder),
            Row(children: [
              Expanded(child: Text(s.whyThisFee, style: Theme.of(context).textTheme.bodySmall)),
              const Spacer(),
              Text('$estimate ETB', style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _feeLine(BuildContext context, String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _info(BuildContext context, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      );

  Widget _section(BuildContext context, String title) =>
      Padding(padding: const EdgeInsets.only(top: 6, bottom: 8), child: Text(title, style: Theme.of(context).textTheme.titleMedium));

  Future<void> _submit(BuildContext context, Session? session) async {
    if (session == null) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final order = await api.placeOrder(
        token: session.token,
        phone: session.profile.phone,
        merchantId: cart.merchantId ?? '',
        items: [
          for (final l in cart.lines) {'itemId': l.item.id, 'qty': l.qty, 'injeraCount': l.injeraCount, 'spice': l.spice},
        ],
        subCity: _subCity,
        sefer: _sefer.isEmpty ? _subCity : _sefer,
        landmarkText: _landmark.text.trim(),
        paymentMethod: _payment,
        roundId: _selectedRoundId,
        lat: _mapKey.currentState?.lat,
        lng: _mapKey.currentState?.lng,
      );
      ref.read(ordersProvider.notifier).upsert(order);
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      if (_payment == 'chapa') {
        // §5.5 Chapa hosted checkout: ask the worker to initialize a real
        // transaction (simulated when no keys are configured). On return the
        // tracking screen polls /api/order/:id until paymentStatus ==
        // confirmed, then renders the verified receipt + QR.
        String? checkoutUrl;
        try {
          final pay = await api.chapaInitialize(order.id, session.token);
          checkoutUrl = (pay['checkoutUrl'] ?? pay['checkout_url']) as String?;
        } catch (_) {
          // Initialization failure must not lose the order: tracking screen
          // still shows it and the customer can retry payment from support.
        }
        if (!mounted) return;
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          await launchUri(context, checkoutUrl);
          if (!mounted) return;
        }
        context.go('/order/${order.id}');
      } else {
        context.go('/order/${order.id}');
      }
    } catch (e) {
      final sessionForQueue = ref.read(sessionProvider);
      // §3 offline-first: queue the order submission with retry (2 automatic
      // attempts, then a manual Retry button) instead of losing it.
      if (sessionForQueue != null) {
        ref.read(ordersProvider.notifier).enqueue(
          PendingOrder(
            token: sessionForQueue.token,
            phone: sessionForQueue.profile.phone,
            merchantId: cart.merchantId ?? '',
            items: [
              for (final l in cart.lines)
                {'itemId': l.item.id, 'qty': l.qty, 'injeraCount': l.injeraCount, 'spice': l.spice},
            ],
            subCity: _subCity,
            sefer: _sefer.isEmpty ? _subCity : _sefer,
            landmarkText: _landmark.text.trim(),
            lat: _mapKey.currentState?.lat,
            lng: _mapKey.currentState?.lng,
            paymentMethod: _payment,
          ),
        );
      }
      if (!mounted) return;
      final msg = e is ApiPublic ? e.message : '${StringsScope.of(context).connectionLost}: $e';
      // SMS order bridge (§11.7): when the app POST fails, offer the OS SMS
      // composer with the encoded order instead of leaving the user stranded.
      final body = 'ORD-${cart.merchantId ?? 'x'}-${cart.lines.map((l) => '${l.item.id}x${l.qty}').join(',')}-${_subCity}-CASH';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$msg · ${'Queued — retry pending'}'),
          action: SnackBarAction(
            label: StringsScope.of(context).orderBySms,
            onPressed: () => launchUri(context, 'sms:?body=${Uri.encodeComponent(body)}'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}