import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_root.dart';
import '../theme/app_colors.dart';

/// Diaspora / sponsor-pay screen (§3.5, §10B.4): a deep link `/g/<token>` lets a
/// sponsor abroad (or locally) prepay a meal delivered to a recipient's landmark
/// in Addis. In production the token is single-use and validated against
/// `sponsor_links`; the demo builds a payment intent and flips to "paid".
class SponsorPayScreen extends StatefulWidget {
  const SponsorPayScreen({super.key, required this.token});
  final String token;

  @override
  State<SponsorPayScreen> createState() => _SponsorPayScreenState();
}

class _SponsorPayScreenState extends State<SponsorPayScreen> {
  bool _paid = false;

  @override
  Widget build(BuildContext context) {
    final s = StringsScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.sponsorPay),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryGold, AppColors.secondaryClay]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.volunteer_activism, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text('Send a warm meal home to Addis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Your loved one receives a home-cooked meal, delivered to their landmark.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.verified, color: AppColors.tsomGreen),
              title: const Text('Single-use sponsor link · በተለየ አገልግሎት'),
              subtitle: Text('token: ${widget.token}'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() => _paid = true),
            child: Text(_paid ? 'Already paid · ተከፍሏል' : 'Pay now via Chapa · በቻፓ ይክፈሉ'),
          ),
          const SizedBox(height: 8),
          if (_paid)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tsomGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tsomGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.tsomGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.homeFed, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tsomGreen)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}