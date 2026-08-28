import 'package:addis_bites/core/api_client.dart';
import 'package:addis_bites/core/api_types.dart';
import 'package:addis_bites/models/rating.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guarded live integration harness against a running Worker.
///
/// Run it with the Worker up, e.g. `wrangler dev` at 127.0.0.1:8787, via:
///
///   flutter test --dart-define=API_BASE_HTTP_TESTS=true test/worker_http_test.dart
///
/// or against a deployed Worker:
///
///   flutter test --dart-define=API_BASE_HTTP_TESTS=true --dart-define=API_BASE=https://addis-bites.higgsfield.app test/worker_http_test.dart
///
/// Real-world verification requires the /api/* endpoints reachable. The
/// Support/Finance demo accounts are seeded in worker/schema.sql (and mirrored
/// in the in-memory fallback): support -> +25192223331, finance -> +25194445551.
void main() {
  const runLiveHttpTests = bool.fromEnvironment('API_BASE_HTTP_TESTS');
  const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8787');

  group('Worker HTTP Integration Test Harness', () {
    test('ApiClient recognizes custom baseUrl when configured', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8787');
      expect(client.isMock, isFalse);
      expect(client.baseUrl, 'http://127.0.0.1:8787');
    });

    test('ApiClient falls back to MockBackend when baseUrl is empty', () {
      final client = ApiClient(baseUrl: '');
      expect(client.isMock, isTrue);
    });

    if (runLiveHttpTests) {
      test('Live /api/catalog fetch against running worker', () async {
        final client = ApiClient(baseUrl: apiBase);
        final catalog = await client.fetchCatalog();
        expect(catalog.merchants, isNotEmpty);
        expect(catalog.items, isNotEmpty);
        expect(catalog.config.serviceFee, 20);
      });

      test('Live /join and /api/place-order loop against running worker', () async {
        final client = ApiClient(baseUrl: apiBase);
        final session = await client.join(
          phone: '+251911000001',
          name: 'Abebe Bikila',
          role: 'customer',
        );
        expect(session.token, isNotEmpty);
        expect(session.profile.phone, '+251911000001');

        final order = await client.placeOrder(
          token: session.token,
          phone: session.profile.phone,
          merchantId: 'sheger-kitchen',
          items: [{'itemId': 'sk-doro-wot', 'qty': 2, 'injeraCount': 4, 'spice': 2}],
          subCity: 'Bole',
          sefer: 'Bole Medhanealem',
          landmarkText: 'Gate 2',
          paymentMethod: 'chapa',
        );
        expect(order.id, isNotEmpty);
        expect(order.subtotal, 840);
        expect(order.total, 940);
      });

      test('Live support console flow + authz (401/403)', () async {
        final client = ApiClient(baseUrl: apiBase);

        final support = await client.join(
          phone: '+25192223331',
          name: 'Selam Support',
          role: 'support',
        );
        final dash = await client.supportDashboard(support.token);
        expect(dash.reports, isNotEmpty);
        await client.validateReport(support.token, dash.reports.first.id, true);
        await client.approveRefund(support.token, dash.refunds.first.id);

        final customer = await client.join(
          phone: '+25193334441',
          name: 'Demo Customer',
          role: 'customer',
        );
        expect(() => client.supportDashboard(customer.token), throwsA(isA<ApiException>()));
        expect(() => client.financeDashboard(customer.token), throwsA(isA<ApiException>()));
      });

      test('Live finance console flow + ledger balance', () async {
        final client = ApiClient(baseUrl: apiBase);

        final finance = await client.join(
          phone: '+25194445551',
          name: 'Finance Lead',
          role: 'finance',
        );
        final dash = await client.financeDashboard(finance.token);
        expect(dash.ledgerImbalance, 0);
        final pending = dash.batches.where((b) => b.status == 'pending').toList();
        expect(pending, isNotEmpty);
        await client.runPayoutBatch(finance.token, pending.first.id);
        await client.reconcile(finance.token);

        final after = await client.financeDashboard(finance.token);
        expect(after.batches.firstWhere((b) => b.id == pending.first.id).status, 'sent');
        expect(after.ledgerImbalance, 0);
      });

      test('Live merchant + driver + admin + ceo flows (role-gated)', () async {
        final client = ApiClient(baseUrl: apiBase);

        final merchant = await client.join(phone: '+25195556661', name: 'Merchant One', role: 'merchant');
        final queue = await client.merchantQueue(merchant.token);
        expect(queue, isA<List<dynamic>>());
        if (queue.isNotEmpty) {
          await client.merchantAction(merchant.token, queue.first.order.id, 'preparing');
        }

        final driver = await client.join(phone: '+25196667771', name: 'Driver One', role: 'driver');
        final dash = await client.driverDashboard(driver.token);
        if (dash.offers.isNotEmpty) {
          await client.driverAccept(driver.token, dash.offers.first.orderId);
        }

        final admin = await client.join(phone: '+25197778881', name: 'Admin One', role: 'admin');
        final snap = await client.adminSnapshot(admin.token);
        expect(snap.ordersToday, isA<int>());
        expect(snap.gmvEtb, isA<int>());

        final customer = await client.join(phone: '+25193334441', name: 'Customer Two', role: 'customer');
        expect(() => client.adminSnapshot(customer.token), throwsA(isA<ApiException>()));
      });

      test('Live rating + customer dispute + ceo flow', () async {
        final client = ApiClient(baseUrl: apiBase);
        final customer = await client.join(phone: '+25193334441', name: 'Customer Two', role: 'customer');
        await client.submitRating(
          customer.token,
          const RatingSubmission(orderId: 'ord-demo-1', direction: RateDirection.customerToCourier, stars: 5, tags: ['on_time']),
        );
        final dispute = await client.openDispute(customer.token, 'ord-demo-1', 'Never received');
        expect(dispute.id, isNotEmpty);

        final ceo = await client.join(phone: '+25198889991', name: 'CEO One', role: 'ceo');
        final dash = await client.ceoDashboard(ceo.token);
        expect(dash.gmvEtb, isA<int>());
        await client.resolveDispute(ceo.token, dispute.id);
      });
    } else {
      test('Guarded live test notice (run with --dart-define=API_BASE_HTTP_TESTS=true when worker running)', () {
        expect(runLiveHttpTests, isFalse);
      });
    }
  });
}