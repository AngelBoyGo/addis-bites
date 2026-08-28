import 'package:addis_bites/core/mock_backend.dart';
import 'package:addis_bites/features/customer/cart_screen.dart';
import 'package:addis_bites/models/catalog_response.dart';
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
}