import 'package:addis_bites/core/mock_backend.dart';
import 'package:addis_bites/features/customer/checkout_screen.dart';
import 'package:addis_bites/models/catalog_response.dart';
import 'package:addis_bites/models/menu.dart';
import 'package:addis_bites/providers/cart_provider.dart';
import 'package:addis_bites/providers/catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededCatalogNotifier extends CatalogNotifier {
  _SeededCatalogNotifier(super.ref, CatalogResponse c) : super(hydrate: false) {
    state = AsyncValue.data(c);
  }
}

class _SeededCartNotifier extends CartNotifier {
  _SeededCartNotifier(MenuItem item) {
    add(item, qty: 2, injeraCount: 4, spice: 2);
  }
}

void main() {
  testWidgets('checkout shows the delivery guarantee note', (tester) async {
    final mb = MockBackend();
    final catalog = mb.catalog();
    const item = MenuItem(
      id: 'sk-doro-wot', merchantId: 'sheger-kitchen', nameEn: 'Doro Wot', nameAm: 'ዶሮ ወጥ', priceEtb: 420,
      hasInjeraStepper: true, spiceLevels: 3,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogProvider.overrideWith((ref) => _SeededCatalogNotifier(ref, catalog)),
        cartProvider.overrideWith((ref) => _SeededCartNotifier(item)),
      ],
      child: const MaterialApp(home: CheckoutScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('On-time guaranteed'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('On-time guaranteed'), findsOneWidget);
  });

  testWidgets('checkout handles catalog-not-loaded without crashing (no null deref)', (tester) async {
    // Cart is non-empty but the catalog provider never loaded (offline / slow
    // start). The estimate/price lock must render without throwing a null check.
    const item = MenuItem(
      id: 'sk-doro-wot', merchantId: 'sheger-kitchen', nameEn: 'Doro Wot', nameAm: 'ዶሮ ወጥ', priceEtb: 420,
      hasInjeraStepper: true, spiceLevels: 3,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        cartProvider.overrideWith((ref) => _SeededCartNotifier(item)),
        // NOTE: catalogProvider intentionally NOT overridden -> stays in loading.
      ],
      child: const MaterialApp(home: CheckoutScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('ETB'), findsWidgets);
  });
}