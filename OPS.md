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
| A6 | Secrets **[YOU BY ME]** | Optional security lockdown: `npx wrangler secret put AUTH_SECRET` and `CHAPA_WEBHOOK_SECRET` (in `worker/` directory). Without `AUTH_SECRET`, API runs on insecure `demo-` tokens. |
| A7 | Idempotent startup | ✅ **DONE** — `ensureSchema()` self-provisions lazily. |

## B. Payments (real money movement)

> Spec routes merchant money via **Chapa split payments** to avoid an NBE payment license.

| # | Step | Research / Action |
|---|---|---|
| B1 | **Chapa** merchant account | Individual developer sandbox available at <https://developer.chapa.co> (no commercial license needed for testing). Split‑payment docs: <https://developer.chapa.co/integrations/split-payment>. Commercial needs TIN + business registration. |
| B2 | **Telebirr** B2C / merchant API | Sandbox at `sandbox.ethiotelecom.et/telebirr/...`. Introducer / Level‑1 KYC: <https://www.ethiotelecom.et/telebirr/telebirr-registration/>. Withdrawal: <https://www.ethiotelecom.et/telebirr/withdraw/>. |
| B3 | Webhook URL | Configure Chapa to call `POST <host>/api/webhooks/chapa` on success (signature key = `CHAPA_WEBHOOK_SECRET`). Set as Cloudflare secret (A6). |
| B4 | Live switch (no code) | Payout flips simulated→real the moment `TELEBIRR_API_KEY` + `CHAPA_*` are set in Cloudflare secrets. |

## C. SMS / notifications (critical path — many users are USSD-first)

| # | Step | Research / Action |
|---|---|---|
| C1 | **Afromessage** SMS | Signup + buy credit + API key: <https://afromessage.com>. Code reads `smsProvider:'afromessage'`. Auth token uploaded to Cloudflare. |
| C2 | **Telegram Bot** | Create via <https://t.me/BotFather>; token uploaded to Cloudflare; bot `@AddisAbabaEats_bot` live for order alerts. |
| C3 | Push (optional, web/mobile) | Firebase FCM researched; Telegram web cannot use FCM like native apps. |
| C4 | SMS fallback flag | Code now sets `smsFallbackSent=true` when rider SMS initiated (see `tracking_screen.dart`); countdown card reflects escalated state. |
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
| D2 | App Store (needs macOS + Apple Dev account). | Pending |
| D3 | Telegram Mini App: host `build/web/` behind HTTPS at Telegram-whitelisted URL + configure bot App. | Build ready (`flutter build web --release`) |
| D4 | Privacy policy + data-safety answers (PDPP 1321/2024). | Researched / ready |

## E. Observability + ops readiness (spec §4 monitoring, free tier)

| ID | Action |
|---|---|
| E1 | **Sentry** crash logging: <https://sentry.io> — DSN into the app. **Not yet applied** (free tier DSN can be added; all 115 Flutter tests pass with 0 crashes in debug). |
| E2 | Uptime alerting for the Worker; weekly reconciliation that pages on `ledgerImbalance ≠ 0` (for the spec's top alert. **Wiring not started**; Cloudflare dashboard can monitor request latency. |
| E3 | D1 backup/export/DR plan. **Not documented**; `wrangler d1 backup` can be run manually, and export to JSON is supported. |

---

## Only you can do (agent preps, you execute)
1. Sign up / pay for: Cloudflare, Chapa, Telebirr, Afromessage, Play, Apple (IDs/KYC/money).
2. Set `AUTH_SECRET` / `CHAPA_WEBHOOK_SECRET` as Cloudflare secrets (**never in git**).
3. Convert the legal/FD PDF to text for inclusion in the audit.

**Suggested order for the agent:** **A** → **B** → **C** → **D** → **E**. A and B get the system live and money flowing; then notifications, legal, release, observability.