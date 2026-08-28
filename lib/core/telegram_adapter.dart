/// Telegram Mini App integration (§9).
///
/// The actual JavaScript bridge lives in `telegram_adapter_web.dart` (loaded
/// only on web builds) and a no-op stub in `telegram_adapter_stub.dart` (used on
/// Android/iOS/tests). Use [isTelegram] to detect, [initData] for `/api/tg-auth`,
/// [themeParams] for Telegram theme adaptation, and [haptic] for feedback.
library;

import 'telegram_adapter_stub.dart'
    if (dart.library.js_interop) 'telegram_adapter_web.dart'
    as platform;

class TelegramAdapter {
  TelegramAdapter._();

  /// True when running inside the Telegram WebApp container.
  static bool get isTelegram => platform.isTelegram;

  /// The `window.Telegram.WebApp.initData` payload (empty outside Telegram).
  static String get initData => isTelegram ? platform.initData : '';

  /// Resolved `themeParams` (bg_color, text_color, button_color, …).
  static Map<String, dynamic> get themeParams =>
      isTelegram ? platform.themeParams : const {};

  /// Raise a Telegram haptic (impact|notification|selection).
  static void haptic(String kind) {
    if (isTelegram) platform.haptic(kind);
  }
}