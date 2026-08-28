import 'dart:io';

import 'package:addis_bites/models/catalog.dart';
import 'package:addis_bites/models/catalog_response.dart';
import 'package:addis_bites/models/menu.dart';
import 'package:addis_bites/models/merchant.dart';
import 'package:addis_bites/providers/catalog_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('addisbites_hive_test');
    Hive.init(tempDir.path);
  });

  test('CatalogCache persists catalog JSON across an app restart (Hive)', () async {
    const catalogItem = MenuItem(
      id: 'sk-doro-wot',
      merchantId: 'sheger-kitchen',
      nameEn: 'Doro Wot',
      nameAm: 'ዶሮ ወጥ',
      priceEtb: 420,
      category: 'Meat Wots',
    );
    const merchant = Merchant(
      id: 'sheger-kitchen',
      nameEn: 'Sheger Kitchen',
      nameAm: 'ሸገር ኩሽና',
      sefer: 'Bole Medhanealem',
      subCity: 'Bole',
    );
    const config = AppConfig(
      serviceFee: 20, deliveryFee2km: 80, deliveryFee5km: 150, deliveryFee8km: 240,
      footFee: 45, rainSurge: 40, bunaRunFee: 50, bunaMaxOrder: 150, bunaMaxKm: 1,
      courierSharePct: 80, courierTipsPct: 100, codFloatCap: 1500,
      codSettlementHours: 24, commissionPct: 12, restaurantOfTheDayCommissionPct: 0,
      ackTimeoutSeconds: 90, smsProvider: 'afromessage', smsCostEtb: 0.45,
      rainMode: false, fastingOverride: false, vehicleCurfew: false,
      restaurantOfTheDayId: '', inflationPct: 22, feeMultiplier: 1, demoMode: false,
    );
    const fasting = FastingState.empty;
    const subCity = SubCity(id: 'bole', nameEn: 'Bole', nameAm: 'ቦሌ');

    final catalog = CatalogResponse(
      merchants: const [merchant],
      items: const [catalogItem],
      config: config,
      fasting: fasting,
      subCities: const [subCity],
    );

    await CatalogCache.write(catalog);
    final restored = await CatalogCache.read();

    expect(restored, isNotNull);
    expect(restored!.items, hasLength(1));
    expect(restored.items.first.id, 'sk-doro-wot');
    expect(restored.items.first.priceEtb, 420);
    expect(restored.merchants.first.id, 'sheger-kitchen');
    expect(restored.config.serviceFee, 20);
    expect(restored.subCities.first.nameEn, 'Bole');
  });
}