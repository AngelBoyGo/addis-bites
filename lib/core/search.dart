import '../models/menu.dart';
import '../models/merchant.dart';

/// Faceted, offline search over the cached catalog.
///
/// One input matches across four dimensions:
///  1. Restaurant (merchant) names — EN + AM, sefer, sub-city, cuisines
///  2. Menu item names — EN + AM
///  3. Food categories — e.g. "Meat Wots", "Breakfast"
///  4. Lifestyle / dietary descriptors — vegan, keto, halal, yetsom, raw-meat…
///
/// Together with the [`CatalogFilter`] predicates used by the home feed
/// (Open Now, fasting mode, halal), this powers the search bar's "the more the
/// better" acceptance.
class SearchEngine {
  const SearchEngine._();

  static String normalize(String input) =>
      input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool _containsQuery(String haystack, String query) {
    if (query.isEmpty) return true;
    return haystack.contains(query);
  }

  /// Returns the best matched facet label for display ("Restaurant",
  /// "Menu item", "Category", "Lifestyle"). An empty hint means no-op.
  static String facetFor(Merchant merchant, MenuItem item, String query) {
    final q = normalize(query);
    if (q.isEmpty) return '';
    if (_containsQuery(normalize(merchant.nameEn), q) ||
        merchant.nameAm.contains(q)) {
      return 'Restaurant';
    }
    if (_containsQuery(normalize(item.nameEn), q) || item.nameAm.contains(q)) {
      return 'Menu item';
    }
    if (_containsQuery(normalize(item.category), q)) return 'Category';
    return 'Lifestyle';
  }

  static bool merchantMatches(Merchant m, String query) =>
      _searchTokens(m.searchTokens, query);

  static bool itemMatches(MenuItem i, String query) =>
      _searchTokens(i.searchTokens, query);

  static bool _searchTokens(List<String> tokens, String query) {
    final q = normalize(query);
    if (q.isEmpty) return true;
    for (final t in tokens) {
      if (normalizedContains(t, q)) return true;
    }
    return false;
  }

  static bool normalizedContains(String hay, String q) =>
      hay.toLowerCase().contains(q);
}

/// Immutable catalog filter for the home feed.
class CatalogFilter {
  const CatalogFilter({
    this.query = '',
    this.openNow = false,
    this.onlyTsomOrVegan = false,
    this.onlyHalal = false,
    this.hub = '',
  });

  final String query;
  final bool openNow;
  final bool onlyTsomOrVegan;
  final bool onlyHalal;
  final String hub;

  bool get isActive => query.isNotEmpty || openNow || onlyTsomOrVegan || onlyHalal || hub.isNotEmpty;

  CatalogFilter copyWith({
    String? query,
    bool? openNow,
    bool? onlyTsomOrVegan,
    bool? onlyHalal,
    String? hub,
  }) => CatalogFilter(
    query: query ?? this.query,
    openNow: openNow ?? this.openNow,
    onlyTsomOrVegan: onlyTsomOrVegan ?? this.onlyTsomOrVegan,
    onlyHalal: onlyHalal ?? this.onlyHalal,
    hub: hub ?? this.hub,
  );

  bool matches(Merchant m) {
    if (openNow && !m.isOpen) return false;
    if (onlyHalal && !m.halalCertified) return false;
    if (onlyTsomOrVegan && !m.tsomCertified) return false;
    if (query.isNotEmpty && !SearchEngine.merchantMatches(m, query)) return false;
    // Coverage gating (§11.4): hide merchants that can't reach the selected hub.
    if (hub.isNotEmpty && !m.covers(hub)) return false;
    return true;
  }
}