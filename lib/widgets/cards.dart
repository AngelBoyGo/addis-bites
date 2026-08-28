import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_root.dart';
import '../i18n/strings.dart';
import '../models/menu.dart';
import '../models/merchant.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import 'shared.dart';

/// Converts a hex accent string (e.g. "#C84B20") to a [Color].
Color hexColor(String? hex, {Color fallback = AppColors.secondaryClay}) {
  if (hex == null || hex.isEmpty) return fallback;
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h, radix: 16);
  if (v == null) return fallback;
  return Color(0xFF000000 | v);
}

/// A tap-through hero Restaurant card. Shows bilingual name, sefer/sub-city,
/// prep time, rating, and the certified badges (tsom/halal/thermal).
class MerchantCard extends ConsumerWidget {
  const MerchantCard({super.key, required this.merchant, this.onTap});

  final Merchant merchant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = StringsScope.of(context);
    final accent = hexColor(merchant.accent);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        merchant.nameEn.isNotEmpty
                            ? merchant.nameEn.substring(0, 1).toUpperCase()
                            : '؟',
                        style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(merchant.nameEn, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${merchant.nameAm} · ${merchant.sefer}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _OpenBadge(isOpen: merchant.isOpen, s: s),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 15, color: AppColors.neutralMid),
                  const SizedBox(width: 4),
                  Text('${merchant.prepMin} min', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(width: 12),
                  const Icon(Icons.star, size: 15, color: AppColors.primaryGold),
                  const SizedBox(width: 4),
                  Text(merchant.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelSmall),
                  const Spacer(),
                  ..._badges(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _badges(BuildContext context) {
    final list = <Widget>[];
    void add(Color color, IconData icon) {
      list.add(Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
        child: Icon(icon, size: 15, color: color),
      ));
    }

    if (merchant.tsomCertified) add(AppColors.tsomGreen, Icons.eco);
    if (merchant.halalCertified) add(AppColors.halalTeal, Icons.verified);
    if (merchant.thermal) add(AppColors.surfaceGround, Icons.ac_unit);
    return list;
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen, required this.s});
  final bool isOpen;
  final Strings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.tsomGreen.withValues(alpha: 0.12)
            : AppColors.neutralMid.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? s.open : s.closed,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.tsomGreen : AppColors.neutralMid,
        ),
      ),
    );
  }
}

/// A menu item row inside a restaurant screen.
class MenuItemTile extends ConsumerWidget {
  const MenuItemTile({super.key, required this.item, this.onTap});
  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txt = Theme.of(context).textTheme;
    final dataSaver = ref.watch(dataSaverProvider);
    final s = StringsScope.of(context);
    final disabled = !item.isAvailable;
    return InkWell(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!dataSaver)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: item.isTsom
                        ? AppColors.tsomGreen.withValues(alpha: 0.15)
                        : AppColors.secondaryClay.withValues(alpha: 0.12),
                    child: item.photoWebpUrl != null && item.photoWebpUrl!.isNotEmpty
                        ? Image.network(
                            item.photoWebpUrl!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => const Icon(Icons.rice_bowl, color: AppColors.neutralMid, size: 26),
                          )
                        : const Center(child: Icon(Icons.rice_bowl, color: AppColors.neutralMid, size: 26)),
                  ),
                ),
              if (!dataSaver) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nameEn, style: txt.titleSmall),
                    Text(item.nameAm, style: txt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, children: _itemChips),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.priceEtb} ETB',
                      style: txt.titleMedium?.copyWith(
                          color: disabled ? AppColors.neutralMid : AppColors.secondaryClay,
                          fontWeight: FontWeight.w700,
                          decoration: disabled ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 6),
                  if (disabled)
                    TagBadge(label: s.soldOut, color: AppColors.neutralMid)
                  else
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryGold,
                      child: Icon(Icons.add, size: 18, color: AppColors.neutralDark),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get _itemChips {
    final list = <Widget>[];
    void chip(String label, Color color) {
      list.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ));
    }

    if (item.isTsom) chip('ጾም', AppColors.tsomGreen);
    if (item.isHalal) chip('halal', AppColors.halalTeal);
    if (item.isRawMeat) chip('raw', AppColors.surfaceGround);
    return list;
  }
}