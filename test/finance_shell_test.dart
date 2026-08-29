import 'package:addis_bites/features/dash/finance_shell.dart';
import 'package:addis_bites/models/backend_services.dart';
import 'package:addis_bites/providers/role_providers.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededFinanceNotifier extends FinanceNotifier {
  _SeededFinanceNotifier(super.ref, FinanceDashboard dash) {
    state = AsyncValue.data(dash);
  }
}

final _dash = FinanceDashboard(
  ledgerImbalance: 0,
  unreconciled24h: 3,
  payoutFailureCount: 1,
  takeRateNetPromos: 2.5,
  batches: [
    PayoutBatch(
      id: 'batch-1',
      method: 'Telebirr',
      status: 'pending',
      totalEtb: 5000,
      count: 10,
      scheduledFor: DateTime(2026, 8, 26),
    ),
  ],
  ledger: [
    LedgerEntry(
      txnId: 'tx-1',
      account: 'Cash',
      debit: 0,
      credit: 1200,
    ),
    LedgerEntry(
      txnId: 'tx-2',
      account: 'Revenue',
      debit: 800,
      credit: 0,
    ),
  ],
);

void main() {
  testWidgets('finance console shows KpiRow + status pill in batch ListTile', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        financeProvider.overrideWith((ref) => _SeededFinanceNotifier(ref, _dash)),
      ],
      child: const MaterialApp(home: FinanceShell()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(KpiRow), findsAtLeastNWidgets(1));
    expect(find.text('Ledger Δ'), findsOneWidget);
    expect(find.text('Unreconciled'), findsOneWidget);
    expect(find.text('Payout failures'), findsOneWidget);
    expect(find.text('Take rate'), findsOneWidget);
    expect(find.byType(StatusPill), findsOneWidget); // batch-1 pending
  });
}