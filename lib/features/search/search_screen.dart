import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_root.dart';
import '../../core/search.dart';
import '../../models/catalog.dart';
import '../../models/catalog_response.dart';
import '../../models/menu.dart';
import '../../models/merchant.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards.dart';

/// Full-screen faceted search: one query across restaurant names, menu items,
/// categories and lifestyle descriptors, with results grouped by facet.
/// The home feed search bar routes here on submit.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _activeCat = '';
  DietaryTag? _activeLifestyle;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (q) => setState(() {
            _query = q;
            _activeCat = '';
            _activeLifestyle = null;
          }),
          decoration: const InputDecoration(
            hintText: 'Search food, restaurants, categories…',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${StringsScope.of(context).connectionLost} — $e')),
        data: (catalog) {
          if (_activeLifestyle != null) return _lifestyleResults(catalog, _activeLifestyle!);
          if (_activeCat.isNotEmpty) return _categoryResults(catalog, _activeCat);
          if (_query.isEmpty) return _suggestions(catalog);
          return _queryResults(catalog, _query);
        },
      ),
    );
  }

  // ---------- suggestions state (empty field) ----------
  Widget _suggestions(CatalogResponse catalog) {
    final s = StringsScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(context, s.lifestyleTitle),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in DietaryTag.values)
              ActionChip(
                avatar: const Icon(Icons.local_dining, size: 18),
                label: Text(tag.en),
                onPressed: () => setState(() => _activeLifestyle = tag),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle(context, s.categoriesTitle),
        for (final c in _categories(catalog))
          _categoryRow(catalog: catalog, name: c),
      ],
    );
  }

  List<String> _categories(CatalogResponse cat) {
    final set = <String>{};
    for (final i in cat.items) {
      if (i.category.isNotEmpty) set.add(i.category);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  Widget _categoryRow({required CatalogResponse catalog, required String name}) {
    int count = 0;
    for (final i in catalog.items) {
      if (i.category == name) count++;
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: const Icon(Icons.category_outlined, color: AppColors.primaryGold),
        title: Text(name),
        subtitle: Text('$count ${StringsScope.of(context).menuItems}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => _activeCat = name),
      ),
    );
  }

  // ---------- lifestyle facet results ----------
  Widget _lifestyleResults(CatalogResponse catalog, DietaryTag tag) {
    final items = catalog.items.where((i) => _lifestyleMatches(i, tag)).toList();
    final merchants = <Merchant>[];
    for (final m in catalog.merchants) {
      if (catalog.items.any((i) => i.merchantId == m.id && _lifestyleMatches(i, tag))) {
        merchants.add(m);
      }
    }
    return _resultsList(
      catalog: catalog,
      merchants: merchants,
      items: items,
    );
  }

  bool _lifestyleMatches(MenuItem item, DietaryTag tag) {
    if (tag == DietaryTag.vegan || tag == DietaryTag.tsom) {
      return item.isTsom || item.dietaryTags.any((t) => t == DietaryTag.vegan);
    }
    if (tag == DietaryTag.halal) {
      return item.isHalal || item.dietaryTags.any((t) => t == DietaryTag.halal);
    }
    if (tag == DietaryTag.rawMeat) {
      return item.isRawMeat || item.dietaryTags.any((t) => t == DietaryTag.rawMeat);
    }
    return item.dietaryTags.any((t) => t == tag);
  }

  // ---------- category facet results ----------
  Widget _categoryResults(CatalogResponse catalog, String cat) {
    final items = catalog.items.where((i) => i.category == cat).toList();
    return _resultsList(catalog: catalog, merchants: const [], items: items);
  }

  // ---------- free-text query results ----------
  Widget _queryResults(CatalogResponse catalog, String query) {
    final s = StringsScope.of(context);
    final merchants =
        catalog.merchants.where((m) => SearchEngine.merchantMatches(m, query)).toList();
    final items = catalog.items.where((i) => SearchEngine.itemMatches(i, query)).toList();

    if (merchants.isEmpty && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(s.noResults, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
    }
    return _resultsList(catalog: catalog, merchants: merchants, items: items);
  }

  // ---------- shared list renderer ----------
  Widget _resultsList({
    required CatalogResponse catalog,
    required List<Merchant> merchants,
    required List<MenuItem> items,
  }) {
    final s = StringsScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (merchants.isNotEmpty) ...[
          _sectionTitle(context, s.restaurants),
          for (final m in merchants)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: MerchantCard(merchant: m, onTap: () => context.push('/restaurant/${m.id}')),
            ),
          const SizedBox(height: 8),
        ],
        if (items.isNotEmpty) ...[
          _sectionTitle(context, s.menuItems),
          for (final item in items) _itemTile(item, catalog),
        ],
      ],
    );
  }

  Widget _itemTile(MenuItem item, CatalogResponse catalog) {
    Merchant? merchant;
    for (final m in catalog.merchants) {
      if (m.id == item.merchantId) {
        merchant = m;
        break;
      }
    }
    final name = merchant == null ? item.nameAm : '${item.nameAm} · ${merchant.nameEn}';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isTsom ? AppColors.tsomGreen : AppColors.secondaryClay,
          child: const Icon(Icons.rice_bowl, color: Colors.white, size: 20),
        ),
        title: Text(item.nameEn),
        subtitle: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text('${item.priceEtb} ETB',
            style: const TextStyle(color: AppColors.secondaryClay, fontWeight: FontWeight.w700)),
        onTap: () => context.push('/restaurant/${merchant?.id ?? item.merchantId}'),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) =>
      Padding(padding: const EdgeInsets.only(bottom: 8, top: 4), child: Text(title, style: Theme.of(context).textTheme.titleLarge));
}