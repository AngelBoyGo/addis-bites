# Addis Bites — Operational Checklist
> For handing to the Perplexity **browser agent** (Comet). Research, verify, and
> tee up each item. Items that require real money, signup, or KYC are marked
> **[DO BY ME]** — the agent can prep them but only you can execute them.
>
> System state: the app + business logic are **complete and tested**
> (`flutter test` 93 green, `node worker/test/smoke.mjs` 61 green, analyze 0/0).
> Everything below is **operational**, not code.

---

## A. Deployments — LIVE

| # | Task | Status / Action / URL |
|---|---|---|
| A1 | Cloudflare account + wrangler | ✅ **DONE** — Logged in (`izzyblast2010@gmail.com`). |
| A2 | Create D1 DB + wire ID | ✅ **DONE** — Database `addis-bites-db` (`28ea87d2-b8dd-4cdb-aa86-1b1e5936673d`) in region EEUR. |
| A3 | Apply schema | ✅ **DONE** — 27 queries executed, all 16 tables + seeds populated. |
| A4 | Deploy Worker | ✅ **LIVE** at `https://addis-bites-worker.izzyblast2010.workers.dev` (verified with `GET /api/catalog`, `POST /join`, `GET /api/driver/dashboard`). |
| A5 | Domain / DNS | Using `https://addis-bites-worker.izzyblast2010.workers.dev`. If pointing custom domain, add CNAME in Cloudflare DNS. |
| A6 | Secrets | ✅ **DONE** — `AUTH_SECRET`, `CHAPA_WEBHOOK_SECRET`, `CHAPA_PUBLIC_KEY`, `CHAPA_SECRET_KEY`, `AFROMESSAGE_API_KEY`, `TELEGRAM_BOT_TOKEN` all live in Cloudflare (set via wrangler; values never committed). Worker verified on signed-JWT flow. |
| A7 | Idempotent startup | ✅ **DONE** — `ensureSchema()` self-provisions lazily. |
| A8 | Web hosting | ✅ **LIVE** — `https://addis-bites-web.pages.dev` (Flutter web via Cloudflare Pages) + privacy policy at `/privacy` (PDPP 1321/2024). |
| A9 | Health check | ✅ **LIVE** — `GET /api/health` returns `{status:"ok"}`. |
| A10 | Chapa webhook | ✅ **LIVE** — `POST /api/webhooks/chapa` with HMAC verification; configured in Chapa dashboard (Merchant ID 7696163, test mode). |

## B. Payments (real money movement)

> Spec routes merchant money via **Chapa split payments** to avoid an NBE payment license.

| # | Step | Research / Action |
|---|---|---|
| B1 | **Chapa** merchant account | ✅ **DONE** — Account created & email-verified. Business: **Addis Bites**, Merchant ID **7696163**, **Test Mode** active. Test keys (`CHAPUBK_TEST-…` / `CHASECK_TEST-…`) stored in Cloudflare secrets. |
| B1b | Chapa webhook | ✅ **DONE** — Configured in dashboard: `https://addis-bites-worker.izzyblast2010.workers.dev/api/webhooks/chapa` + secret hash (matches `CHAPA_WEBHOOK_SECRET`). Success + failed-payment hooks enabled. |
| B1c | Chapa live switch | ⬜ Needs KYC: business info + TIN + license (`dashboard.chapa.co` → Compliance → Verify Now). [DO BY ME] |
| B2 | **Telebirr** B2C / merchant API | Sandbox at `sandbox.ethiotelecom.et/telebirr/...`. Introducer / Level‑1 KYC: <https://www.ethiotelecom.et/telebirr/telebirr-registration/>. Withdrawal: <https://www.ethiotelecom.et/telebirr/withdraw/>. |
| B3 | Webhook URL | ✅ see B1b. |
| B4 | Live switch (no code) | Payout flips simulated→real the moment `TELEBIRR_API_KEY` + live Chapa keys are set in Cloudflare secrets. |

## C. SMS / notifications (critical path — many users are USSD-first)

| # | Step | Research / Action |
|---|---|---|
| C1 | **Afromessage** SMS | ✅ **DONE** — Account created + email-verified (`Addis Bites`). **API token (JWT, valid to Aug 2031) → Cloudflare `AFROMESSAGE_API_KEY`.** Beta account: ~98 free messages, expires Sep 30 2026. ⬜ Pending: phone verification + sender-name "AddisBites" (requires account upgrade — email sales@afromessage.com). |
| C2 | **Telegram Bot** | ✅ **DONE** — `@AddisAbabaEats_bot` verified via Bot API; token in Cloudflare; **Mini App menu button live** (launches `addis-bites-web.pages.dev`). |
| C3 | Push (optional, web/mobile) | ✅ **DONE** — Firebase project `addis-eats-8a4f9` created (Spark/free), Android app `com.addisbites.app` registered (App ID `1:682279432166:android:45e512612f5f72856ab027`), `google-services.json` committed at `android/app/`. FCM server key can be added to Cloudflare when push is wired. |
| C4 | SMS fallback flag | ✅ Code sets `smsFallbackSent=true` when rider SMS initiated. |
## C. Legal / regulatory / corporate (the Metis PDF)

> The PDF cannot be read by this model. Convert it to text so it can be folded in.

| ID | Task |
|---|---|
| C1 | **Convert the PDF to text** (`Metis_Ethiopia_Legal_Regulatory_Financial_Proposal (1).pdf` → `.md`/`.txt`) and field‑by‑field: NBE licensing, corporate structure (Ethiopian PLC + US LLC + TTA), VAT/WHT tax, startup incentives. **Not found locally** — needs external source or acceptance of verified summary. |
| C2 | Verify spec claims: public‑sector alignment, 100M‑birr trust fund, 2026 MoJ directive, CMI earnings baseline (≈920 ETB/mo). |
| C3 | Business registration + bank + Telebirr merchant (business plan phase 0). |

## D. Store listing + release signing

| ID | Action | Status |
|---|---|---|
| D1 | **Play Console** release signing | ✅ **DONE** — Generated production keystore (`upload-keystore.jks`), wired in `android/app/build.gradle.kts`, verified release APK signature with `CN=Addis Bites, C=ET`. |
| D1b | **Play Console developer account** | ✅ **DONE** — Personal account created & $25 paid (Account ID `7433507581773030012`, "Dr. Ishmael Avery"). ⬜ **Publishing blocked on 3 human verifications**: identity doc upload, Android-device check (Play Console app), email code — see "Finish setting up" in console. `Create app` unlocks after these. |
| D2 | App Store (needs macOS + Apple Dev account). | Pending |
| D3 | Telegram Mini App: host `build/web/` behind HTTPS at Telegram-whitelisted URL + configure bot App. | ✅ Menu button live (`setChatMenuButton` → `addis-bites-web.pages.dev`); full `/newapp` flow optional. |
| D4 | Privacy policy + data-safety answers (PDPP 1321/2024). | ✅ **LIVE** at `https://addis-bites-web.pages.dev/privacy`; data-safety form ready to paste into Play Console. |

## E. Observability + ops readiness (spec §4 monitoring, free tier)

| ID | Action |
|---|---|
| E1 | **Sentry** crash logging | ✅ **DONE** — Org `addis-bites.sentry.io` created (separate from `metisgold` so quota is fresh), Flutter project live, DSN wired into `lib/main.dart` (`sentry_flutter`, no PII, prod env). ⬜ Optional: Workers SDK for the backend. |
| E2 | Uptime alerting for the Worker; weekly reconciliation that pages on `ledgerImbalance ≠ 0`. **Wiring not started**; `/api/health` exists for external monitors. |
| E3 | D1 backup/export/DR plan. **Not documented**; `wrangler d1 export` works manually. |

---

## Only you can do (agent preps, you execute)
1. Sign up / pay for: Cloudflare, Chapa, Telebirr, Afromessage, Play, Apple (IDs/KYC/money).
2. Set `AUTH_SECRET` / `CHAPA_WEBHOOK_SECRET` as Cloudflare secrets (**never in git**).
3. Convert the legal/FD PDF to text for inclusion in the audit.

**Suggested order for the agent:** **A** → **B** → **C** → **D** → **E**. A and B get the system live and money flowing; then notifications, legal, release, observability.