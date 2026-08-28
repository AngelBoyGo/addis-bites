import 'package:addis_bites/models/order.dart';
import 'package:addis_bites/theme/app_colors.dart';
import 'package:addis_bites/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmptyState', () {
    testWidgets('shows title, subtitle and optional action', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.storefront,
            title: 'No restaurants',
            subtitle: 'Try clearing filters',
            action: TextButton(onPressed: () {}, child: const Text('Clear')),
          ),
        ),
      ));
      expect(find.text('No restaurants'), findsOneWidget);
      expect(find.text('Try clearing filters'), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('renders without an action', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EmptyState(icon: Icons.inbox, title: 'Empty')),
      ));
      expect(find.text('Empty'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('RetryPanel', () {
    testWidgets('shows message and retry button that fires', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RetryPanel(message: 'connection lost', onRetry: () => tapped++),
        ),
      ));
      expect(find.text('connection lost'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(tapped, 1);
    });
  });

  group('StatusPill', () {
    testWidgets('maps every OrderStatus to a label and works with wire value',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            for (final s in OrderStatus.values) StatusPill(status: s.wire),
          ]),
        ),
      ));
      for (final s in OrderStatus.values) {
        expect(find.textContaining(s.wire), findsOneWidget, reason: s.wire);
      }
    });

    testWidgets('delivered renders with success color', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusPill(status: 'delivered')),
      ));
      final pill = tester.widget<StatusPill>(find.byType(StatusPill));
      expect(pill.resolvedColor, AppColors.tsomGreen);
    });
  });

  group('KpiRow / Kpi', () {
    testWidgets('renders four stat cards in a row', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: KpiRow(
            kpis: const [
              Kpi(label: 'Orders', value: '47'),
              Kpi(label: 'GMV', value: '18450', valueColor: AppColors.primaryGold),
              Kpi(label: 'Couriers', value: '23'),
              Kpi(label: 'Delta', value: '0'),
            ],
          ),
        ),
      ));
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('18450'), findsOneWidget);
      expect(find.text('Couriers'), findsOneWidget);
      expect(find.text('Delta'), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(4));
    });

    testWidgets('gold value color applied', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: KpiRow(kpis: const [Kpi(label: 'GMV', value: '18450', valueColor: AppColors.primaryGold)]),
        ),
      ));
      final t = tester.widget<Text>(find.text('18450'));
      expect(t.style?.color, AppColors.primaryGold);
    });
  });
}