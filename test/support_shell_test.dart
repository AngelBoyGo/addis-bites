import 'package:addis_bites/features/dash/support_shell.dart';
import 'package:addis_bites/models/backend_services.dart';
import 'package:addis_bites/providers/role_providers.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededSupportNotifier extends SupportNotifier {
  _SeededSupportNotifier(super.ref, SupportDashboard dash) {
    state = AsyncValue.data(dash);
  }
}

final _dash = SupportDashboard(
  reports: const [
    MisconductReport(id: 'rep-1', orderId: 'ord-1', reporterType: 'customer', subjectType: 'courier', subjectId: 'c-1', category: 'late_slow', status: 'open'),
  ],
  strikes: const [],
  refunds: [
    RefundRecord(id: 'rf-1', orderId: 'ord-9', amountEtb: 120, status: 'requested', created: DateTime(2026, 8, 25)),
  ],
  disputes: const [],
  firstResponseMin: 4,
  resolutionHours: 18,
);

void main() {
  testWidgets('support console shows KpiRow + report/refund status pills', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        supportProvider.overrideWith((ref) => _SeededSupportNotifier(ref, _dash)),
      ],
      child: const MaterialApp(home: SupportShell()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(KpiRow), findsAtLeastNWidgets(1));
    expect(find.text('Open reports'), findsOneWidget);
    expect(find.byType(StatusPill), findsAtLeastNWidgets(2)); // report + refund
  });
}