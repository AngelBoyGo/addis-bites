import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_root.dart';
import '../core/telegram_adapter.dart';
import '../i18n/strings.dart';
import '../models/session.dart';
import '../providers/catalog_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';

/// One sign-up flow for all five roles (§5.1).
/// Role tiles -> name + phone (regex + length checks) -> verification method
/// (Telegram one-tap or SMS OTP; demo code shown only in demo mode) -> role home.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _phone = TextEditingController(text: '+251911224410');
  final _name = TextEditingController(text: 'Demo User');
  final _otp = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _verify = false;
  String _method = 'sms'; // 'sms' | 'telegram'
  bool _busy = false;
  String? _demoCode;
  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    _name.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  String _canonicalPhone() {
    var p = _phone.text.replaceAll(RegExp(r'[\s-]'), '');
    if (p.startsWith('0')) p = '+251${p.substring(1)}';
    if (p.startsWith('9')) p = '+251$p';
    return p;
  }

  bool get _phoneValid => RegExp(r'^\+251(9|7)[0-9]{8}$').hasMatch(_canonicalPhone());
  bool get _nameValid => _name.text.trim().isNotEmpty && _name.text.trim().length <= 60;

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    final demo = ref.watch(catalogProvider).valueOrNull?.config.demoMode ?? true;

    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: _verify ? _verificationView(context, s, demo) : _profileView(context, s, demo),
      ),
    );
  }

  Widget _profileView(BuildContext context, Strings s, bool demo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (demo)
          Align(
            alignment: Alignment.topRight,
            child: TagPill(label: 'DEMO · ማሳያ', color: AppColors.surfaceGround),
          ),
        Text('Choose your role · ሚናዎን ይምረጡ', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _roleTile(UserRole.customer, 'Customer', 'ደንበኛ · order food'),
        _roleTile(UserRole.merchant, 'Merchant', 'ነጋዴ · accept orders'),
        _roleTile(UserRole.driver, 'Driver / Carrier', 'አበላሽ · deliver'),
        _roleTile(UserRole.admin, 'Admin', 'አስተዳዳሪ'),
        _roleTile(UserRole.ceo, 'CEO', 'ባለቤት'),
        _roleTile(UserRole.support, 'Support', 'ደንበኛ እርዳታ · tickets & strikes'),
        _roleTile(UserRole.finance, 'Finance', 'ፋይናንስ · payouts & ledger'),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Full name · ሙሉ ስም'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone (+251…)',
            errorText: _phone.text.isEmpty
                ? null
                : (_phoneValid ? null : 'must be +251 9/7 followed by 8 digits'),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (_nameValid && _phoneValid && !_busy) ? () => _requestVerification(context) : null,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(s.continueBtn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _verificationView(BuildContext context, Strings s, bool demo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (demo)
          Align(
            alignment: Alignment.topRight,
            child: TagPill(label: 'DEMO · ማሳያ', color: AppColors.surfaceGround),
          ),
        Text('Verify · ማረጋገጥ', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'sms', label: Text('SMS OTP')),
            ButtonSegment(value: 'telegram', label: Text('Telegram')),
          ],
          selected: {_method},
          onSelectionChanged: (v) => setState(() {
            _method = v.first;
            _demoCode = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_method == 'sms') ...[
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '6-digit code',
              helperText: demo && _demoCode != null ? 'Demo code: $_demoCode' : null,
            ),
          ),
          TextButton(
            onPressed: _resendCooldown > 0 ? null : () => _requestVerification(context),
            child: Text(_resendCooldown > 0 ? 'Resend · ${_resendCooldown}s' : 'Resend · 30s'),
          ),
        ] else
          Text(
            'Tap to authenticate with your Telegram account (initData → /api/tg-auth).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : () => _verifySubmit(context),
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Verify & continue · አረጋግጡ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        TextButton(
          onPressed: () => setState(() => _verify = false),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _roleTile(UserRole role, String en, String am) {
    final selected = _role == role;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: selected ? AppColors.primaryGold.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.primaryGold : AppColors.cardBorder, width: 2),
      ),
      child: ListTile(
        leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? AppColors.primaryGold : AppColors.neutralMid),
        title: Text(en),
        subtitle: Text(am),
        onTap: () => setState(() => _role = role),
      ),
    );
  }

  Future<void> _requestVerification(BuildContext context) async {
    setState(() => _busy = true);
    try {
      if (_method == 'telegram') {
        await ref.read(sessionProvider.notifier).tgAuth(TelegramAdapter.initData);
        if (!mounted) return;
        context.go('/');
      } else {
        final res = await ref.read(sessionProvider.notifier).otpRequest(phone: _canonicalPhone());
        setState(() {
          _verify = true;
          _demoCode = res.demoCode;
          _busy = false;
        });
        _startResendCooldown();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _verifySubmit(BuildContext context) async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).otpVerify(
            phone: _canonicalPhone(),
            code: _otp.text.trim(),
            role: _role.name,
          );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class TagPill extends StatelessWidget {
  const TagPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}