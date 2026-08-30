import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../i18n/strings.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared.dart';

/// Field Agent verification mode (§12): GPS-sorted nearby draft_unverified
/// merchants, camera-first capture (menu photo + storefront photo → OCR), pin
/// confirm, payment details, submit; plus a personal tally + earnings ledger.
/// This is the supply-side engine that feeds the admin OCR + application queue.
class FieldAgentScreen extends ConsumerStatefulWidget {
  const FieldAgentScreen({super.key});

  @override
  ConsumerState<FieldAgentScreen> createState() => _FieldAgentScreenState();
}

class _FieldAgentScreenState extends ConsumerState<FieldAgentScreen> {
  bool _verified = false;
  bool _menuShot = false;
  bool _storeShot = false;
  bool _pinConfirmed = false;
  bool _payCaptured = false;

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final catalog = ref.watch(catalogProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.fieldAgentTitle),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoleSection(title: s.fieldNearby, child: _nearbyList(context, s, catalog)),
          RoleSection(title: s.fieldCapture, child: _captureSteps(context, s)),
          RoleSection(title: s.fieldTally, child: _tally(context, s)),
        ],
      ),
    );
  }

  Widget _nearbyList(BuildContext context, Strings s, dynamic catalog) {
    if (catalog == null) return const SizedBox();
    // GPS-sorted draft records nearest to the agent (demo shows a sample).
    final draft = [
      'የኣዳም ቡና · Adam Coffee (80 m)',
      'ሳምራዊ ምግብ ቤት · Samrawi Restaurant (140 m)',
      'መርካቶ ጣፋጭ ቤት · Merkato Sweets (210 m)',
    ];
    return Column(
      children: [
        for (final d in draft)
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: const Icon(Icons.storefront, color: AppColors.primaryGold),
              title: Text(d),
              trailing: const Icon(Icons.near_me, color: AppColors.neutralMid),
            ),
          ),
      ],
    );
  }

  Widget _captureSteps(BuildContext context, Strings s) {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          SwitchListTile(
            value: _menuShot,
            title: Text(s.photoMenu),
            subtitle: const Text('→ OCR pipeline → admin review'),
            onChanged: (v) => setState(() => _menuShot = v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          SwitchListTile(
            value: _storeShot,
            title: Text(s.photoStorefront),
            onChanged: (v) => setState(() => _storeShot = v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          SwitchListTile(
            value: _pinConfirmed,
            title: Text(s.confirmPin),
            subtitle: const Text('Standing at the door — GPS + timestamp'),
            onChanged: (v) => setState(() => _pinConfirmed = v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          SwitchListTile(
            value: _payCaptured,
            title: Text(s.paymentDetails),
            subtitle: const Text('Owner Telebirr/CBE + phone'),
            onChanged: (v) => setState(() => _payCaptured = v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: (_menuShot && _storeShot && _pinConfirmed && _payCaptured && !_verified)
                  ? () => setState(() => _verified = true)
                  : null,
              child: Text(_verified ? 'VERIFIED — submitted' : s.verifyMerchant,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tally(BuildContext context, Strings s) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.agentLedger, style: Theme.of(context).textTheme.titleSmall),
            KvRow(k: 'Today verified', v: '${_verified ? 1 : 0}'),
            const KvRow(k: 'Base stipend (day)', v: '500 ETB'),
            KvRow(k: 'Activations (+100 ETB)', v: '${_verified ? 100 : 0} ETB'),
            const KvRow(k: 'OCR quality bonus', v: '0 ETB'),
            const KvRow(k: 'Residuals (90d)', v: '0 ETB'),
          ],
        ),
      ),
    );
  }
}