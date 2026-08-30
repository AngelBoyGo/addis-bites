# Addis Bites — Release & Store Listing

> Operational/deployment workbench is in [`OPS.md`](OPS.md). This file covers build artifacts + signing.

## Built artifacts
- Android APK: `addis_bites/build/app/outputs/flutter-apk/app-release.apk` (~56.7 MB) — **Production Signed** (Certificate: `CN=Addis Bites, C=ET`, SHA-256: `c3dcfbb3...`)
- Web (Telegram Mini App): `addis_bites/build/web/`
- Live Backend API: `https://addis-bites-worker.izzyblast2010.workers.dev` (Cloudflare Worker + D1 Database `addis-bites-db`)

Rebuild:
```bash
cd addis_bites
flutter build apk --release --dart-define=API_BASE=https://addis-bites-worker.izzyblast2010.workers.dev
flutter build web --release --dart-define=API_BASE=https://addis-bites-worker.izzyblast2010.workers.dev
```

## Android release signing
The `app-release.apk` is signed using the release keystore configured in `android/app/build.gradle.kts` and `android/key.properties`. Keystore files and passwords are kept in local `.gitignore`.

## Store listing
- **Google Play**: Upload `build/app/outputs/flutter-apk/app-release.apk` (or build `.aab` via `flutter build appbundle --release`), fill title, description (EN + Amharic), content rating, privacy policy URL. Application ID: `com.addisbites.app`.
- **App Store (iOS)**: Apple Developer account + Xcode provisioning on macOS before `flutter build ipa`.
- **Telegram Mini App**: Host `build/web/` under HTTPS and configure via `@BotFather` `/newapp` or WebApp button.

## Live Backend
Point the app at the live Cloudflare D1 backend:
```bash
flutter run --dart-define=API_BASE=https://addis-bites-worker.izzyblast2010.workers.dev
```