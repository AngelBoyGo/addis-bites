import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fasting_engine.dart';
import '../models/catalog.dart';
import 'catalog_provider.dart';

/// Resolved fasting state: server `fasting` + weekly Wed/Fri rule + user override.
final fastingProvider = Provider<ResolvedFasting>((ref) {
  final server = ref.watch(catalogProvider).valueOrNull?.fasting ?? FastingState.empty;
  final override = ref.watch(fastingOverrideProvider);
  final active = FastingEngine.isActive(DateTime.now(), server) && !override;
  return ResolvedFasting(server: server, userOverride: override, active: active);
});

/// One-tap "Show all" override (reveals meat items on fasting days).
final fastingOverrideProvider = StateNotifierProvider<FastingOverride, bool>(
  (ref) => FastingOverride(),
);

class FastingOverride extends StateNotifier<bool> {
  FastingOverride() : super(false);
  void set(bool v) => state = v;
  void toggle() => state = !state;
}

class ResolvedFasting {
  final FastingState server;
  final bool userOverride;
  final bool active;
  const ResolvedFasting({required this.server, required this.userOverride, required this.active});
}