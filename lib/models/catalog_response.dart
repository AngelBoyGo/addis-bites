import 'catalog.dart';
import 'menu.dart';
import 'merchant.dart';

/// Aggregate catalog response from `/api/catalog`.
class CatalogResponse {
  const CatalogResponse({
    required this.merchants,
    required this.items,
    required this.config,
    required this.fasting,
    required this.subCities,
  });

  final List<Merchant> merchants;
  final List<MenuItem> items;
  final AppConfig config;
  final FastingState fasting;
  final List<SubCity> subCities;

  factory CatalogResponse.fromJson(Map<String, dynamic> json) {
    final merchantListRaw = (json['merchants'] as List?) ?? const [];
    final itemListRaw = (json['menu'] as List?) ?? const [];

    final merchants = merchantListRaw
        .map((e) => Merchant.fromJson(e as Map<String, dynamic>))
        .toList();

    List<MenuItem> parseItems() {
      final byMerchant = <String, Merchant>{for (final m in merchants) m.id: m};
      return itemListRaw.map((e) {
        final j = e as Map<String, dynamic>;
        return MenuItem.fromJson(j, merchantId: byMerchant[j['merchantId']]?.id);
      }).toList();
    }

    return CatalogResponse(
      merchants: merchants,
      items: parseItems(),
      config: AppConfig.fromJson(Map<String, dynamic>.from(json['config'] as Map? ?? const {})),
      fasting: FastingState.fromJson(Map<String, dynamic>.from(json['fasting'] as Map? ?? const {})),
subCities: ((json['subCities'] as List?) ?? const [])
        .map((e) => SubCity.fromJson(e as Map<String, dynamic>))
        .toList(),
    );
  }

  /// §4 wire serialization (keys match the server contract exactly).
  Map<String, dynamic> toJson() => {
    'merchants': merchants.map((m) => m.toJson()).toList(),
    'menu': items.map((i) => i.toJson()).toList(),
    'config': config.toJson(),
    'fasting': fasting.toJson(),
    'subCities': subCities.map((s) => s.toJson()).toList(),
  };
}