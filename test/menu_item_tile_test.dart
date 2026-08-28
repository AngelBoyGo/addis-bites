import 'package:addis_bites/models/menu.dart';
import 'package:addis_bites/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(body: child),
  ),
);

void main() {
  const available = MenuItem(
    id: 'a1', merchantId: 'm', nameEn: 'Doro Wot', nameAm: 'ዶሮ ወጥ', priceEtb: 420,
  );
  const soldOut = MenuItem(
    id: 's1', merchantId: 'm', nameEn: 'Shiro Wot', nameAm: 'ሽሮ ወጥ', priceEtb: 245, isAvailable: false,
  );

  testWidgets('sold-out item shows a sold-out pill and is not tappable', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(
      MenuItemTile(item: soldOut, onTap: () => tapped++),
    ));
    expect(find.textContaining('Sold out'), findsOneWidget);
    await tester.tap(find.byType(MenuItemTile));
    await tester.pump();
    expect(tapped, 0); // tap-through disabled
  });

  testWidgets('available item remains tappable and has no sold-out pill', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(
      MenuItemTile(item: available, onTap: () => tapped++),
    ));
    expect(find.textContaining('Sold out'), findsNothing);
    expect(find.text('420 ETB'), findsOneWidget);
    await tester.tap(find.byType(MenuItemTile));
    expect(tapped, 1);
  });
}