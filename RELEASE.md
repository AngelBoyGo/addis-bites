# Addis Bites — Release & Store Listing

> Operational/deployment workbench is in [`OPS.md`](OPS.md) (hand to the
> Perplexity browser agent). This file covers build artifacts + signing.

## Built artifacts
- Android APK: `addis_bites/build/app/outputs/flutter-apk/app-release.apk` (~56 MB)
- Web (Telegram Mini App): `addis_bites/build/web/`

Rebuild:
```
cd addis_bites
flutter build apk --release
flutter build web --release      # JS target (Telegram Mini App WebView)
```

## Android release signing
The current `app-release.apk` is built with the debug signing config. For a
real Play release, configure a keystore in
`android/app/build.gradle.kts` and the `android/key.properties` per Flutter
docs, then rebuild. Store credentials must never be committed.

## Store listing (requires store accounts — cannot be automated here)
- **Google Play**: apply for a merchant account, upload the signed APK/AAB,
  fill the store listing (title, description EN + Amharic, screenshots,
  content rating, privacy policy URL, data safety). Use the package id set in
  `android/app/build.gradle.kts`.
- **App Store (iOS)**: Apple Developer account + Xcode provisioning before
  `flutter build ipa`. Building iOS requires running on macOS.
- **Telegram Mini App**: host `build/web` under Telegram's requirements and
  configure the bot with the WebApp URL (the app already loads Telegram init via
  `lib/core/telegram_adapter_web.dart`).

## Backend gate
Point the app at the deployed backend:
```
flutter run --dart-define=API_BASE=https://addis-bites.higgsfield.app
```
Deploy + provision D1 via `worker/deploy.ps1` (needs `wrangler login` and the
AUTH_SECRET / CHAPA_WEBHOOK_SECRET secrets. Until real payouts/creds are set,
money movement (Telebirr B2C) and webhook signing default to simulated mode so
the app remains fully functional offline.