
/// Restaurant / merchant per the catalog contract, extended with opening-hours
/// so the Open Now toggle works, and dietary/lifestyle tags for faceted search.
class Merchant {
  const Merchant({
    required this.id,
    required this.nameEn,
    required this.nameAm,
    this.sefer = '',
    this.subCity = '',
    this.lat = 0,
    this.lng = 0,
    this.phoneGsm = '',
    this.prepMin = 25,
    this.rating = 0,
    this.tsomCertified = false,
    this.halalCertified = false,
    this.thermal = false,
    this.acceptsCash = true,
    this.acceptsChapa = true,
    this.isRestaurantOfTheDay = false,
    this.accent,
    this.isOpen = true,
    this.cuisine = const [],
    this.features = const [],
    this.deliveryZones = const [],
  });

  final String id;
  final String nameEn;
  final String nameAm;
  final String sefer;
  final String subCity;
  final double lat;
  final double lng;
  final String phoneGsm;
  final int prepMin;
  final double rating;
  final bool tsomCertified;
  final bool halalCertified;
  final bool thermal;
  final bool acceptsCash;
  final bool acceptsChapa;
  final bool isRestaurantOfTheDay;
  final String? accent;
  final bool isOpen;
  final List<String> cuisine; // e.g. ['Ethiopian', 'Coffee']
  final List<String> features; // e.g. ['vegan-friendly', 'halal', 'raw-meat-ok']
  final List<String> deliveryZones; // sub-cities/hubs this merchant can reach

  /// Coverage gating (§11.4): can this merchant deliver to [hub]?
  bool covers(String hub) {
    final h = hub.toLowerCase();
    if (deliveryZones.isEmpty) return true; // no zone data → allow (field-agent verified feed)
    return deliveryZones.any((z) => z.toLowerCase() == h || z.toLowerCase().contains(h));
  }

  /// Full search corpus for this merchant: name (both scripts), sefer, subcity,
  /// cuisines and lifestyle features.
  List<String> get searchTokens => [
    nameEn.toLowerCase(),
    nameAm,
    sefer.toLowerCase(),
    subCity.toLowerCase(),
    ...cuisine.map((c) => c.toLowerCase()),
    ...features.map((c) => c.toLowerCase()),
    if (tsomCertified) 'tsom,yetsom,vegan,ጾም',
    if (halalCertified) 'halal',
    if (thermal) 'raw-meat,thermal',
  ];

  bool get hasAnyLifestyleTag => tsomCertified || halalCertified || features.isNotEmpty;

  factory Merchant.fromJson(Map<String, dynamic> json) => Merchant(
    id: json['id'] as String? ?? '',
    nameEn: json['nameEn'] as String? ?? '',
    nameAm: json['nameAm'] as String? ?? '',
    sefer: json['sefer'] as String? ?? '',
    subCity: json['subCity'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    phoneGsm: json['phoneGsm'] as String? ?? '',
    prepMin: (json['prepMin'] as num?)?.toInt() ?? 25,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    tsomCertified: json['tsomCertified'] as bool? ?? false,
    halalCertified: json['halalCertified'] as bool? ?? false,
    thermal: json['thermal'] as bool? ?? false,
    acceptsCash: json['acceptsCash'] as bool? ?? true,
    acceptsChapa: json['acceptsChapa'] as bool? ?? true,
    isRestaurantOfTheDay: json['isRestaurantOfTheDay'] as bool? ?? false,
    accent: json['accent'] as String?,
    isOpen: json['isOpen'] as bool? ?? json['openNow'] as bool? ?? true,
    cuisine: _strList(json['cuisine']),
    features: _strList(json['features']),
    deliveryZones: _strList(json['deliveryZones'] ?? json['zones']),
  );

  static List<String> _strList(Object? v) =>
      (v is List ? v.map((e) => e.toString()).toList() : const <String>[]);

  /// §4 wire serialization (keys match the server contract exactly).
  Map<String, dynamic> toJson() => {
    'id': id,
    'nameEn': nameEn,
    'nameAm': nameAm,
    'sefer': sefer,
    'subCity': subCity,
    'lat': lat,
    'lng': lng,
    'phoneGsm': phoneGsm,
    'prepMin': prepMin,
    'rating': rating,
    'tsomCertified': tsomCertified,
    'halalCertified': halalCertified,
    'thermal': thermal,
    'acceptsCash': acceptsCash,
    'acceptsChapa': acceptsChapa,
    'isRestaurantOfTheDay': isRestaurantOfTheDay,
    if (accent != null) 'accent': accent,
    'isOpen': isOpen,
    'cuisine': cuisine,
    'features': features,
    'deliveryZones': deliveryZones,
  };
}