import 'package:addis_bites/core/mock_backend.dart';
import 'package:addis_bites/features/customer/home_feed.dart';
import 'package:addis_bites/models/catalog_response.dart';
import 'package:addis_bites/models/menu.dart';
import 'package:addis_bites/models/merchant.dart';
import 'package:addis_bites/providers/catalog_provider.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Merchant _merchant(String id) => Merchant(
  id: id,
  nameEn: 'Restaurant $id',
  nameAm: 'ሪስቶራንት',
  sefer: 'Bole',
  subCity: 'Bole',
  lat: 8.99,
  lng: 38.79,
  phoneGsm: '+251911224410',
  prepMin: 25,
  rating: 4.5,
  acceptsCash: true,
  acceptsChapa: true,
  tsomCertified: false,
  halalCertified: false,
  isRestaurantOfTheDay: id == 'm1',
  accent: '#C84B20',
);

CatalogResponse _catalog({List<Merchant>? merchants}) {
  final m = merchants ?? [for (var i = 1; i <= 4; i++) _merchant('m$i')];
  return CatalogResponse(
    merchants: m,
    items: const [
      MenuItem(id: 'it1', merchantId: 'm1', nameEn: 'Doro Wot', nameAm: 'ዶሮ ወጥ', priceEtb: 420),
      MenuItem(id: 'it2', merchantId: 'm2', nameEn: 'Shiro Wot', nameAm: 'ሽሮ ወጥ', priceEtb: 245),
    ],
    config: MockBackend().catalog().config,
    fasting: MockBackend().catalog().fasting,
    subCities: MockBackend().catalog().subCities,
  );
}

/// Test notifier seeded with a fixed catalog, subclassing the real one so the
/// world provider override type-checks.
class _SeededCatalogNotifier extends CatalogNotifier {
  _SeededCatalogNotifier(super.ref, CatalogResponse catalog) : super(hydrate: false) {
    state = AsyncValue.data(catalog);
  }
}

void main() {
  testWidgets('home feed renders merchant cards and the Restaurant of the Day hero', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogProvider.overrideWith((ref) => _SeededCatalogNotifier(ref, _catalog())),
      ],
      child: const MaterialApp(home: HomeFeed()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Restaurant m1'), findsWidgets);
    expect(find.textContaining('commission'), findsOneWidget); // RotD hero
    // drag the (virtualized) list to reveal lower cards
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Restaurant m4'), findsOneWidget);
  });

  testWidgets('empty catalog shows EmptyState, not a blank body', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        catalogProvider.overrideWith((ref) => _SeededCatalogNotifier(ref, _catalog(merchants: const []))),
      ],
      child: const MaterialApp(home: HomeFeed()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });
}