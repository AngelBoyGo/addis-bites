/// Telegram WebApp bridge for Flutter Web builds (§9).
///
/// Reads `window.Telegram.WebApp` via `dart:js_interop`. Every accessor is
/// defensive: if the app is not embedded in Telegram (or the SDK hasn't loaded),
/// it returns safe defaults so the app keeps working as a normal web app.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Returns the `window.Telegram.WebApp` object, or null when unavailable.
JSObject? _webApp() {
  try {
    final tg = globalContext.getProperty('Telegram'.toJS);
    if (tg == null) return null;
    final wa = (tg as JSObject).getProperty('WebApp'.toJS);
    return wa == null ? null : wa as JSObject;
  } catch (_) {
    return null;
  }
}

String _string(JSObject o, String key) {
  try {
    final v = o.getProperty(key.toJS);
    if (v == null) return '';
    return (v as JSString).toDart;
  } catch (_) {
    return '';
  }
}

bool get isTelegram => _webApp() != null;

String get initData {
  final wa = _webApp();
  return wa == null ? '' : _string(wa, 'initData');
}

Map<String, dynamic> get themeParams {
  final wa = _webApp();
  if (wa == null) return const {};
  const keys = [
    'bg_color',
    'text_color',
    'hint_color',
    'link_color',
    'button_color',
    'button_text_color',
    'secondary_bg_color',
    'section_bg_color',
    'subtitle_text_color',
    'accent_text_color',
  ];
  final map = <String, dynamic>{};
  for (final k in keys) {
    final v = _string(wa, k);
    if (v.isNotEmpty) map[k] = v;
  }
  return map;
}

void haptic(String kind) {
  final wa = _webApp();
  if (wa == null) return;
  try {
    final hf = wa.getProperty('HapticFeedback'.toJS);
    if (hf == null) return;
    (hf as JSObject).callMethod('impactOccurred'.toJS, kind.toJS);
  } catch (_) {}
}