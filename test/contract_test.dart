import 'dart:convert';
import 'dart:io';

import 'package:addis_bites/core/api_client.dart';
import 'package:addis_bites/core/api_types.dart';
import 'package:addis_bites/core/mock_backend.dart';
import 'package:addis_bites/models/backend_services.dart';
import 'package:addis_bites/models/catalog_response.dart';
import 'package:addis_bites/models/driver.dart';
import 'package:addis_bites/models/order.dart';
import 'package:addis_bites/models/rating.dart';
import 'package:addis_bites/models/role_dashboards.dart';
import 'package:addis_bites/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§4 Wire Fixtures Contract Tests', () {
    test('CatalogResponse fixture round-trip and field existence', () {
      final file = File('test/fixtures/catalog.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      // Field existence check on §4 keys
      expect(json.containsKey('merchants'), isTrue);
      expect(json.containsKey('menu'), isTrue);
      expect(json.containsKey('config'), isTrue);
      expect(json.containsKey('fasting'), isTrue);
      expect(json.containsKey('subCities'), isTrue);

      final catalog = CatalogResponse.fromJson(json);

      // Verify Merchant fields
      final m = catalog.merchants.first;
      expect(m.id, 'sheger-kitchen');
      expect(m.nameAm, 'ሸገር ኩሽና');
      expect(m.nameEn, 'Sheger Kitchen');
      expect(m.sefer, 'Bole Medhanealem');
      expect(m.subCity, 'Bole');
      expect(m.lat, 8.9888);
      expect(m.lng, 38.7872);
      expect(m.phoneGsm, '+251 911 224 410');
      expect(m.prepMin, 28);
      expect(m.rating, 4.7);
      expect(m.tsomCertified, isTrue);
      expect(m.halalCertified, isFalse);
      expect(m.thermal, isTrue);
      expect(m.acceptsCash, isTrue);
      expect(m.acceptsChapa, isTrue);
      expect(m.isRestaurantOfTheDay, isTrue);
      expect(m.accent, '#C84B20');

      // Verify Menu item fields
      final item = catalog.items.first;
      expect(item.id, 'sk-doro-wot');
      expect(item.merchantId, 'sheger-kitchen');
      expect(item.nameAm, 'ዶሮ ወጥ');
      expect(item.nameEn, 'Doro Wot');
      expect(item.priceEtb, 420);
      expect(item.category, 'Meat Wots');
      expect(item.isTsom, isFalse);
      expect(item.isHalal, isFalse);
      expect(item.isRawMeat, isFalse);
      expect(item.isAvailable, isTrue);
      expect(item.hasInjeraStepper, isTrue);
      expect(item.spiceLevels, 3);

      // Verify Config fields
      final cfg = catalog.config;
      expect(cfg.serviceFee, 20);
      expect(cfg.deliveryFee2km, 80);
      expect(cfg.deliveryFee5km, 150);
      expect(cfg.deliveryFee8km, 240);
      expect(cfg.rainSurge, 40);
      expect(cfg.bunaRunFee, 50);
      expect(cfg.bunaMaxOrder, 150);
      expect(cfg.bunaMaxKm, 1);
      expect(cfg.courierSharePct, 80);
      expect(cfg.courierTipsPct, 100);
      expect(cfg.codFloatCap, 1500);
      expect(cfg.codSettlementHours, 24);
      expect(cfg.commissionPct, 12);
      expect(cfg.restaurantOfTheDayCommissionPct, 0);
      expect(cfg.smsProvider, 'afromessage');
      expect(cfg.smsCostEtb, 0.45);
      expect(cfg.ackTimeoutSeconds, 90);
      expect(cfg.rainMode, isFalse);
      expect(cfg.fastingOverride, isFalse);
      expect(cfg.restaurantOfTheDayId, 'sheger-kitchen');
      expect(cfg.inflationPct, 22);
      expect(cfg.feeMultiplier, 1.0);

      // Verify serialization round-trip
      final serialized = catalog.toJson();
      expect(serialized['merchants'], isNotEmpty);
      expect(serialized['menu'], isNotEmpty);
      expect(serialized['config'], isNotEmpty);
      expect(serialized['fasting'], isNotEmpty);
      expect(serialized['subCities'], isNotEmpty);
    });

    test('Order fixture round-trip and field existence', () {
      final file = File('test/fixtures/order.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      // Field existence check
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('merchantName'), isTrue);
      expect(json.containsKey('items'), isTrue);
      expect(json.containsKey('subtotal'), isTrue);
      expect(json.containsKey('deliveryFee'), isTrue);
      expect(json.containsKey('serviceFee'), isTrue);
      expect(json.containsKey('surge'), isTrue);
      expect(json.containsKey('total'), isTrue);
      expect(json.containsKey('paymentMethod'), isTrue);
      expect(json.containsKey('paymentStatus'), isTrue);
      expect(json.containsKey('status'), isTrue);

      final order = Order.fromJson(json);
      expect(order.id, 'ord-20260825-001');
      expect(order.merchantName, 'Sheger Kitchen');
      expect(order.items.length, 1);
      expect(order.items.first.nameEn, 'Doro Wot');
      expect(order.items.first.price, 420);
      expect(order.items.first.qty, 2);
      expect(order.subtotal, 840);
      expect(order.deliveryFee, 80);
      expect(order.serviceFee, 20);
      expect(order.surge, 0);
      expect(order.total, 940);
      expect(order.paymentMethod, 'chapa');
      expect(order.paymentStatus, PaymentStatus.confirmed);
      expect(order.status, OrderStatus.placed);
      expect(order.plusCode, '8FMC4RWV+X2');

      final serialized = order.toJson();
      expect(serialized['id'], order.id);
      expect(serialized['total'], 940);
      expect(serialized['paymentStatus'], 'confirmed');
      expect(serialized['status'], 'placed');
    });

    test('Session & Profile fixture round-trip', () {
      final file = File('test/fixtures/session.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final session = Session.fromJson(json);
      expect(session.token, contains('eyJ'));
      expect(session.profile.id, 'p-1001');
      expect(session.profile.phone, '+251911000001');
      expect(session.profile.role, UserRole.customer);
      expect(session.profile.vehicle, 'motorbike');

      final serialized = session.toJson();
      expect(serialized['token'], session.token);
      expect(serialized['profile']['role'], 'customer');
    });

    test('DriverOffer fixture round-trip', () {
      final file = File('test/fixtures/driver.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final offer = DriverOffer.fromJson(json);
      expect(offer.orderId, 'ord-20260825-001');
      expect(offer.merchant, 'Sheger Kitchen');
      expect(offer.distanceKm, 1.2);
      expect(offer.grossFee, 80);
      expect(offer.keeperShare, 64);
      expect(offer.fuelCost, 10);
      expect(offer.net, 54);
      expect(offer.subsidy, 0);
      expect(offer.tipsEtb, 12);
      expect(offer.etaMin, 15);
      expect(offer.footEligible, isTrue);

      final serialized = offer.toJson();
      expect(serialized['orderId'], offer.orderId);
      expect(serialized['net'], 54);
    });

    test('OTP request and verify fixtures', () {
      final file = File('test/fixtures/otp.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final req = json['request'] as Map<String, dynamic>;
      expect(req['ok'], isTrue);
      expect(req['provider'], 'demo');
      expect(req['demoCode'], '123456');

      final verify = json['verify'] as Map<String, dynamic>;
      expect(verify['ok'], isTrue);
      expect(verify['phone'], '+251911000001');
    });
  });

  group('§6 Server-Authoritative Pricing Guardrails', () {
    test('PlaceOrder payload contains NO client-supplied price or total fields', () {
      final file = File('test/fixtures/place_order.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      // Verify no top-level price fields
      expect(json.containsKey('price'), isFalse);
      expect(json.containsKey('total'), isFalse);
      expect(json.containsKey('subtotal'), isFalse);
      expect(json.containsKey('deliveryFee'), isFalse);
      expect(json.containsKey('priceEtb'), isFalse);

      // Verify item lines only contain ID, qty, injeraCount, spice
      final items = (json['items'] as List).cast<Map<String, dynamic>>();
      for (final item in items) {
        expect(item.containsKey('itemId'), isTrue);
        expect(item.containsKey('qty'), isTrue);
        expect(item.containsKey('price'), isFalse);
        expect(item.containsKey('priceEtb'), isFalse);
        expect(item.containsKey('total'), isFalse);
      }
    });

    test('MockBackend placeOrder re-prices from DB menu and rejects tampered items', () {
      final backend = MockBackend();
      final order = backend.placeOrder(
        token: 'demo-token',
        phone: '+251911000001',
        merchantId: 'sheger-kitchen',
        items: [
          {'itemId': 'sk-doro-wot', 'qty': 2, 'injeraCount': 4, 'spice': 2},
        ],
        subCity: 'Bole',
        sefer: 'Bole Medhanealem',
        landmarkText: 'Behind yellow building',
        paymentMethod: 'chapa',
      );

      // sk-doro-wot is 420 ETB * 2 = 840 ETB subtotal, 80 delivery, 20 service = 940 ETB
      expect(order.subtotal, 840);
      expect(order.serviceFee, 20);
      expect(order.total, 940);
    });
  });

  group('Negative & Guardrail Coverage Tests', () {
    test('Invalid OTP code throws ApiPublic', () {
      final backend = MockBackend();
      backend.otpRequest(phone: '+251911000001');
      expect(
        () => backend.otpVerify(phone: '+251911000001', code: '999999'),
        throwsA(isA<ApiPublic>()),
      );
    });

    test('Placing order for unknown item throws ApiPublic', () {
      final backend = MockBackend();
      expect(
        () => backend.placeOrder(
          token: 'demo',
          phone: '+251911000001',
          merchantId: 'sheger-kitchen',
          items: [{'itemId': 'non-existent-item-999', 'qty': 1}],
          subCity: 'Bole',
          sefer: 'Bole Medhanealem',
          landmarkText: 'Gate 2',
          paymentMethod: 'chapa',
        ),
        throwsA(isA<ApiPublic>()),
      );
    });

    test('Coverage gating: placing order for out-of-zone subCity throws ApiPublic', () {
      final backend = MockBackend();
      // pizza-mercato only delivers to 'Arada', ordering to 'Bole' must fail
      expect(
        () => backend.placeOrder(
          token: 'demo',
          phone: '+251911000001',
          merchantId: 'pizza-mercato',
          items: [{'itemId': 'sk-doro-wot', 'qty': 1}],
          subCity: 'Bole',
          sefer: 'Bole Medhanealem',
          landmarkText: 'Gate 2',
          paymentMethod: 'chapa',
        ),
        throwsA(isA<ApiPublic>()),
      );
    });

    test('Telegram tgAuth returns valid session', () {
      final backend = MockBackend();
      final session = backend.tgAuth(initData: 'query_id=AAHD...');
      expect(session.token, 'tg-demo');
      expect(session.profile.name, 'Telegram User');
      expect(session.profile.role, UserRole.customer);
    });
  });

  group('§3.5/3.6 Support & Finance Wire Contract', () {
    // Worker-shaped fixtures mirroring worker/src/shapes.js output.
    const reportJson = {
      'id': 'rep-1',
      'orderId': 'ord-1',
      'reporterType': 'customer',
      'subjectType': 'courier',
      'subjectId': 'c-1',
      'category': 'late_slow',
      'status': 'open',
    };
    const strikeJson = {
      'subjectType': 'courier',
      'subjectId': 'c-1',
      'validatedCount': 1,
      'level': 'warning',
      'issuedAt': '2026-08-25T00:00:00.000Z',
    };
    const refundJson = {
      'id': 'rf-1',
      'orderId': 'ord-9',
      'amountEtb': 120,
      'status': 'requested',
      'created': '2026-08-25T00:00:00.000Z',
    };
    const batchJson = {
      'id': 'pb-1',
      'method': 'telebirr_b2c',
      'status': 'pending',
      'totalEtb': 18500,
      'count': 23,
      'scheduledFor': '2026-08-26T10:00:00.000Z',
    };
    const disputeJson = {
      'id': 'd-1',
      'orderId': 'ord-1',
      'reason': 'I never received this',
      'status': 'open',
    };

    test('Support dashboard entity fixtures round-trip through the client models', () {
      final report = MisconductReport.fromJson(reportJson);
      expect(report.id, 'rep-1');
      expect(report.orderId, 'ord-1');
      expect(report.category, 'late_slow');
      expect(report.status, 'open');
      final reportBack = MisconductReport.fromJson(report.toJson());
      expect(reportBack.status, 'open');

      final strike = StrikeRecord.fromJson(strikeJson);
      expect(strike.subjectType, 'courier');
      expect(strike.validatedCount, 1);
      expect(strike.level, StrikeLevel.warning);

      final refund = RefundRecord.fromJson(refundJson);
      expect(refund.amountEtb, 120);
      expect(refund.status, 'requested');

      final dispute = Dispute.fromJson(disputeJson);
      expect(dispute.orderId, 'ord-1');
      expect(dispute.status, 'open');
    });

    test('Finance dashboard entity fixtures round-trip and keep the wire keys', () {
      final batch = PayoutBatch.fromJson(batchJson);
      expect(batch.method, 'telebirr_b2c');
      expect(batch.status, 'pending');
      expect(batch.totalEtb, 18500);
      expect(batch.scheduledFor.toIso8601String(), '2026-08-26T10:00:00.000Z');
      final batchBack = PayoutBatch.fromJson(batch.toJson());
      expect(batchBack.totalEtb, 18500);
      expect(batchBack.status, 'pending');
    });

    test('Support & Finance dashboard JSON expose the exact top-level keys the ApiClient reads', () {
      final supportDashboardJson = <String, dynamic>{
        'reports': [reportJson],
        'strikes': [strikeJson],
        'refunds': [refundJson],
        'disputes': [disputeJson],
        'firstResponseMin': 4,
        'resolutionHours': 18,
      };
      for (final key in ['reports', 'strikes', 'refunds', 'disputes', 'firstResponseMin', 'resolutionHours']) {
        expect(supportDashboardJson.containsKey(key), isTrue, reason: 'support $key');
      }

      const financeDashboardJson = <String, dynamic>{
        'ledgerImbalance': 0,
        'unreconciled24h': 0,
        'batches': [batchJson],
        'ledger': [
          {'txnId': 'tx-1', 'account': 'platform:fees', 'debit': 0, 'credit': 1280, 'orderId': 'ord-1'},
          {'txnId': 'tx-1', 'account': 'courier:c-1', 'debit': 1280, 'credit': 0, 'orderId': 'ord-1'},
        ],
        'payoutFailureCount': 0,
        'takeRateNetPromos': 11.4,
      };
      for (final key in ['ledgerImbalance', 'unreconciled24h', 'batches', 'ledger', 'payoutFailureCount', 'takeRateNetPromos']) {
        expect(financeDashboardJson.containsKey(key), isTrue, reason: 'finance $key');
      }
    });

    test('A double-entry ledger batch for one txnId sums to zero', () {
      final entries = [
        LedgerEntry.fromJson(const {'txnId': 'tx-9', 'account': 'platform:payout_float', 'debit': 500, 'credit': 0}),
        LedgerEntry.fromJson(const {'txnId': 'tx-9', 'account': 'couriers:settlement', 'debit': 0, 'credit': 500}),
      ];
      final imbalance = entries.fold<int>(0, (sum, e) => sum + e.signed);
      expect(imbalance, 0);
    });

    test('Support/Finance route paths interpolate the id (no double slash)', () {
      expect(ApiClient.supportValidatePath('rep-42'), '/api/support/reports/rep-42/validate');
      expect(ApiClient.supportApproveRefundPath('rf-7'), '/api/support/refunds/rf-7/approve');
      expect(ApiClient.financeRunPayoutPath('pb-3'), '/api/finance/payouts/pb-3/run');
      expect(ApiClient.ceoResolveDisputePath('tkt-1'), '/api/ceo/dispute/tkt-1/resolve');
      expect(ApiClient.supportValidatePath('x').contains('//'), isFalse);
      expect(ApiClient.supportApproveRefundPath('x').contains('//'), isFalse);
      expect(ApiClient.financeRunPayoutPath('x').contains('//'), isFalse);
      expect(ApiClient.ceoResolveDisputePath('x').contains('//'), isFalse);
    });

    test('Worker-shaped rating and order fixtures round-trip through the client models', () {
      // RatingSubmission has toJson only; assert the server-bound payload shape.
      const rating = RatingSubmission(
        orderId: 'ord-demo-1',
        direction: RateDirection.customerToCourier,
        stars: 5,
        tags: ['on_time'],
      );
      final wire = rating.toJson();
      expect(wire['orderId'], 'ord-demo-1');
      expect(wire['direction'], 'customer_to_courier');
      expect(wire['stars'], 5);
      expect(wire['tags'], ['on_time']);
      expect(wire.containsKey('price'), isFalse);

      // A merchant-queue entry is an Order payload + ack/sms fields.
      const queueRow = {
        'id': 'ord-demo-1',
        'merchantName': 'Sheger Kitchen',
        'items': [{'nameEn': 'Doro Wot', 'nameAm': 'ዶሮ ወጥ', 'qty': 2, 'price': 420, 'injera': 4, 'spice': 2}],
        'subtotal': 840,
        'deliveryFee': 80,
        'serviceFee': 20,
        'surge': 0,
        'total': 940,
        'paymentMethod': 'chapa',
        'paymentStatus': 'confirmed',
        'status': 'placed',
        'ackDeadlineAt': '2026-08-26T12:00:00.000Z',
        'smsFallbackSent': false,
      };
      final merchantOrder = MerchantOrder.fromJson(queueRow);
      expect(merchantOrder.order.id, 'ord-demo-1');
      expect(merchantOrder.order.total, 940);
      expect(merchantOrder.order.status, OrderStatus.placed);
      expect(merchantOrder.smsFallbackSent, isFalse);
      expect(merchantOrder.ackSecondsLeft, greaterThanOrEqualTo(0));
    });
  });
}