import 'package:addis_bites/core/mock_backend.dart';
import 'package:addis_bites/features/dash/merchant_shell.dart';
import 'package:addis_bites/models/catalog_response.dart';
import 'package:addis_bites/models/order.dart';
import 'package:addis_bites/models/role_dashboards.dart';
import 'package:addis_bites/providers/catalog_provider.dart';
import 'package:addis_bites/providers/role_providers.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededCatalogNotifier extends CatalogNotifier {
  _SeededCatalogNotifier(super.ref, CatalogResponse c) : super(hydrate: false) {
    state = AsyncValue.data(c);
  }
}

class _SeededMerchantNotifier extends MerchantNotifier {
  _SeededMerchantNotifier(super.ref, List<MerchantOrder> entries) {
    state = AsyncValue.data(entries);
  }
}

Order _order(String id) => Order(
  id: id,
  merchantName: 'Sheger Kitchen',
  items: const [],
  subtotal: 840,
  deliveryFee: 80,
  serviceFee: 20,
  surge: 0,
  total: 940,
  paymentMethod: 'chapa',
  paymentStatus: PaymentStatus.confirmed,
  status: OrderStatus.placed,
  createdAt: DateTime(2026, 8, 27),
  ackDeadlineAt: DateTime.now().add(const Duration(seconds: 60)),
);

void main() {
  testWidgets('merchant shell shows KPI row + status pill for a queued order', (tester) async {
    final mb = MockBackend();
    final catalog = mb.catalog();
    final entries = [MerchantOrder(order: _order('ord-1'), ackDeadlineAt: DateTime.now().add(const Duration(seconds: 60)))];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogProvider.overrideWith((ref) => _SeededCatalogNotifier(ref, catalog)),
        merchantQueueProvider.overrideWith((ref) => _SeededMerchantNotifier(ref, entries)),
      ],
      child: const MaterialApp(home: MerchantShell()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(KpiRow), findsAtLeastNWidgets(1));
    expect(find.byType(StatusPill), findsAtLeastNWidgets(1));

  });
}