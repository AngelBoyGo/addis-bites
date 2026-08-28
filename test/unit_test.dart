import 'package:addis_bites/models/backend_services.dart';
import 'package:addis_bites/core/fasting_engine.dart';
import 'package:addis_bites/models/cart.dart';
import 'package:addis_bites/models/catalog.dart';
import 'package:addis_bites/models/menu.dart';
import 'package:addis_bites/core/pricing.dart';
import 'package:addis_bites/widgets/map_pin_field.dart';
import 'package:flutter_test/flutter_test.dart';

const _item = MenuItem(
  id: 'test-item',
  merchantId: 'm',
  nameEn: 'Test Dish',
  nameAm: 'ፈት',
  priceEtb: 100,
);

void main() {
  group('FastingEngine', () {
    test('Wednesday and Friday are fasting days', () {
      final wed = DateTime(2026, 8, 26); // Wednesday
      final fri = DateTime(2026, 8, 28); // Friday
      expect(FastingEngine.isWednesdayOrFriday(wed), isTrue);
      expect(FastingEngine.isWednesdayOrFriday(fri), isTrue);
    });

    test('Tuesday and Thursday are not', () {
      expect(FastingEngine.isWednesdayOrFriday(DateTime(2026, 8, 25)), isFalse);
      expect(FastingEngine.isWednesdayOrFriday(DateTime(2026, 8, 27)), isFalse);
    });

    test('server active wins', () {
      const server = FastingState(active: true, labelEn: 'Abiy Tsom', labelAm: 'ጾም', weekly: false);
      expect(FastingEngine.isActive(DateTime(2026, 8, 25), server), isTrue);
    });

    test('weekly flag applies Wed/Fri rule', () {
      const server = FastingState(active: false, labelEn: '', labelAm: '', weekly: true);
      expect(FastingEngine.isActive(DateTime(2026, 8, 26), server), isTrue);
      expect(FastingEngine.isActive(DateTime(2026, 8, 25), server), isFalse);
    });

    test('seasonal fasts (Filseta, Advent, Gahad) detected accurately', () {
      expect(FastingEngine.isSeasonalFast(DateTime(2026, 8, 15)), isTrue); // Filseta
      expect(FastingEngine.isSeasonalFast(DateTime(2026, 12, 10)), isTrue); // Advent
      expect(FastingEngine.isSeasonalFast(DateTime(2026, 1, 18)), isTrue); // Gahad
      expect(FastingEngine.isSeasonalFast(DateTime(2026, 4, 15)), isFalse);
    });
  });

  group('Pricing', () {
    const cfg = AppConfig(
      serviceFee: 20, deliveryFee2km: 80, deliveryFee5km: 150, deliveryFee8km: 240,
      footFee: 45, rainSurge: 40, bunaRunFee: 50, bunaMaxOrder: 150, bunaMaxKm: 1,
      courierSharePct: 80, courierTipsPct: 100, codFloatCap: 1500,
      codSettlementHours: 24, commissionPct: 12, restaurantOfTheDayCommissionPct: 0,
      ackTimeoutSeconds: 90, smsProvider: 'afromessage', smsCostEtb: 0.45,
      rainMode: false, fastingOverride: false, vehicleCurfew: false,
      restaurantOfTheDayId: '', inflationPct: 22, feeMultiplier: 1, demoMode: false,
    );

    test('delivery by distance band', () {
      expect(Pricing.deliveryFee(cfg, DeliveryBand.under2), 80);
      expect(Pricing.deliveryFee(cfg, DeliveryBand.mid5), 150);
      expect(Pricing.deliveryFee(cfg, DeliveryBand.far8), 240);
    });

    test('fee multiplier scales', () {
      const c2 = AppConfig(
        serviceFee: 20, deliveryFee2km: 80, deliveryFee5km: 150, deliveryFee8km: 240,
        footFee: 45, rainSurge: 40, bunaRunFee: 50, bunaMaxOrder: 150, bunaMaxKm: 1,
        courierSharePct: 80, courierTipsPct: 100, codFloatCap: 1500,
        codSettlementHours: 24, commissionPct: 12, restaurantOfTheDayCommissionPct: 0,
        ackTimeoutSeconds: 90, smsProvider: 'afromessage', smsCostEtb: 0.45,
        rainMode: false, fastingOverride: false, vehicleCurfew: false,
        restaurantOfTheDayId: '', inflationPct: 22, feeMultiplier: 1.1, demoMode: false,
      );
      expect(Pricing.deliveryFee(c2, DeliveryBand.under2), 88);
    });

    test('buna run triggers for small orders', () {
      final cart = const Cart(lines: [], band: DeliveryBand.under2);
      expect(Pricing.bunaRun(cfg, cart), 50); // subtotal 0 < 150
    });

    test('rain surge adds line', () {
      const rain = AppConfig(
        serviceFee: 20, deliveryFee2km: 80, deliveryFee5km: 150, deliveryFee8km: 240,
        footFee: 45, rainSurge: 40, bunaRunFee: 50, bunaMaxOrder: 150, bunaMaxKm: 1,
        courierSharePct: 80, courierTipsPct: 100, codFloatCap: 1500,
        codSettlementHours: 24, commissionPct: 12, restaurantOfTheDayCommissionPct: 0,
        ackTimeoutSeconds: 90, smsProvider: 'afromessage', smsCostEtb: 0.45,
        rainMode: true, fastingOverride: false, vehicleCurfew: false,
        restaurantOfTheDayId: '', inflationPct: 22, feeMultiplier: 1, demoMode: false,
      );
      expect(Pricing.surge(rain), 40);
    });
  });

  group('Cart', () {
    test('line key splits on configuration', () {
      final a = const CartLine(item: _item, qty: 1, injeraCount: 2, spice: 1);
      final b = const CartLine(item: _item, qty: 1, injeraCount: 4, spice: 1);
      expect(a.key, isNot(b.key));
    });

    test('withLine merges same config, splits different', () {
      const cart = Cart();
      final c1 = cart.withLine(const CartLine(item: _item, qty: 1));
      final c2 = c1.withLine(const CartLine(item: _item, qty: 2));
      expect(c2.lines.length, 1);
      expect(c2.lines.first.qty, 3);
      final c3 = c2.withLine(const CartLine(item: _item, qty: 1, injeraCount: 4));
      expect(c3.lines.length, 2);
    });
  });

  group('Map & Geolocation', () {
    test('plusCodeFor produces standard Open Location Code format', () {
      final code = plusCodeFor(8.9888, 38.7872); // Addis Ababa Bole
      expect(code.contains('+'), isTrue);
      expect(code.length, 11); // 8 chars + '+' + 2 chars
      expect(code, '6GWWXQQP+GV');
    });
  });

  group('BackendServices & Trust/Safety', () {
    test('StrikeLevel labels match progressive enforcement policy', () {
      expect(StrikeLevel.warning.label, contains('1st'));
      expect(StrikeLevel.suspendWeek.label, contains('1 week'));
      expect(StrikeLevel.suspendMonth.label, contains('1 month'));
      expect(StrikeLevel.permanent.label, contains('Permanent'));
    });

    test('StrikeRecord roundtrip serialization', () {
      final now = DateTime(2026, 8, 26, 12, 0);
      final record = StrikeRecord(
        subjectType: 'courier',
        subjectId: 'c-101',
        validatedCount: 2,
        level: StrikeLevel.suspendWeek,
        issuedAt: now,
      );
      final json = record.toJson();
      final roundTrip = StrikeRecord.fromJson(json);
      expect(roundTrip.subjectType, 'courier');
      expect(roundTrip.subjectId, 'c-101');
      expect(roundTrip.validatedCount, 2);
      expect(roundTrip.level, StrikeLevel.suspendWeek);
    });

    test('MisconductReport roundtrip serialization', () {
      const report = MisconductReport(
        id: 'rep-1',
        orderId: 'ord-123',
        reporterType: 'customer',
        subjectType: 'courier',
        subjectId: 'drv-2',
        category: 'tampered_seal',
        status: 'open',
      );
      final json = report.toJson();
      final parsed = MisconductReport.fromJson(json);
      expect(parsed.id, 'rep-1');
      expect(parsed.category, 'tampered_seal');
      expect(parsed.status, 'open');
    });

    test('PayoutBatch and LedgerEntry balance invariants', () {
      final batch = PayoutBatch(
        id: 'pb-01',
        method: 'telebirr_b2c',
        status: 'pending',
        totalEtb: 15400,
        count: 12,
        scheduledFor: DateTime(2026, 8, 26, 10),
      );
      expect(batch.totalEtb, 15400);

      const debit = LedgerEntry(txnId: 'tx-1', account: 'settlement_holding', debit: 0, credit: 500);
      const credit = LedgerEntry(txnId: 'tx-1', account: 'merchant_payable', debit: 500, credit: 0);
      const entries = [debit, credit];
      final imbalance = entries.fold<int>(0, (sum, e) => sum + e.signed);
      expect(imbalance, 0);
    });
  });
}