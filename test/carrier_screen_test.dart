import 'package:addis_bites/features/dash/carrier_screen.dart';
import 'package:addis_bites/models/role_dashboards.dart';
import 'package:addis_bites/providers/role_providers.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededFootNotifier extends FootNotifier {
  _SeededFootNotifier(super.ref, FootStatus status) {
    state = AsyncValue.data(status);
  }
}

void main() {
  testWidgets('carrier earnings (step 3) shows a KPI row', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        footProvider.overrideWith((ref) => _SeededFootNotifier(
          ref,
          const FootStatus(signupComplete: true, orientationComplete: true, earningToday: true, radiusKm: 1.5, missed: 0, phone: '+251911000001'),
        )),
        footEarningsProvider.overrideWith((ref) => const FootEarnings(
          walletBalanceEtb: 95,
          bonuses: [FootBonus(kind: 'signup', amountEtb: 50, deliveredEtb: 0, status: 'released')],
          trips: [],
        )),
      ],
      child: const MaterialApp(home: CarrierScreen(initialStep: 3)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(KpiRow), findsAtLeastNWidgets(1));
  });
}