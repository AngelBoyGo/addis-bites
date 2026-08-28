# Addis Bites (አዲስ ባይትስ)

A landmark-based, low-bandwidth, fasting-calendar-aware food delivery app for
Addis Ababa, Ethiopia. Built to the full Dreamflow spec: five role-gated
dashboards in one codebase, server-authoritative pricing, offline-first, and a
deep local savings engine.

## The five roles (all in one app)

| Role | Screen | Route |
|---|---|---|
| **Customer** | Home feed (search + Open Now + fasting), restaurant + platter configurator, Gebeta cart, landmark checkout, tracking | `/app`, `/restaurant/:id`, `/cart`, `/checkout`, `/order/:id` |
| **Merchant** | Live queue, 90s ack countdown, accept/decline/preparing, menu 86'ing, menu-photo OCR upload | `/dash/merchant` |
| **Driver** | Vehicle tabs + economics, wallet + COD float, live offers, accept, POD (photo + PIN) | `/dash/driver` |
| **Foot carrier** | Phone-only onboarding, orientation checklist, "start earning today" (1.5 km radius), earnings + bonuses | `/carrier` |
| **Admin** | KPIs, live orders, pricing editor, platform flags (rain mode / fasting override), OCR queue, OTP log, field-agent mode | `/admin`, `/field` |
| **CEO** | KPI tiles, inflation engine, unit economics, foot network, disputes, promotions | `/dash/ceo` |

## Getting started

```bash
cd addis_bites
flutter pub get
flutter run                # pick a device/emulator (Android)
# or press Run in Android Studio
```

### API base override
The app reads `API_BASE` only:

```bash
flutter run --dart-define=API_BASE=https://addis-bites.higgsfield.app
```

When no base is configured the app runs in **demo mode** against an in-memory
mock backend (`lib/core/mock_backend.dart`) that produces coherent fixtures for
every role — the full order loop and all dashboards are demonstrable and fully
offline. A "DEMO" watermark shows whenever the catalog reports demo mode.

### Local Cloudflare Worker Harness (§4 REST API)
A standalone mock worker is included in `worker/` to run the real HTTP contract locally:

```bash
cd worker
npm install
npm run start              # starts worker on http://127.0.0.1:8787
```

In another terminal, boot the Flutter client against the local worker:

```bash
flutter run --dart-define=API_BASE=http://127.0.0.1:8787
```

To run end-to-end HTTP integration tests against the running worker:

```bash
flutter test test/worker_http_test.dart --dart-define=API_BASE_HTTP_TESTS=true
```

## Contract Verification & Test Matrix

Run all tests and static analysis:

```bash
# PowerShell / Windows:
.\test\run_contract.ps1

# Unix / Bash / CI:
./test/run_contract.sh
```

| Test Suite | Purpose | Command |
|---|---|---|
| **Contract Tests** | §4 JSON wire fixture round-trips & field-existence assertions, negative coverage, server-authoritative pricing guardrail | `flutter test test/contract_test.dart` |
| **Unit & Pricing Tests** | Fasting calendar engine (Wed/Fri/seasonal), inflation indexing, buna & foot tiers, cart batching | `flutter test test/unit_test.dart` |
| **Role Routing Tests** | Five-role router redirects & role gates | `flutter test test/role_router_test.dart` |
| **Worker HTTP Tests** | Live HTTP communication against running worker | `flutter test test/worker_http_test.dart` |

## Architecture

- **State:** Riverpod, one pattern project-wide (`StateNotifierProvider`).
- **Routing:** go_router with **role-guarded redirects** (`lib/router/app_router.dart`).
- **Auth:** phone + OTP (SMS / Telegram) or Telegram `tg-auth`; token only in
  `flutter_secure_storage` (`lib/core/session_storage.dart`); 401/403 flushes session.
- **API:** `lib/core/api_client.dart` against the §4 contract; server-authoritative
  pricing — the client **never sends prices**, only item IDs.
- **Offline:** catalog cached with 3-min TTL + disk cache; cart always editable
  offline; order submission queues with retry (2 automatic + manual Retry);
  SMS order bridge fallback on the OS SMS composer.
- **i18n:** EN / Amharic toggle, all copy in `lib/i18n/strings.dart`.

## Featured mechanics

- **Two-tier landmark addressing** — sub-city dropdown + sefer hub autosuggest +
  mandatory free-text micro-landmark; optional map pin (Plus Code) as a
  background confirmation layer.
- **Fasting Calendar (Tsom)** — Wed/Fri + seasonal from server `fasting`, green
  banner, one-tap "Show all" override, independent Halal filter.
- **Gebeta platter configurator** — qty + injera-roll stepper (steps of 2) +
  spice picker; raw-meat items show "Thermal transit verified".
- **Sefer Rounds** — batch deliveries with live per-head fee split, join action.
- **Savings**, all surfaced in ETB: buna run, foot-tier downgrade, pickup (0 ETB),
  meet-point, schedule-ahead, digital-payment discount, share-to-save.
- **Guardrails**: price lock (identical locked total on every screen), verified
  receipt with QR, refund tracker, ticketed disputes ("I never received this" /
  "I was overcharged"), coverage gating, honest ETA ranges, POD-gated delivered.
- **Growth loops**: Gursha gifting, Share Gebeta (group cart deep link), referral,
  diaspora "Feed Home".

## Build targets

- **Android** (primary): minSdk 21 / targetSdk 34 per spec (set in
  `android/app/build.gradle.kts`).
- **Web** (Telegram Mini App): compiled with a Telegram adapter seam
  (`lib/core/telegram_adapter.dart`).

`flutter analyze` is clean (0 errors) and `flutter test` passes the unit,
contract, and role-routing suites. A debug APK builds successfully (`flutter build apk --debug`).

## Notes
- Fonts: drop `Inter` + `NotoSansEthiopic` `.ttf` into `assets/fonts/` and
  uncomment the `fonts:` block in `pubspec.yaml` to bundle them; the system font
  stack already renders Amharic on Android.
- Release APK: use `--split-per-abi --obfuscate --tree-shake-icons` to shrink
  toward the <150 MB spec target.
