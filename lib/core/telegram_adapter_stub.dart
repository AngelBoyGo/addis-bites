/// No-op Telegram bridge for non-web targets (Android, iOS, VM tests).
library;

bool get isTelegram => false;

String get initData => '';

Map<String, dynamic> get themeParams => const {};

void haptic(String kind) {}