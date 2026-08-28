import 'package:addis_bites/features/dash/driver_shell.dart';
import 'package:addis_bites/models/driver.dart';
import 'package:addis_bites/providers/role_providers.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededDriverNotifier extends DriverNotifier {
  _SeededDriverNotifier(super.ref, DriverDashboard dash) {
    state = AsyncValue.data(dash);
  }
}

const _dash = DriverDashboard(
  wallet: DriverWallet(balanceEtb: 640, floatEtb: 1200, floatCap: 1500, payoutDue: 0),
  econByVehicle: [
    VehicleEconomics(vehicle: DeliveryVehicle.motorbike, costPerKm: 10, rangeKm: 18, keeperSharePct: 80),
    VehicleEconomics(vehicle: DeliveryVehicle.foot, costPerKm: 0, rangeKm: 1.5, keeperSharePct: 95),
  ],
  offers: [
    DriverOffer(
      orderId: 'ord-1', merchant: 'Sheger Kitchen', sefer: 'Bole', distanceKm: 1.2,
      grossFee: 80, keeperShare: 64, fuelCost: 10, net: 54, subsidy: 0, tipsEtb: 12, etaMin: 15, footEligible: true,
    ),
  ],
  curfewActive: false,
);

void main() {
  testWidgets('driver dashboard shows wallet KpiRow and offer status pill', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        driverDashboardProvider.overrideWith((ref) => _SeededDriverNotifier(ref, _dash)),
      ],
      child: const MaterialApp(home: DriverShell()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(KpiRow), findsAtLeastNWidgets(1));
    expect(find.text('640'), findsOneWidget); // wallet balance in KpiRow
    // the offers section lives further down the main (vertical) list
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Sheger Kitchen · Bole'), findsOneWidget);
  });
}