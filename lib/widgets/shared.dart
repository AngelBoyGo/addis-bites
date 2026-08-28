import 'dart:async';

import 'package:flutter/material.dart';

import '../app_root.dart';
import '../theme/app_colors.dart';

/// A "locked total" pill rendered identically on customer, driver and merchant
/// screens — the Price Lock guardrail (§11.3): same number, same format,
/// labeled "Locked total — pay exactly this."
class LockedTotalPill extends StatelessWidget {
  const LockedTotalPill({super.key, required this.totalEtb, this.small = false});
  final int totalEtb;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14, vertical: small ? 6 : 10),
      decoration: BoxDecoration(
        color: AppColors.primaryGold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Locked total · ቋሚ ጠቅላላ',
            style: TextStyle(fontSize: small ? 10 : 11, fontWeight: FontWeight.w600, color: AppColors.neutralDark),
          ),
          Text(
            '$totalEtb ETB',
            style: TextStyle(
              fontSize: small ? 16 : 22,
              fontWeight: FontWeight.w900,
              color: AppColors.neutralDark,
            ),
          ),
          if (!small)
            const Text('pay exactly this · በትክክል ይክፈሉ',
                style: TextStyle(fontSize: 10, color: AppColors.neutralDark)),
        ],
      ),
    );
  }
}

/// Small badge used across role dashboards.
class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.label, this.color = AppColors.tsomGreen});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Demo-mode watermark (§13: visible whenever the backend reports demo provider).
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});
  @override
  Widget build(BuildContext context) {
    return TagBadge(label: StringsScope.of(context).demoWatermark, color: AppColors.surfaceGround);
  }
}

/// Section header used in role dashboards.
class RoleSection extends StatelessWidget {
  const RoleSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        child,
      ],
    );
  }
}

/// Tiny key/value row.
class KvRow extends StatelessWidget {
  const KvRow({super.key, required this.k, required this.v, this.vColor});
  final String k;
  final String v;
  final Color? vColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: Theme.of(context).textTheme.bodyMedium)),
          Text(v,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: vColor)),
        ],
      ),
    );
  }
}

/// Ticks every second and calls [onZero] when it expires (re-builds with a new
/// [seconds] value passed in via the parent's setState).
class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.seconds});
  final int seconds;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late int _left;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _left = widget.seconds;
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left > 0 && mounted) {
        setState(() => _left--);
      } else if (_left == 0) {
        _t?.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(CountdownText old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) {
      _left = widget.seconds;
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('${_left}s',
        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondaryClay, fontSize: 16));
  }
}