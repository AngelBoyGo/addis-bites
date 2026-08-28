import 'catalog.dart';

/// A food item (menu item) per the catalog contract.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.merchantId,
    required this.nameEn,
    required this.nameAm,
    required this.priceEtb,
    this.category = '',
    this.isTsom = false,
    this.isHalal = false,
    this.isRawMeat = false,
    this.isAvailable = true,
    this.hasInjeraStepper = false,
    this.spiceLevels = 0,
    this.photoWebpUrl,
    this.dietaryTags = const [],
  });

  final String id;
  final String merchantId;
  final String nameEn;
  final String nameAm;
  final int priceEtb;
  final String category;
  final bool isTsom;
  final bool isHalal;
  final bool isRawMeat;
  final bool isAvailable;
  final bool hasInjeraStepper;
  final int spiceLevels;
  final String? photoWebpUrl;
  final List<DietaryTag> dietaryTags;

  /// Derived "facet" tags that power the search bar (names, menu items,
  /// categories, lifestyle). Extends raw flags with lifestyle extras that may
  /// come from the server as a `tags` array on the item.
  List<String> get searchTokens {
    final tokens = <String>[nameEn.toLowerCase(), nameAm];
    if (category.isNotEmpty) tokens.add(category.toLowerCase());
    if (isTsom) tokens.addAll(const ['vegan', 'yetsom', 'ጾም', 'keto']);
    if (isHalal) tokens.add('halal');
    if (isRawMeat) tokens.addAll(const ['raw-meat', 'kitfo', 'tere siga']);
    for (final t in dietaryTags) {
      tokens.add(t.en);
      tokens.add(t.am);
    }
    return tokens;
  }

  factory MenuItem.fromJson(Map<String, dynamic> json, {String? merchantId}) {
    final extra = (json['dietaryTags'] as List?) ?? const [];
    final tags = <DietaryTag>[
      if (json['isTsom'] == true) DietaryTag.tsom,
      if (json['isHalal'] == true) DietaryTag.halal,
      if (json['isRawMeat'] == true) DietaryTag.rawMeat,
...extra.map((e) => DietaryTag.values.firstWhere(
      (t) => t.key == e, orElse: () => DietaryTag.vegan,
    )),
  ];
    return MenuItem(
      id: json['id'] as String? ?? '',
      merchantId: merchantId ?? (json['merchantId'] as String? ?? ''),
      nameEn: json['nameEn'] as String? ?? '',
      nameAm: json['nameAm'] as String? ?? '',
      priceEtb: (json['priceEtb'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      isTsom: json['isTsom'] as bool? ?? false,
      isHalal: json['isHalal'] as bool? ?? false,
      isRawMeat: json['isRawMeat'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      hasInjeraStepper: json['injeraStepper'] as bool? ?? false,
      spiceLevels: (json['spiceLevels'] as num?)?.toInt() ?? 0,
      photoWebpUrl: json['photoWebpUrl'] as String?,
      dietaryTags: tags,
    );
  }

  /// §4 wire serialization (keys match the server contract exactly).
  Map<String, dynamic> toJson() => {
    'id': id,
    'merchantId': merchantId,
    'nameEn': nameEn,
    'nameAm': nameAm,
    'priceEtb': priceEtb,
    'category': category,
    'isTsom': isTsom,
    'isHalal': isHalal,
    'isRawMeat': isRawMeat,
    'isAvailable': isAvailable,
    'injeraStepper': hasInjeraStepper,
    'spiceLevels': spiceLevels,
    if (photoWebpUrl != null) 'photoWebpUrl': photoWebpUrl,
    'dietaryTags': dietaryTags.map((t) => t.key).toList(),
  };
}