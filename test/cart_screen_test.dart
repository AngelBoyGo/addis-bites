import 'package:addis_bites/core/mock_backend.dart';
import 'package:addis_bites/features/customer/cart_screen.dart';
import 'package:addis_bites/models/catalog_response.dart';
import 'package:addis_bites/models/menu.dart';
import 'package:addis_bites/providers/cart_provider.dart';
import 'package:addis_bites/providers/catalog_provider.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededCatalogNotifier extends CatalogNotifier {
  _SeededCatalogNotifier(super.ref, CatalogResponse catalog) : super(hydrate: false) {
    state = AsyncValue.data(catalog);
  }
}

class _SeededCartNotifier extends CartNotifier {
  _SeededCartNotifier(MenuItem item) {
    add(item, qty: 3, injeraCount: 4, spice: 2);
  }
}

void main() {
  testWidgets('empty cart shows EmptyState with a Browse action', (tester) async {
    final catalog = MockBackend().catalog();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogProvider.overrideWith((ref) => _SeededCatalogNotifier(ref, catalog)),
      ],
      child: const MaterialApp(home: CartScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.textContaining('Browse food'), findsAtLeastNWidgets(1));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
  });

  testWidgets('foot-tier "you save" shows the real savings, not the order total', (tester) async {
    final catalog = MockBackend().catalog();
    const item = MenuItem(
      id: 'sk-doro-wot', merchantId: 'sheger-kitchen', nameEn: 'Doro Wot', nameAm: 'ዶሮ ወጥ', priceEtb: 420,
      hasInjeraStepper: true, spiceLevels: 3,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogProvider.overrideWith((ref) => _SeededCatalogNotifier(ref, catalog)),
        cartProvider.overrideWith((ref) => _SeededCartNotifier(item)),
      ],
      child: const MaterialApp(home: CartScreen()),
    ));
    await tester.pumpAndSettle();

    // Mock config: footFee 45, deliveryFee2km 80, serviceFee 20.
    // subtotal = 420*3 = 1260, delivery (band under2, non-buna) = 80,
    // service 20, surge 0 => total = 1360.
    // footSavings = 80 - 45 = 35.
    expect(find.textContaining('You save 35 ETB'), findsOneWidget,
        reason: 'foot-tier savings must show the real delta (35 ETB), not the total');
    expect(find.textContaining('You save 1360'),
        findsNothing, reason: 'must not advertise the whole order total as savings');
    // Per-head (qty 3): 1260 / 3 = 420 ETB/head.
    expect(find.textContaining('420 ETB/head'), findsOneWidget);
  });
}