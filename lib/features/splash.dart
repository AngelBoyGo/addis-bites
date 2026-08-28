import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

/// Brand splash/onboarding. Brand lockup + Amharic tagline + language toggle (§5.0).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final amharic = locale == LocaleId.am;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: OutlinedButton(
                    onPressed: () => ref.read(localeProvider.notifier).toggle(),
                    child: Text(amharic ? 'EN' : 'አማ'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('AB', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.neutralDark)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Addis Bites', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('አዲስ ባይትስ', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.push('/join'),
                child: Text(amharic ? 'ጀምር' : 'Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}