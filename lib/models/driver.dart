/// Driver-domain models mirroring `/api/driver/dashboard`, `/api/driver/accept`
/// and the offer wire shape in §4.
library;

enum DeliveryVehicle { foot, bicycle, motorbike, car }

class DriverOffer {
  const DriverOffer({
    required this.orderId,
    required this.merchant,
    required this.sefer,
    required this.distanceKm,
    required this.grossFee,
    required this.keeperShare,
    required this.fuelCost,
    required this.net,
    required this.subsidy,
    required this.tipsEtb,
    required this.etaMin,
    required this.footEligible,
  });

  final String orderId;
  final String merchant;
  final String sefer;
  final double distanceKm;
  final int grossFee;
  final int keeperShare;
  final int fuelCost;
  final int net;
  final int subsidy;
  final int tipsEtb;
  final int etaMin;
  final bool footEligible;

  factory DriverOffer.fromJson(Map<String, dynamic> json) => DriverOffer(
    orderId: json['orderId'] as String? ?? '',
    merchant: json['merchant'] as String? ?? '',
    sefer: json['sefer'] as String? ?? '',
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    grossFee: (json['grossFee'] as num?)?.toInt() ?? 0,
    keeperShare: (json['keeperShare'] as num?)?.toInt() ?? 0,
    fuelCost: (json['fuelCost'] as num?)?.toInt() ?? 0,
    net: (json['net'] as num?)?.toInt() ?? 0,
    subsidy: (json['subsidy'] as num?)?.toInt() ?? 0,
    tipsEtb: (json['tipsEtb'] as num?)?.toInt() ?? 0,
    etaMin: (json['etaMin'] as num?)?.toInt() ?? 0,
    footEligible: json['footEligible'] as bool? ?? false,
  );

  /// §4 wire serialization.
  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'merchant': merchant,
    'sefer': sefer,
    'distanceKm': distanceKm,
    'grossFee': grossFee,
    'keeperShare': keeperShare,
    'fuelCost': fuelCost,
    'net': net,
    'subsidy': subsidy,
    'tipsEtb': tipsEtb,
    'etaMin': etaMin,
    'footEligible': footEligible,
  };
}

class VehicleEconomics {
  const VehicleEconomics({
    required this.vehicle,
    required this.costPerKm,
    required this.rangeKm,
    required this.keeperSharePct,
  });

  final DeliveryVehicle vehicle;
  final double costPerKm;
  final double rangeKm;
  final int keeperSharePct;

  String get label => switch (vehicle) {
    DeliveryVehicle.foot => 'Foot',
    DeliveryVehicle.bicycle => 'Bicycle',
    DeliveryVehicle.motorbike => 'Motorbike',
    DeliveryVehicle.car => 'Car',
  };
}

class DriverWallet {
  const DriverWallet({required this.balanceEtb, required this.floatEtb, required this.floatCap, required this.payoutDue});

  final int balanceEtb;
  final int floatEtb;
  final int floatCap;
  final int payoutDue;

  bool get codBlocked => floatEtb >= floatCap;
}

class DriverDashboard {
  const DriverDashboard({
    required this.wallet,
    required this.econByVehicle,
    required this.offers,
    required this.curfewActive,
    this.activeOrderTotalEtb,
  });

  final DriverWallet wallet;
  final List<VehicleEconomics> econByVehicle;
  final List<DriverOffer> offers;
  final bool curfewActive;

  /// Locked collect-on-arrival total of the driver's active (assigned, not yet
  /// POD'd) order, when one exists. Null means "no active pickup to collect".
  /// §11.3 price lock: driver must see the identical total the customer locked.
  final int? activeOrderTotalEtb;

  factory DriverDashboard.fromJson(Map<String, dynamic> json) => DriverDashboard(
    wallet: DriverWallet(
      balanceEtb: (json['walletBalanceEtb'] as num?)?.toInt() ?? 0,
      floatEtb: (json['floatEtb'] as num?)?.toInt() ?? 0,
      floatCap: (json['floatCap'] as num?)?.toInt() ?? 1500,
      payoutDue: (json['payoutDue'] as num?)?.toInt() ?? 0,
    ),
    econByVehicle: [
      const VehicleEconomics(vehicle: DeliveryVehicle.foot, costPerKm: 0, rangeKm: 1.5, keeperSharePct: 95),
      const VehicleEconomics(vehicle: DeliveryVehicle.bicycle, costPerKm: 0, rangeKm: 4, keeperSharePct: 80),
      const VehicleEconomics(vehicle: DeliveryVehicle.motorbike, costPerKm: 10, rangeKm: 18, keeperSharePct: 80),
      const VehicleEconomics(vehicle: DeliveryVehicle.car, costPerKm: 18, rangeKm: 30, keeperSharePct: 80),
    ],
    offers: ((json['offers'] as List?) ?? const [])
        .map((e) => DriverOffer.fromJson(e as Map<String, dynamic>))
        .toList(),
    curfewActive: json['curfewActive'] as bool? ?? false,
    activeOrderTotalEtb: (json['activeOrderTotalEtb'] as num?)?.toInt(),
  );

  static const empty = DriverDashboard(
    wallet: DriverWallet(balanceEtb: 0, floatEtb: 0, floatCap: 1500, payoutDue: 0),
    econByVehicle: [],
    offers: [],
    curfewActive: false,
  );
}

class ProofOfDelivery {
  const ProofOfDelivery({required this.orderId, required this.photoB64, required this.pin});
  final String orderId;
  final String photoB64;
  final String pin;
}