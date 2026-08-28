# Addis Bites — UI/UX Design Specification (Wireframes)

Version 1.0 — design-first spec. The app shell, routes, models, and business
logic are implemented and tested (93 Flutter tests green, analyze 0/0). This
document is the **visual contract** for polishing every screen. Source of truth
for tokens: `lib/theme/app_colors.dart`, `app_typography.dart`, `app_theme.dart`.

Design principles (mirrors §7 visual rules):
1. **Warm Ethiopian food-market identity** — Teff Gold CTA, Berbere Clay accents,
   Highland Green for fasting/halal. Never generic tech-blue or raw flag green.
2. **Amharic-first, Latin-friendly** — dual-script type, line-height ≥ 1.65,
   ≥ 12 px vertical padding on every control that can hold Amharic.
3. **Big, tappable, legible** — 40 dp+ touch targets; large price numerals.
4. **Honest states** — every screen defines loading / empty / error / success.
5. **Runner-Lite low-literacy mode** — minimal text, icon-led, big buttons, voice
   prompts parity; spare, high-contrast.

---
## 1. Component system (build once, reuse everywhere)

| Component | Tokens / shape | Notes |
|---|---|---|
| Primary button `FilledButton` | Gold bg → `onPrimary` teff-brown text, 16/700, radius 14, min-height 52 | single CTA per screen |
| Secondary button `OutlinedButton` | 1px cardBorder, radius 14, height 52 | back/secondary CTA |
| Tercierary `TextButton` | tsomGreen text | links, "Skip" |
| Card `Card` | radius 16, 1px cardBorder, elevation 0, shadow 8% | the workhorse surface |
| Section header `RoleSection` | titleLarge + 12px gap | shared widget exists |
| Chips | radius 30, bg card, border cardBorder, 12/500 | tags, filters, fasting |
| Input | filled white/card, radius 12, 16×14 padding, gold focus border 2px | search, address |
| Bottom nav | `NavigationBar` M3, 4 homes (Home/Orders/Gebeta/More) | exists in `shell.dart` |
| List row / tile | dense, contentPadding zero, leading icon within 40×40 tonal square | dashboards read clean |
| Loading / empty / error | centered spinner; icon+title+subtitle+retry; `connectionLost` string | every AsyncValue `.when` |
| Price | tabular figures, w700, size 18–28 | always ETB integer |
| Fasting banner | Highland Green surface, gold leaf icon, optional "Show all" override | `fastingProvider` |
| Status pill | tonal chip: placed/gold, preparing/clay, delivered/tsom-green, cancelled/neutral | orders + merchant |

---

## 2. Screen-by-screen wireframes

Legend: `[T]` text `[btn]` button `[card]` surface `[chip]` `◇` icon `…` scroll.

### 2.1 Splash — `splash.dart`
```
 ┌──────────────┐
 │  አዲስ ባይትስ       │   displayMedium, center
 │  Addis Bites    │   subdued latin
 │       ◇ gold-bowl logo 120dp      │
 │  [brand tagline]                │
 │  . . . .  (spinner)             │
 └──────────────┘
```
States: boot → session check → redirect `/join` or `/app` (by role). No buttons.

### 2.2 Join — `join_screen.dart`
Two panels: (A) **Phone + OTP**, (B) **role tiles**.
```
 (A)                          (B)
 ┌────────────────────────┐  ┌────────────────────────┐
 │  ግባ · Welcome          │  │  አንተ ማን ነህ? · Who are you?│
 │  [ +251 ___ ___ ___ ]  │  │  [card ◇] Customer  ገዢ │
 │  [btn Continue]         │  │  [card ◇] Merchant  ባለሱቅ │
 │  (OTP) [ _  _  _  _ ]  │  │  [card ◇] Driver  ሹፌር  │
 │        [btn Verify]     │  │  [card ◇] Support / Finance… │
 └────────────────────────┘  │  [card] Foot Carrier እግር ሹፌር │
                            └────────────────────────┘
```
Role tiles: 4-per-row grid (2×2 + foot full-width), each a Card with tonal icon
square 48dp, name EN + Am. Developer/actor roles (admin, ceo, field, support,
finance) revealed via small "More roles" disclosure so the consumer surface stays
clean. States: verifying spinner on button, error inline.

### 2.3 Customer shell & Home — `shell.dart` + `home_feed.dart`
```
 ┌────────────────────────────────┐
 │ [◇ cart]  Location: Bole ▾   [☾]│  header (safe area)
 │ [ 🔍 [  search… ] ]             │  search + button
 │ [chip Fasting active] Show all ▸│  green banner (optional)
 │ [ ► Restaurant of the Day hero ]│  tall card, gold edge
 │ [chip] Open now   [chip] Halal  │  filter row
 │ ⌄ Tag scroll: Vegan Keto Tsom…  │  horizontal chips
 │ [card] 🏪 Sheger Kitchen  4.7 ★ │  merchant card
 │   Shiro 245 · 45 min · heat     │
 │ [card] …                        │
 │ ───── bottom nav ───────        │  Home Orders Gebeta More
 └────────────────────────────────┘
```
Merchant card: 96px item-photo tile left, name title-true, cuisines bodySmall,
price+delivery+time row, rating chip. True-cost sort toggle in overflow menu.
States: loading spinner; empty = "No restaurants match (try clearing filters)";
error = retry with `connectionLost`.

### 2.4 Search & results — `features/search/search_screen.dart`
```
 │ [🔍  search q ]  ×  [Done]                │  focus autofocus
 │ Suggested: Beyainetu · Kitfo · ቡና         │  live suggestion chips
 │ ─ Results (food) ─                        │
 │ [card] 🍲 Doro Wot 420 ETB  → Sheger…    │
 │ ─ Restaurants ─                           │
 │ [card] 🏪 Restaurant cards (reuse 2.3)    │
```
States: typing → debounce spinner; no results = empty illustration + "Try ቡና or
kitfo". Category facet chips atop. Reuse `search.dart` results.

### 2.5 Restaurant & menu — `restaurant_screen.dart`
```
 ┌────────────────────────────────┐
 │  [◀]  (hero: cover + fading edge) │
 │  ሸገር ኩሽና · Sheger Kitchen         │
 │  [chip Open] [chip 4.7★] [chip ~28m]│
 │  ቦሌ Medhanealem · Bole           │
 │  [chip] Tsom ☑ [chip] Halal ☐     │
 │  ─ Menu ─                        │
 │  [card] Doro Wot          [qty +]│
 │        420 ETB · 🥘 4× [1] [2] [3]│  injera stepper chips
 │  [card] Shiro Wot   …             │
 │ ───────────────                    │
 │ [sticky] [btn] + Add · ገበታ (3)  │  cart summary bar
```
States: menu loading/empty; sold-out item = chip "Sold out", strikethrough.

### 2.6 Cart / Gebeta — `cart_screen.dart`
```
 │  ገበታ · Your basket          [◀]  │
 │ [card] 🍲 Doro Wot ×2   840      │
 │        [−] [2] [+]  injera 4 ▸  │
 │ [card] … (config-split lines)   │
 │  ───────────────                 │
 │  Subtotal     Rows               │
 │  Delivery     Band fee           │
 │  Service     20                  │
 │  [chip] Buna add-on? 50          │  optional
 │  Total      940 ETB (tabular)    │
 │ [btn] Checkout →                 │
```
States: empty gebeta = big icon + "Gebetaha fasha new" + "Browse" CTA. Changing
injera/spice re-splits lines (existing `withLine` logic).

### 2.7 Checkout — `checkout_screen.dart`
```
 │  ማረጋገጥ · Checkout          [◀] │
 │ Address: [MapPinField] + Plus   │  existing widget
 │   Code 6GWWXQQP+GV   [reuse] │
 │ Sefer / landmark [input]        │
 │ Payment: [radio] Chapa /COD     │
 │ [card] summary (as 2.6)        │
│  [btn] Place order · Pay 940   │
 │  Guarantee note: >30m refund   │  delivery guarantee note
```
States: placing spinner; success → `/order/:id`. Validation inline (address,
payment).

### 2.8 Tracking — `tracking_screen.dart`
```
 │  እየተከታተለ · Live order     [◀] │
 │ [map (flutter_map)] center pin │  existing MapPinField reuse
 │ STATUS STEPPER (5 dots):        │
 │   ✓ received → kitchen → rider │
 │      → arrived → delivered     │  stepIndex from OrderStatus
 │ [card] Tariku Assefa · Bajaj   │  courier card
 │        ★4.9 · 12 min away      │
 │ [btn] Call    [btn] Chat       │
 │ [chip] Live guarantees applied │
```
States: auto-refresh spinner; delivered = confetti-esque success block + receipt
CTA.

### 2.9 Orders — `orders_screen.dart`
```
 │  ትዕዛዞች · Orders           [◀] │
 │ [tab] Active | Past            │
 │ [card] tot.940  Sheger Kitchen │
│  placed → preparing → …  pill│
  │   · 06-25 13:20 · [Tracking]   │
 │ ─                             │
 │ [card] Past … receipt → QR     │
```
States: empty past = "እስካሁን ምንም ትዕዛዝ የለም". Active item shows live pill + tap to
tracking.

### 2.10 Receipt — `receipt_view.dart`
```
 │  ደረሰኝ · Receipt           [◀] │
 │           ◇  QR  (offline)      │  large QR for reconciliation
 │  Addis Bites · <date>           │
 │  Sheger Kitchen                 │
 │  Doro Wot       420             │
 │  Delivery       80              │
 │  Service        20              │
 │  Total    940 ETB                        │  tabular, large
 │ [btn] Share   [btn] Done        │
```

### 2.11 Sponsor-pay — `sponsor_pay_screen.dart`
```
 │  [◇ gift icon] Gursha link      │
 │  [card] Meal appeal +240 ETB   │
 │  link: addis-bites/hig/g/Ax9   │  deep link /g/<token>
 │  [chip] For: My daughter       │
 │  Pay on: Chapa                  │  sponsor pays via Chapa
 │  [btn] Pay now                  │  pay-on-Chapa CTA
States: created→opened→paid status, expiry countdown.

### 2.12 More — `more_screen.dart`
```
 │  ተጨማሪ · More                  │
 │ [card] 👤 Name · 0911 224 410   │  profile
 │   Savings  [card] 45 ETF chip  │  savings widget
 │   Fasting  [switch]             │  override
 │   Language  [chip] Amharic ▾    │
 │   Notifications [switch]        │
 │   Sponsor a meal [row]          │
 │   Support / FAQ | Log out       │
```

### Dashboards (common shell: AppBar back + refresh)
Consistent dashboard pattern:
```
 │ [AppBar title]            [⟳] │
 │ [KPI row: 4 stat cards]        │
 │ [RoleSection …Action list…]    │
 │ [RoleSection …] (scroll)       │
```
Each dash feeds `AsyncValue.when` states.

### 2.13 Merchant — `merchant_shell.dart`
```
 │ Orders: 47 · GMV 18450        │  KPI
 │ [card] 🏪 Sheger Kitchen         │  merchant card
 │   Live orders (queue)           │
 │ ⌄ for o in queue: [accept][decl]│  placed→merchantAck→prepar
 │ perf menu: [✓][×] Doro Wot     │  toggle availability
 │ [btn] Add menu photo (OCR)      │
```

### 2.14 Driver — `driver_shell.dart`
```
 │ Wallet 640 · Float 1200/1500    │
 │ econ ▼: foot/bike/scooter/car   │  VehicleEconomics
 │ Off offers: [card] ord-offer-1  │
 │   Sheger·Bole  1.2km·80→net54   │
 │   [btn] Accept   [btn] Decline  │
 │   (curfew banner if active)     │
 │ active order card → tracking    │
```

### 2.15 Runner Lite / Carrier — `carrier_screen.dart` (4-step)
Step0 signup, Step1 checklist, Step2 activation, Step3 earnings:
```
Step0                     Step3 earnings
 │  1, 2, 3                  │ 95 ETB (big)         │
 │ [btn] SIGN UP PHONE       │ Radius 1.5·Earning today│
 │ 95% keep · +50/+100       │ Bonuses ledger.          │
  Step1 checklist (3 ✓)       │  [card] Signup +50 ✓      │
  Step2 [btn] START EARN NOW  │  [card] First trip +100   │
 │  Trips history [card]     │
 │ [btn] Mark delivered      │  POD demo
```
Runner mode: icon-first rows, giant buttons, Amharic labels, no dense tables.
Step3 now reads live `footEarnings` (bonuses + trips list).

### 2.16 Field agent — `field_agent_screen.dart`
 ```
 │ KPI: activations 12 · residual 340│
 │ [card] Buna Bet · [cam icon] OCR  │  OCRFlow
 │ [btn] Verify   [btn] Reject      │
 │ [card] Merchant application…      │
 │ strikes / residuals rows          │
 ```

### 2.17 Admin — `admin_shell.dart`
```
│ [KPI] Orders 47 · GMV 18450 · 23 couriers│
│ Tabs: Live | Merchants | OTP | OCR │
│ Live: [card] orders list + aux    │
│ Merchant approval queue: app-1     │
│  [btn] Approve [btn] Reject       │
│ Config row → §configuration editor │
│ OCR staging: confidence bars      │
```

### 2.18 CEO — `ceo_shell.dart`
```
│ GMV 184500 · Orders 1203 · 42% COD│
│ [card] Disputes: d-1 open  [resolve]│
│ [card] Promotions: Welcome-10%  │
```

### 2.19 Support — `support_shell.dart`
```
│ [KPI] rep open · strikes · ref · 4mm│
│ Misconduct: [card] rep-1 late_slow │
│   [✓ Validate] [× Reject]          │
│ Strike ledger: gavel ✦ c-1 warning │
│ Refund queue: rf-1 120 [approve]   │
│ Disputes: ticket list              │
```

### 2.20 Finance — `finance_shell.dart`
```
│ Δ0 · unrecon.0 · fail0 · take 11.4%│  ledgerImbalance must be 0
│ Payout batches: pb-1 pending 18500 │
│   [btn] Run (two-person release)   │
│ Ledger: account … ±ETB (rows)      │
│ [btn] Reconcile                    │
```

---

## 3. Cross-cutting themes

1. **Empty states** (widget `shared.dart`): add a reusable `EmptyState(icon, title,
   subtitle, action)` so every list has a designed zero case.
2. **Error/retry**: standard `RetryPanel(message, onRetry)` wrapping
   `AsyncValue.when(error:)`.
3. **Screen headers**: gold underline accent on primary screen titles for brand
   cohesion.
4. **Status pill component** (shared) mapping `OrderStatus` → tonal colors.
5. **Haptics/motion**: minimal pulse on CTA confirm; no heavy animations (low-end
   phones + Runner Lite).
6. **a11y**: min 40dp hit targets; Amharic in every console control; label
   support on icon-only buttons.

## 4. Suggested build order (breadth → depth)
1. `shared.dart`: `EmptyState`, `RetryPanel`, `StatusPill`, `KpiRow` (reuse in
   every dash) — foundation.
2. Customer: Home → Restaurant → Cart → Checkout → Tracking → Orders → Receipt →
   More (the buying funnel).
3. Dashboards: Driver → Merchant → Carrier(Runner Lite) → Support/Finance →
   Admin/CEO/Field (reuse `KpiRow` + `RoleSection`).
4. Dark + Telegram theme pass; locale checks EN↔Am.

Each screen ships with its tests still green (add golden/semantic tests where
cheap).