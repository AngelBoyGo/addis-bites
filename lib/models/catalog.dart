/// Wire models matching the backend catalog contract (§4 / §6 of the spec).
/// The client NEVER sends prices — prices here reflect cached server data used
/// for display only; the server is authoritative on checkout.
library;

class FastingState {
  const FastingState({
    required this.active,
    required this.labelEn,
    required this.labelAm,
    required this.weekly,
  });

  final bool active;
  final String labelEn;
  final String labelAm;
  final bool weekly;

  factory FastingState.fromJson(Map<String, dynamic> json) => FastingState(
    active: json['active'] as bool? ?? false,
    labelEn: json['labelEn'] as String? ?? '',
    labelAm: json['labelAm'] as String? ?? '',
    weekly: json['weekly'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'active': active,
    'labelEn': labelEn,
    'labelAm': labelAm,
    'weekly': weekly,
  };

  static const empty = FastingState(active: false, labelEn: '', labelAm: '', weekly: false);
}

class SubCity {
  const SubCity({required this.id, required this.nameEn, required this.nameAm});

  final String id;
  final String nameEn;
  final String nameAm;

  factory SubCity.fromJson(Map<String, dynamic> json) => SubCity(
    id: json['id'] as String? ?? '',
    nameEn: json['nameEn'] as String? ?? '',
    nameAm: json['nameAm'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'nameEn': nameEn, 'nameAm': nameAm};
}

class AppConfig {
  const AppConfig({
    required this.serviceFee,
    required this.deliveryFee2km,
    required this.deliveryFee5km,
    required this.deliveryFee8km,
    required this.footFee,
    required this.rainSurge,
    required this.bunaRunFee,
    required this.bunaMaxOrder,
    required this.bunaMaxKm,
    required this.courierSharePct,
    required this.courierTipsPct,
    required this.codFloatCap,
    required this.codSettlementHours,
    required this.commissionPct,
    required this.restaurantOfTheDayCommissionPct,
    required this.ackTimeoutSeconds,
    required this.smsProvider,
    required this.smsCostEtb,
    required this.rainMode,
    required this.fastingOverride,
    required this.vehicleCurfew,
    required this.restaurantOfTheDayId,
    required this.inflationPct,
    required this.feeMultiplier,
    required this.demoMode,
  });

  final int serviceFee;
  final int deliveryFee2km;
  final int deliveryFee5km;
  final int deliveryFee8km;
  final int footFee; // ≤1.5km zero-fuel tier (§6: 45 ETB)
  final int rainSurge;
  final int bunaRunFee;
  final int bunaMaxOrder;
  final int bunaMaxKm;
  final int courierSharePct;
  final int courierTipsPct;
  final int codFloatCap;
  final int codSettlementHours;
  final int commissionPct;
  final int restaurantOfTheDayCommissionPct;
  final int ackTimeoutSeconds;
  final String smsProvider;
  final double smsCostEtb;
  final bool rainMode;
  final bool fastingOverride;
  final bool vehicleCurfew; // §5.8b evening motorbike restriction
  final String restaurantOfTheDayId;
  final int inflationPct;
  final double feeMultiplier;
  final bool demoMode;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    String? s(Object? v) => v?.toString();
    int? i(Object? v) => v is num ? v.toInt() : int.tryParse(s(v) ?? '');
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse(s(v) ?? '');
    return AppConfig(
      serviceFee: i(json['serviceFee']) ?? 20,
      deliveryFee2km: i(json['deliveryFee2km']) ?? 80,
      deliveryFee5km: i(json['deliveryFee5km']) ?? 150,
      deliveryFee8km: i(json['deliveryFee8km']) ?? 240,
      footFee: i(json['footFee']) ?? 45,
      rainSurge: i(json['rainSurge']) ?? 40,
      bunaRunFee: i(json['bunaRunFee']) ?? 50,
      bunaMaxOrder: i(json['bunaMaxOrder']) ?? 150,
      bunaMaxKm: i(json['bunaMaxKm']) ?? 1,
      courierSharePct: i(json['courierSharePct']) ?? 80,
      courierTipsPct: i(json['courierTipsPct']) ?? 100,
      codFloatCap: i(json['codFloatCap']) ?? 1500,
      codSettlementHours: i(json['codSettlementHours']) ?? 24,
      commissionPct: i(json['commissionPct']) ?? 12,
      restaurantOfTheDayCommissionPct: i(json['restaurantOfTheDayCommissionPct']) ?? 0,
      ackTimeoutSeconds: i(json['ackTimeoutSeconds']) ?? 90,
      smsProvider: s(json['smsProvider']) ?? 'afromessage',
      smsCostEtb: d(json['smsCostEtb']) ?? 0.45,
      rainMode: json['rainMode'] as bool? ?? false,
      fastingOverride: json['fastingOverride'] as bool? ?? false,
      vehicleCurfew: json['vehicleCurfew'] as bool? ?? false,
      restaurantOfTheDayId: json['restaurantOfTheDayId'] as String? ?? '',
      inflationPct: i(json['inflationPct']) ?? 22,
      feeMultiplier: d(json['feeMultiplier']) ?? 1.0,
      demoMode: (json['demoMode'] ?? json['demo']) as bool? ?? false,
    );
  }

  AppConfig copyWith({
    int? serviceFee,
    int? deliveryFee2km,
    int? deliveryFee5km,
    int? deliveryFee8km,
    int? footFee,
    int? rainSurge,
    int? bunaRunFee,
    int? bunaMaxOrder,
    int? bunaMaxKm,
    int? courierSharePct,
    int? courierTipsPct,
    int? codFloatCap,
    int? codSettlementHours,
    int? commissionPct,
    int? restaurantOfTheDayCommissionPct,
    int? ackTimeoutSeconds,
    String? smsProvider,
    double? smsCostEtb,
    bool? rainMode,
    bool? fastingOverride,
    bool? vehicleCurfew,
    String? restaurantOfTheDayId,
    int? inflationPct,
    double? feeMultiplier,
    bool? demoMode,
  }) => AppConfig(
    serviceFee: serviceFee ?? this.serviceFee,
    deliveryFee2km: deliveryFee2km ?? this.deliveryFee2km,
    deliveryFee5km: deliveryFee5km ?? this.deliveryFee5km,
    deliveryFee8km: deliveryFee8km ?? this.deliveryFee8km,
    footFee: footFee ?? this.footFee,
    rainSurge: rainSurge ?? this.rainSurge,
    bunaRunFee: bunaRunFee ?? this.bunaRunFee,
    bunaMaxOrder: bunaMaxOrder ?? this.bunaMaxOrder,
    bunaMaxKm: bunaMaxKm ?? this.bunaMaxKm,
    courierSharePct: courierSharePct ?? this.courierSharePct,
    courierTipsPct: courierTipsPct ?? this.courierTipsPct,
    codFloatCap: codFloatCap ?? this.codFloatCap,
    codSettlementHours: codSettlementHours ?? this.codSettlementHours,
    commissionPct: commissionPct ?? this.commissionPct,
    restaurantOfTheDayCommissionPct: restaurantOfTheDayCommissionPct ?? this.restaurantOfTheDayCommissionPct,
    ackTimeoutSeconds: ackTimeoutSeconds ?? this.ackTimeoutSeconds,
    smsProvider: smsProvider ?? this.smsProvider,
    smsCostEtb: smsCostEtb ?? this.smsCostEtb,
    rainMode: rainMode ?? this.rainMode,
    fastingOverride: fastingOverride ?? this.fastingOverride,
    vehicleCurfew: vehicleCurfew ?? this.vehicleCurfew,
    restaurantOfTheDayId: restaurantOfTheDayId ?? this.restaurantOfTheDayId,
    inflationPct: inflationPct ?? this.inflationPct,
    feeMultiplier: feeMultiplier ?? this.feeMultiplier,
    demoMode: demoMode ?? this.demoMode,
  );

  /// §4 wire serialization (keys match the server contract exactly).
  Map<String, dynamic> toJson() => {
    'serviceFee': serviceFee,
    'deliveryFee2km': deliveryFee2km,
    'deliveryFee5km': deliveryFee5km,
    'deliveryFee8km': deliveryFee8km,
    'footFee': footFee,
    'rainSurge': rainSurge,
    'bunaRunFee': bunaRunFee,
    'bunaMaxOrder': bunaMaxOrder,
    'bunaMaxKm': bunaMaxKm,
    'courierSharePct': courierSharePct,
    'courierTipsPct': courierTipsPct,
    'codFloatCap': codFloatCap,
    'codSettlementHours': codSettlementHours,
    'commissionPct': commissionPct,
    'restaurantOfTheDayCommissionPct': restaurantOfTheDayCommissionPct,
    'ackTimeoutSeconds': ackTimeoutSeconds,
    'smsProvider': smsProvider,
    'smsCostEtb': smsCostEtb,
    'rainMode': rainMode,
    'fastingOverride': fastingOverride,
    'vehicleCurfew': vehicleCurfew,
    'restaurantOfTheDayId': restaurantOfTheDayId,
    'inflationPct': inflationPct,
    'feeMultiplier': feeMultiplier,
    'demo': demoMode,
  };
}

/// Lifestyle / dietary tags for search. These go beyond the raw boolean flags so
/// the search bar can match "keto", "vegan", "gluten-free", "halal", "yetsom" etc.
enum DietaryTag {
  vegan('vegan', 'vegan', 'vegan'),
  vegetarian('vegetarian', 'vegetarian', 'vegetarian'),
  keto('keto', 'keto', 'keto'),
  halal('halal', 'halal', 'halal'),
  tsom('tsom', 'yetsom', 'የጾም'),
  rawMeat('raw-meat', 'kitfo < tere siga', 'raw meat'),
  spicy('spicy', 'spicy', 'myo'),
  highProtein('high-protein', 'high-protein', 'high-protein'),
  glutenFree('gluten-free', 'gluten-free', 'gluten-free'),
  lowCarb('low-carb', 'low-carb', 'low-carb');

  const DietaryTag(this.key, this.en, this.am);
  final String key;
  final String en;
  final String am;
}

/// Item category tags (food categories search matches these).
class CategoryTag {
  final String en;
  final String am;
  const CategoryTag({required this.en, this.am = ''});
}