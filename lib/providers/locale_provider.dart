import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session_storage.dart';
import '../i18n/strings.dart';

/// Current UI locale ("en" | "am"). Toggling rebuilds the whole tree with a new
/// Strings catalog (§8: all strings live in resource files, zero hardcoded).
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleId>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<LocaleId> {
  LocaleNotifier() : super(LocaleId.en) {
    _init();
  }

  Future<void> _init() async {
    final saved = await SessionStorage.locale();
    if (saved == 'am') state = LocaleId.am;
  }

  Future<void> toggle() async {
    final next = state == LocaleId.en ? LocaleId.am : LocaleId.en;
    state = next;
    await SessionStorage.setLocale(next == LocaleId.am ? 'am' : 'en');
  }
}