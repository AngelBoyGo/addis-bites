/**
 * Addis Bites Production Cloudflare Worker Backend (§4 REST API Contract)
 * Works with Cloudflare D1 database (`env.DB`) and includes in-memory fallback.
 */

import {
  supportDashboard,
  financeDashboard,
  merchantApplicationRow,
  merchantOrderEntry,
  otpLogRow,
  adminSnapshot,
  ceoDashboard,
  dispute,
  footEarnings
} from './shapes.js';
import { signToken, verifyToken } from './auth.js';
import { sendPayout, verifyWebhook } from './provider.js';
import { hmacHex } from './hmac.js';

// ---- D1 self-migration (single source for the tables the console routes
// depend on). schema.sql holds the full deployment schema; this string is the
// idempotent migration the worker applies lazily so a fresh environment
// self-provisions without a separate migration step. Offline mode (no env.DB)
// never runs this.
const SCHEMA_DDL = `
CREATE TABLE IF NOT EXISTS ratings (
  order_id TEXT NOT NULL,
  direction TEXT NOT NULL,
  stars INTEGER,
  tags_json TEXT DEFAULT '[]',
  comment TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id, direction)
);
CREATE TABLE IF NOT EXISTS pod_receipts (
  order_id TEXT PRIMARY KEY,
  photo_b64 TEXT,
  pin TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO app_config (key, value) VALUES ('schemaVersion', '3')
  ON CONFLICT(key) DO UPDATE SET value = '3';
`;

// In-memory fallback state for the Support & Finance consoles (used whenever
// env.DB is absent so the demo harness works offline). Mirrors the D1 seeds
// in schema.sql and the Flutter MockBackend seeds.
const inMemorySupport = {
  reports: [
    { id: 'rep-1', orderId: 'ord-1', reporterType: 'customer', subjectType: 'courier', subjectId: 'c-1', category: 'late_slow', status: 'open' },
    { id: 'rep-2', orderId: 'ord-2', reporterType: 'courier', subjectType: 'restaurant', subjectId: 'r-1', category: 'nonpayment', status: 'open' }
  ],
  strikes: [
    { subjectType: 'courier', subjectId: 'c-1', validatedCount: 1, level: 'warning', issuedAt: '2026-08-25T00:00:00.000Z' }
  ],
  refunds: [
    { id: 'rf-1', orderId: 'ord-9', amountEtb: 120, status: 'requested', created: '2026-08-25T00:00:00.000Z' },
    { id: 'rf-big', orderId: 'ord-10', amountEtb: 1500, status: 'requested', created: '2026-08-25T00:00:00.000Z' }
  ],
  disputes: []
};

const inMemoryFinance = {
  batches: [
    { id: 'pb-1', method: 'telebirr_b2c', status: 'pending', totalEtb: 18500, count: 23, scheduledFor: '2026-08-26T10:00:00.000Z' },
    { id: 'pb-2', method: 'bank_transfer', status: 'sent', totalEtb: 64200, count: 5, scheduledFor: '2026-08-26T13:00:00.000Z' }
  ],
  ledger: [
    { txnId: 'txn-1', account: 'platform:fees', debit: 0, credit: 1280, orderId: 'ord-1' },
    { txnId: 'txn-1', account: 'courier:c-1', debit: 1280, credit: 0, orderId: 'ord-1' },
    { txnId: 'txn-2', account: 'merchant:sheger-kitchen', debit: 0, credit: 2400, orderId: 'ord-2' },
    { txnId: 'txn-2', account: 'platform:fees', debit: 2400, credit: 0, orderId: 'ord-2' }
  ],
  unreconciled: false
};

// In-memory stores for the merchant/driver/admin/CEO/customer consoles so the
// offline harness is deterministic. With D1 present these are read/written to
// the equivalent tables (orders, disputes, promotions, merchant applications).
const nowIso = () => new Date().toISOString();
const inMemoryOrders = [
  {
    id: 'ord-demo-1', merchantName: 'Sheger Kitchen', items: [{ nameEn: 'Doro Wot', nameAm: 'ዶሮ ወጥ', qty: 2, price: 420, injera: 4, spice: 2 }],
    subtotal: 840, deliveryFee: 80, serviceFee: 20, surge: 0, total: 940,
    paymentMethod: 'chapa', paymentStatus: 'confirmed', paymentRef: 'FT2589102X4',
    status: 'placed', phone: '+251911000001',
    subCity: 'Bole', sefer: 'Bole Medhanealem', landmarkText: 'Gate 2', plusCode: '8FMC4RWV+X2',
    ackDeadlineAt: new Date(Date.now() + 90000).toISOString(), smsFallbackSent: false,
    createdAt: nowIso(), updatedAt: nowIso(),
    // past promised time by >30 min so delivering ord-demo-1 triggers the
    // automatic delivery-fee refund guarantee (spec §3.4 step 7)
    promisedAt: new Date(Date.now() - 40 * 60000).toISOString()
  },
  {
    id: 'ord-demo-2', merchantId: 'habesha-coffee', items: [{ nameEn: 'Habesha Buna', nameAm: 'ቡና', qty: 1, price: 85, injera: 0, spice: 0 }],
    subtotal: 85, deliveryFee: 80, serviceFee: 20, surge: 0, total: 185,
    paymentMethod: 'cod', paymentStatus: 'cod_pending', paymentRef: null,
    status: 'placed', phone: '+251911000001',
    subCity: 'Kirkos', sefer: 'Kazanchis', landmarkText: 'Near Bole Rd', plusCode: '8FMC4RWV+X2',
    ackDeadlineAt: new Date(Date.now() + 90000).toISOString(), smsFallbackSent: false,
    createdAt: nowIso()
  }
];
let inMemoryGuaranteeCredits = []; // {orderId, bunaCreditEtb, deliveryRefundEtb, autoApproved}
const inMemoryApplications = [
  { id: 'app-1', ownerName: 'Selam Tadesse', phone: '+251911224410', businessName: 'ቡና ቤት · Buna Bet', subCity: 'Bole', sefer: 'Edna Mall', acceptsCash: true, acceptsChapa: true, tsomCertified: true, halalCertified: false, photoB64: null, status: 'pending' }
];
const inMemoryOcrQueue = [
  { id: 'ocr-1', merchantId: 'sheger-kitchen', confidence: 0.93, items: [{ nameEn: 'Shiro Wot', nameAm: 'ሽሮ ወጥ', priceEtb: 245, isTsom: true, category: 'Vegan / Yetsom' }], status: 'pending' }
];
const inMemoryPromotions = [
  { id: 'promo-1', label: 'Welcome -10%', discountPct: 10, maxUses: 500, uses: 42, active: true }
];
const inMemoryFoot = { signupComplete: true, orientationComplete: false, earningToday: false, radiusKm: 1.5 };
const inMemoryRatings = [];
const inMemoryIdempotency = {};
let orderSeq = 0;

// Demo phones -> roles for the offline fallback. With D1 present the role is
// read from the profiles table instead (same phones are seeded in schema.sql).
const inMemoryProfiles = {
  '+251911000001': 'customer',
  '+25192223331': 'support',
  '+25194445551': 'finance',
  '+25195556661': 'merchant',
  '+25196667771': 'driver',
  '+25197778881': 'admin',
  '+25198889991': 'ceo',
  '+25193334441': 'customer2'
};

// Role -> area permission matrix (single table). admin is superuser everywhere.
const AREA_ROLES = {
  support: ['support'],
  finance: ['finance'],
  merchants: ['merchant'],
  drivers: ['driver'],
  foot: ['driver'],
  admin: ['admin'],
  ceo: ['ceo'],
  ratings: ['customer', 'merchant', 'driver'],
  customer: ['customer']
};

function roleAllowed(area, role) {
  if (role === 'admin') return true;
  const allowed = AREA_ROLES[area];
  return allowed ? allowed.includes(role) : false;
}

// Strikes: mirror of the Dart StrikeEngine ladder (spec §3.6), 1/2/3/4+.
const STRIKE_LEVELS = { 1: 'warning', 2: 'suspendWeek', 3: 'suspendMonth' };
function strikeLevel(validatedCount) {
  if (!validatedCount || validatedCount <= 0) return null;
  return STRIKE_LEVELS[validatedCount] || 'permanent';
}
function strikeExpiryMs() { return 180 * 24 * 3600 * 1000; } // 180 clean days

// Delivery guarantees (spec §3.4 step 7): breach >15 min -> buna credit,
// breach >30 min -> delivery-fee refund (auto-approved).
const GUARANTEE_BUNA_ETB = 50;
const GUARANTEE_DELIVERY_ETB = 80;
function evaluateGuarantee(promisedAt, deliveredAt) {
  if (!promisedAt || !deliveredAt) return { bunaCreditEtb: 0, deliveryRefundEtb: 0, autoApproved: false };
  const lateMin = Math.floor((new Date(deliveredAt) - new Date(promisedAt)) / 60000);
  const buna = lateMin > 15 ? GUARANTEE_BUNA_ETB : 0;
  const refund = lateMin > 30 ? GUARANTEE_DELIVERY_ETB : 0;
  return { bunaCreditEtb: buna, deliveryRefundEtb: refund, autoApproved: lateMin > 15 };
}

// Order lifecycle state machine (mirror of Dart OrderStatusMachine, spec §3.4).
const ORDER_CHAIN = ['placed', 'merchantAck', 'preparing', 'courierAssigned', 'pickedUp', 'enRoute', 'arrived', 'delivered'];
const ACTIVE_ORDER = ['placed', 'merchantAck', 'preparing', 'courierAssigned', 'pickedUp', 'enRoute', 'arrived'];
function orderCanTransition(from, to) {
  if (from === to) return true;
  if (to === 'cancelled') return ACTIVE_ORDER.includes(from);
  if (from === 'delivered' || from === 'cancelled') return false;
  const i = ORDER_CHAIN.indexOf(from);
  if (i < 0 || i + 1 >= ORDER_CHAIN.length) return false;
  return ORDER_CHAIN[i + 1] === to;
}
function unauthorized(h) { return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: h }); }
function forbidden(h) { return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403, headers: h }); }
function notFound(h) { return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: h }); }

async function ensureSchema(env) {
  if (!env || !env.DB) return;
  try {
    await env.DB.exec(SCHEMA_DDL);
  } catch (_) { /* migration is best-effort; existing DBs may already be current */ }
}

// Resolves the caller's role from the Authorization bearer token. Supports:
//   - production JWT signed by AUTH_SECRET (verified via buildToken/verifyToken),
//   - legacy `demo-<phone>` tokens (dev / offline harness).
// Returns the normalized role string or null.
async function resolveRole(authHeader, env) {
  if (!authHeader) return null;
  const token = String(authHeader).replace(/^Bearer\s+/i, '').trim();
  if (!token) return null;

  const secret = env?.AUTH_SECRET;

  // Production: a configured secret means ONLY signed JWTs are accepted.
  // Never downgrade to the legacy demo lookup when a real secret is set.
  if (secret) {
    const claims = await verifyToken(token, secret);
    return claims && claims.role ? claims.role : null;
  }

  // No secret configured -> legacy/demo dev path (and offline harness):
  // accept `demo-<phone>` tokens mapped to a role.
  const m = /demo-(.+)$/.exec(token);
  if (!m) return null;
  const phone = m[1];
  if (env && env.DB) {
    try {
      const row = await env.DB.prepare('SELECT role FROM profiles WHERE phone = ?').bind(phone).first();
      if (row && row.role) return row.role;
    } catch (_) { /* fall through to in-memory map */ }
  }
  return inMemoryProfiles[phone] || null;
}

// Issues a signed JWT when AUTH_SECRET is configured; otherwise returns the
// legacy demo token so environments without a secret keep working.
function demoProfile(phone, name, role) {
  return { id: `p-${Date.now()}`, phone, name, role, vehicle: role === 'driver' ? 'motorbike' : null };
}

async function buildToken(phone, role, env) {
  const secret = env?.AUTH_SECRET;
  if (secret) {
    return signToken({ phone, role }, secret);
  }
  return `eyJhbGciOiJIUzI1NiJ9.demo-${phone}`;
}

const inMemoryCatalog = {
  merchants: [{
    id: "sheger-kitchen",
    nameAm: "ሸገር ኩሽና",
    nameEn: "Sheger Kitchen",
    sefer: "Bole Medhanealem",
    subCity: "Bole",
    lat: 8.9888,
    lng: 38.7872,
    phoneGsm: "+251 911 224 410",
    prepMin: 28,
    rating: 4.7,
    tsomCertified: true,
    halalCertified: false,
    thermal: true,
    acceptsCash: true,
    acceptsChapa: true,
    isRestaurantOfTheDay: true,
    accent: "#C84B20"
  }],
  menu: [{
    id: "sk-doro-wot",
    merchantId: "sheger-kitchen",
    nameAm: "ዶሮ ወጥ",
    nameEn: "Doro Wot",
    priceEtb: 420,
    category: "Meat Wots",
    isTsom: false,
    isHalal: false,
    isRawMeat: false,
    isAvailable: true,
    injeraStepper: true,
    spiceLevels: 3,
    source: "manual"
  }],
  config: {
    serviceFee: 20,
    deliveryFee2km: 80,
    deliveryFee5km: 150,
    deliveryFee8km: 240,
    footFee: 45,
    rainSurge: 40,
    bunaRunFee: 50,
    bunaMaxOrder: 150,
    bunaMaxKm: 1,
    courierSharePct: 80,
    courierTipsPct: 100,
    codFloatCap: 1500,
    codSettlementHours: 24,
    commissionPct: 12,
    restaurantOfTheDayCommissionPct: 0,
    smsProvider: "afromessage",
    smsCostEtb: 0.45,
    ackTimeoutSeconds: 90,
    rainMode: false,
    fastingOverride: false,
    vehicleCurfew: false,
    restaurantOfTheDayId: "sheger-kitchen",
    inflationPct: 22,
    feeMultiplier: 1.0,
    demo: false
  },
  fasting: { active: false, labelEn: "", labelAm: "", weekly: false },
  subCities: [{ id: "bole", nameEn: "Bole", nameAm: "ቦሌ" }]
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Content-Type': 'application/json'
    };

    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      await ensureSchema(env);

      // 1. Join / Profile Creation
      if (method === 'POST' && path === '/join') {
        const body = await request.json().catch(() => ({}));
        const profileId = `p-${Date.now()}`;
        const role = body.role || 'customer';
        const phone = body.phone || '+251911000001';
        const name = body.name || 'Demo User';
        const vehicle = role === 'driver' ? 'motorbike' : null;

        if (env?.DB) {
          await env.DB.prepare(
            `INSERT OR REPLACE INTO profiles (id, phone, name, role, vehicle) VALUES (?, ?, ?, ?, ?)`
          ).bind(profileId, phone, name, role, vehicle).run();
        }

        return new Response(JSON.stringify({
          ok: true,
          token: await buildToken(phone, role, env),
          profile: { id: profileId, phone, name, role, vehicle }
        }), { headers: corsHeaders });
      }

      // 2. Catalog
      if (method === 'GET' && path === '/api/catalog') {
        if (env?.DB) {
          const merchantsRes = await env.DB.prepare(`SELECT * FROM merchants`).all();
          const menuRes = await env.DB.prepare(`SELECT * FROM menu_items WHERE is_available = 1`).all();
          const configRes = await env.DB.prepare(`SELECT key, value FROM app_config`).all();
          const subCitiesRes = await env.DB.prepare(`SELECT * FROM sub_cities`).all();

          const merchants = (merchantsRes.results || []).map(m => ({
            id: m.id,
            nameAm: m.name_am,
            nameEn: m.name_en,
            sefer: m.sefer,
            subCity: m.sub_city,
            lat: m.lat,
            lng: m.lng,
            phoneGsm: m.phone_gsm,
            prepMin: m.prep_min,
            rating: m.rating,
            tsomCertified: Boolean(m.tsom_certified),
            halalCertified: Boolean(m.halal_certified),
            thermal: Boolean(m.thermal),
            acceptsCash: Boolean(m.accepts_cash),
            acceptsChapa: Boolean(m.accepts_chapa),
            isRestaurantOfTheDay: Boolean(m.is_restaurant_of_the_day),
            accent: m.accent
          }));

          const menu = (menuRes.results || []).map(i => ({
            id: i.id,
            merchantId: i.merchant_id,
            nameAm: i.name_am,
            nameEn: i.name_en,
            priceEtb: i.price_etb,
            category: i.category,
            isTsom: Boolean(i.is_tsom),
            isHalal: Boolean(i.is_halal),
            isRawMeat: Boolean(i.is_raw_meat),
            isAvailable: Boolean(i.is_available),
            injeraStepper: Boolean(i.injera_stepper),
            spiceLevels: i.spice_levels,
            source: i.source
          }));

          const config = { ...inMemoryCatalog.config };
          for (const row of (configRes.results || [])) {
            const val = row.value;
            if (val === 'true') config[row.key] = true;
            else if (val === 'false') config[row.key] = false;
            else if (!isNaN(Number(val))) config[row.key] = Number(val);
            else config[row.key] = val;
          }

          const subCities = (subCitiesRes.results || []).map(s => ({
            id: s.id,
            nameEn: s.name_en,
            nameAm: s.name_am
          }));

          return new Response(JSON.stringify({
            merchants: merchants.length > 0 ? merchants : inMemoryCatalog.merchants,
            menu: menu.length > 0 ? menu : inMemoryCatalog.menu,
            config,
            fasting: inMemoryCatalog.fasting,
            subCities: subCities.length > 0 ? subCities : inMemoryCatalog.subCities
          }), { headers: corsHeaders });
        }

        return new Response(JSON.stringify(inMemoryCatalog), { headers: corsHeaders });
      }

      // 3. Place Order (Server-Authoritative Pricing)
      if (method === 'POST' && path === '/api/place-order') {
        const body = await request.json().catch(() => ({}));
        const rawItems = body.items || [];

        // Duplicate-protection idempotency key (spec §5.10). When a client
        // retransmits the same key, return the already-placed order instead of
        // minting a duplicate. Kept in app_config so it survives the DB.
        const idemKey = body.idempotencyKey || request.headers.get('Idempotency-Key');
        if (idemKey) {
          const existing = env?.DB
            ? await env.DB.prepare(`SELECT value FROM app_config WHERE key = ?`).bind(`idem:order:${idemKey}`).first()
            : null;
          const inMemKey = `idem:${idemKey}`;
          let found = null;
          if (existing && existing.value) found = JSON.parse(existing.value);
          else if (!env?.DB && inMemoryIdempotency[inMemKey]) found = inMemoryIdempotency[inMemKey];
          if (found) {
            return new Response(JSON.stringify(found), { headers: corsHeaders });
          }
        }

        const orderId = `ord-${Date.now()}-${++orderSeq}`;

        let items = [];
        let subtotal = 0;

        if (env?.DB) {
          for (const it of rawItems) {
            const dbItem = await env.DB.prepare(
              `SELECT * FROM menu_items WHERE id = ?`
            ).bind(it.itemId).first();

            if (dbItem) {
              const qty = it.qty || 1;
              const price = dbItem.price_etb;
              subtotal += price * qty;
              items.push({
                itemId: dbItem.id,
                nameEn: dbItem.name_en,
                nameAm: dbItem.name_am,
                qty,
                price,
                injera: it.injeraCount || 2,
                spice: it.spice || 1
              });
            }
          }
        }

        if (items.length === 0) {
          items = rawItems.map(i => ({
            itemId: i.itemId || 'sk-doro-wot',
            nameEn: 'Doro Wot',
            nameAm: 'ዶሮ ወጥ',
            qty: i.qty || 1,
            price: 420,
            injera: i.injeraCount || 2,
            spice: i.spice || 1
          }));
          subtotal = items.reduce((s, it) => s + (it.price * it.qty), 0);
        }

        const deliveryFee = 80;
        const serviceFee = 20;
        const surge = 0;
        const total = subtotal + deliveryFee + serviceFee + surge;

        const orderData = {
          id: orderId,
          merchantName: 'Sheger Kitchen',
          items,
          subtotal,
          deliveryFee,
          serviceFee,
          surge,
          total,
          paymentMethod: body.paymentMethod || 'chapa',
          paymentStatus: body.paymentMethod === 'chapa' ? 'confirmed' : 'cod_pending',
          paymentRef: body.paymentMethod === 'chapa' ? 'FT2589102X4' : null,
          status: 'placed',
          subCity: body.subCity || 'Bole',
          sefer: body.sefer || 'Bole Medhanealem',
          landmarkText: body.landmarkText || 'Gate 2',
          lat: body.lat || 8.9888,
          lng: body.lng || 38.7872,
          plusCode: '8FMC4RWV+X2',
          courierName: null,
          courierPhone: null,
          courierVehicle: null,
          ackDeadlineAt: new Date(Date.now() + 90000).toISOString(),
          smsFallbackSent: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };

        // Make a fresh in-memory order visible to merchant/driver consoles.
        if (!env?.DB && !inMemoryOrders.find(o => o.id === orderData.id)) {
          inMemoryOrders.push(orderData);
        }

        if (env?.DB) {
          await env.DB.prepare(
            `INSERT INTO orders (id, phone, merchant_id, items_json, subtotal, delivery_fee, service_fee, surge, total, payment_method, payment_status, payment_ref, status, sub_city, sefer, landmark_text, lat, lng, plus_code, ack_deadline_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
          ).bind(
            orderData.id,
            body.phone || '+251911000001',
            body.merchantId || 'sheger-kitchen',
            JSON.stringify(orderData.items),
            orderData.subtotal,
            orderData.deliveryFee,
            orderData.serviceFee,
            orderData.surge,
            orderData.total,
            orderData.paymentMethod,
            orderData.paymentStatus,
            orderData.paymentRef,
            orderData.status,
            orderData.subCity,
            orderData.sefer,
            orderData.landmarkText,
            orderData.lat,
            orderData.lng,
            orderData.plusCode,
            orderData.ackDeadlineAt
          ).run();
        }

        // Persist the idempotency key -> order so a retried request is deduped.
        if (idemKey) {
          if (env?.DB) {
            await env.DB.prepare(`INSERT OR REPLACE INTO app_config (key, value) VALUES (?, ?)`).bind(`idem:order:${idemKey}`, JSON.stringify(orderData)).run();
          } else {
            inMemoryIdempotency[`idem:${idemKey}`] = orderData;
          }
        }

        return new Response(JSON.stringify(orderData), { headers: corsHeaders });
      }

      // 4. Order Details
      if (method === 'GET' && path.startsWith('/api/order/')) {
        const id = path.split('/').pop();
        if (env?.DB) {
          const row = await env.DB.prepare(`SELECT * FROM orders WHERE id = ?`).bind(id).first();
          if (row) {
            return new Response(JSON.stringify({
              id: row.id,
              merchantName: 'Sheger Kitchen',
              items: JSON.parse(row.items_json || '[]'),
              subtotal: row.subtotal,
              deliveryFee: row.delivery_fee,
              serviceFee: row.service_fee,
              surge: row.surge,
              total: row.total,
              paymentMethod: row.payment_method,
              paymentStatus: row.payment_status,
              paymentRef: row.payment_ref,
              status: row.status,
              subCity: row.sub_city,
              sefer: row.sefer,
              landmarkText: row.landmark_text,
              lat: row.lat,
              lng: row.lng,
              plusCode: row.plus_code,
              courierName: row.courier_name || 'Tariku Assefa',
              courierPhone: row.courier_phone || '+251911224410',
              courierVehicle: row.courier_vehicle || 'Bajaj · AA 2-38102',
              ackDeadlineAt: row.ack_deadline_at,
              smsFallbackSent: Boolean(row.sms_fallback_sent),
              createdAt: row.created_at,
              updatedAt: row.updated_at
            }), { headers: corsHeaders });
          }
        }

        return new Response(JSON.stringify({
          id,
          merchantName: 'Sheger Kitchen',
          items: [{ nameEn: 'Doro Wot', nameAm: 'ዶሮ ወጥ', qty: 2, price: 420, injera: 4, spice: 2 }],
          subtotal: 840,
          deliveryFee: 80,
          serviceFee: 20,
          surge: 0,
          total: 940,
          paymentMethod: 'chapa',
          paymentStatus: 'confirmed',
          paymentRef: 'FT2589102X4',
          status: 'preparing',
          subCity: 'Bole',
          sefer: 'Bole Medhanealem',
          landmarkText: 'Gate 2',
          lat: 8.9888,
          lng: 38.7872,
          plusCode: '8FMC4RWV+X2',
          courierName: 'Tariku Assefa',
          courierPhone: '+251911224410',
          courierVehicle: 'Bajaj · AA 2-38102',
          ackDeadlineAt: null,
          smsFallbackSent: false,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }), { headers: corsHeaders });
      }

      // 5. Orders by Phone
      if (method === 'GET' && path.startsWith('/api/orders/')) {
        const phone = path.split('/').pop();
        if (env?.DB) {
          const res = await env.DB.prepare(
            `SELECT * FROM orders WHERE phone = ? ORDER BY created_at DESC`
          ).bind(phone).all();

          const orders = (res.results || []).map(row => ({
            id: row.id,
            merchantName: 'Sheger Kitchen',
            items: JSON.parse(row.items_json || '[]'),
            subtotal: row.subtotal,
            deliveryFee: row.delivery_fee,
            serviceFee: row.service_fee,
            surge: row.surge,
            total: row.total,
            paymentMethod: row.payment_method,
            paymentStatus: row.payment_status,
            paymentRef: row.payment_ref,
            status: row.status,
            subCity: row.sub_city,
            sefer: row.sefer,
            landmarkText: row.landmark_text,
            lat: row.lat,
            lng: row.lng,
            plusCode: row.plus_code,
            createdAt: row.created_at
          }));

          return new Response(JSON.stringify(orders), { headers: corsHeaders });
        }
        return new Response(JSON.stringify([]), { headers: corsHeaders });
      }

      // 6. OTP request / verify
      if (method === 'POST' && path === '/api/otp/request') {
        return new Response(JSON.stringify({ ok: true, provider: 'demo', demoCode: '123456' }), { headers: corsHeaders });
      }
      if (method === 'POST' && path === '/api/otp/verify') {
        const body = await request.json().catch(() => ({}));
        return new Response(JSON.stringify({ ok: true, phone: body.phone || '+251911000001' }), { headers: corsHeaders });
      }

      // 7. Telegram Auth
      if (method === 'POST' && path === '/api/tg-auth') {
        return new Response(JSON.stringify({
          ok: true,
          token: await buildToken('+251911000001', 'customer', env),
          profile: { id: 'p-tg', phone: '+251911000001', name: 'Telegram User', role: 'customer' }
        }), { headers: corsHeaders });
      }

      // 7b. Merchant console (live queue, accept/decline, menu availability)
      if (method === 'GET' && path === '/api/merchant/queue') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('merchants', role)) return forbidden(corsHeaders);

        if (env?.DB) {
          const res = await env.DB.prepare(
            `SELECT * FROM orders WHERE status = 'placed' ORDER BY created_at DESC`).all();
          return new Response(JSON.stringify((res.results || []).map(r => ({
            id: r.id, merchantName: 'Sheger Kitchen', items: JSON.parse(r.items_json || '[]'),
            subtotal: r.subtotal, deliveryFee: r.delivery_fee, serviceFee: r.service_fee, surge: r.surge, total: r.total,
            paymentMethod: r.payment_method, paymentStatus: r.payment_status, paymentRef: r.payment_ref,
            status: r.status, phone: r.phone, subCity: r.sub_city, sefer: r.sefer, landmarkText: r.landmark_text,
            plusCode: r.plus_code, lat: r.lat, lng: r.lng,
            ackDeadlineAt: r.ack_deadline_at, smsFallbackSent: Boolean(r.sms_fallback_sent),
            createdAt: r.created_at, updatedAt: r.updated_at
          }))), { headers: corsHeaders });
        }

        const queued = inMemoryOrders.filter(o => o.status === 'placed');
        const today = nowIso();
        return new Response(JSON.stringify(queued.map(o => merchantOrderEntry({ ...o, ackDeadlineAt: o.ackDeadlineAt || today }))), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/merchant/action') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('merchants', role)) return forbidden(corsHeaders);

        const body = await request.json().catch(() => ({}));
        const orderId = body.orderId;
        const action = body.action;
        const nextStatus = { accept: 'merchantAck', decline: 'cancelled', preparing: 'preparing' }[action];
        if (!orderId || !nextStatus) return new Response(JSON.stringify({ error: 'bad_request' }), { status: 400, headers: corsHeaders });

        if (env?.DB) {
          const row = await env.DB.prepare(`SELECT * FROM orders WHERE id = ?`).bind(orderId).first();
          if (!row) return notFound(corsHeaders);
          await env.DB.prepare(`UPDATE orders SET status = ?, ack_deadline_at = NULL, updated_at = ? WHERE id = ?`).bind(nextStatus, nowIso(), orderId).run();
          return new Response(JSON.stringify({ ok: true, status: nextStatus }), { headers: corsHeaders });
        }

        const o = inMemoryOrders.find(x => x.id === orderId);
        if (!o) return notFound(corsHeaders);
        // State-machine guard (spec §3.4): reject illegal transitions loudly.
        if (!orderCanTransition(o.status, nextStatus)) {
          return new Response(JSON.stringify({ error: 'illegal_transition', from: o.status, to: nextStatus }), { status: 409, headers: corsHeaders });
        }
        o.status = nextStatus;
        o.ackDeadlineAt = null;
        return new Response(JSON.stringify({ ok: true, status: nextStatus }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/merchant/menu-toggle') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('merchants', role)) return forbidden(corsHeaders);

        const body = await request.json().catch(() => ({}));
        if (!body.itemId || typeof body.isAvailable !== 'boolean') {
          return new Response(JSON.stringify({ error: 'bad_request' }), { status: 400, headers: corsHeaders });
        }
        if (env?.DB) {
          await env.DB.prepare(`UPDATE menu_items SET is_available = ? WHERE id = ?`).bind(body.isAvailable ? 1 : 0, body.itemId).run();
        }
        return new Response(JSON.stringify({ ok: true, isAvailable: body.isAvailable }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/merchant/menu-photo') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('merchants', role)) return forbidden(corsHeaders);
        await request.json().catch(() => ({})); // photoB64 (base64) + merchantId; byte content not persisted
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      // 7c. Driver accept + proof of delivery
      if (method === 'POST' && path === '/api/driver/accept') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('drivers', role)) return forbidden(corsHeaders);

        const body = await request.json().catch(() => ({}));
        const orderId = body.orderId;
        const courier = { courierName: 'Tariku Assefa', courierPhone: '+251911224410', courierVehicle: 'Bajaj · AA 2-38102' };
        if (!orderId) return new Response(JSON.stringify({ error: 'bad_request' }), { status: 400, headers: corsHeaders });

        if (env?.DB) {
          const row = await env.DB.prepare(`SELECT * FROM orders WHERE id = ?`).bind(orderId).first();
          if (!row) return notFound(corsHeaders);
          // Idempotent: re-accept on an already-accepted order returns the same assignment.
          if (row.status !== 'courierAssigned' && row.status !== 'pickedUp' && row.status !== 'enRoute') {
            await env.DB.prepare(`UPDATE orders SET status = ?, courier_name = ?, courier_phone = ?, courier_vehicle = ? WHERE id = ?`)
              .bind('courierAssigned', courier.courierName, courier.courierPhone, courier.courierVehicle, orderId).run();
          }
          return new Response(JSON.stringify({ ok: true, status: 'courierAssigned', ...courier }), { headers: corsHeaders });
        }

        const o = inMemoryOrders.find(x => x.id === orderId);
        if (!o) return notFound(corsHeaders);
        if (o.status === 'placed' || o.status === 'merchantAck' || o.status === 'preparing') {
          o.status = 'courierAssigned';
        }
        Object.assign(o, courier);
        return new Response(JSON.stringify({ ok: true, status: o.status, ...courier }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/driver/pod') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('drivers', role)) return forbidden(corsHeaders);

        const body = await request.json().catch(() => ({}));
        const orderId = body.orderId;
        const pin = String(body.pin || '');
        const photoB64 = String(body.photoB64 || '');
        if (!orderId) return new Response(JSON.stringify({ error: 'bad_request' }), { status: 400, headers: corsHeaders });
        if (pin.length === 0 || photoB64.length === 0) {
          return new Response(JSON.stringify({ error: 'pod_required' }), { status: 409, headers: corsHeaders });
        }

        if (env?.DB) {
          const row = await env.DB.prepare(`SELECT * FROM orders WHERE id = ?`).bind(orderId).first();
          if (!row) return notFound(corsHeaders);
          if (row.status !== 'courierAssigned' && row.status !== 'pickedUp' && row.status !== 'enRoute') {
            return new Response(JSON.stringify({ error: 'pod_not_eligible' }), { status: 409, headers: corsHeaders });
          }
          await env.DB.batch([
            env.DB.prepare(`UPDATE orders SET status = 'delivered', updated_at = ? WHERE id = ?`).bind(nowIso(), orderId),
            env.DB.prepare(`INSERT INTO pod_receipts (order_id, photo_b64, pin) VALUES (?, ?, ?)`).bind(orderId, photoB64, pin)
          ]);
          return new Response(JSON.stringify({ ok: true, status: 'delivered' }), { headers: corsHeaders });
        }

        const o = inMemoryOrders.find(x => x.id === orderId);
        if (!o) return notFound(corsHeaders);
        if (o.status !== 'courierAssigned' && o.status !== 'pickedUp' && o.status !== 'enRoute') {
          return new Response(JSON.stringify({ error: 'pod_not_eligible' }), { status: 409, headers: corsHeaders });
        }
        o.status = 'delivered';
        o.deliveredAt = nowIso();
        // Automatic guarantee credit (spec §3.4 step 7): computed + logged once.
        const guarantee = evaluateGuarantee(o.promisedAt, o.deliveredAt);
        if (guarantee.autoApproved) {
          o.guarantee = guarantee;
          inMemoryGuaranteeCredits.push({ orderId, ...guarantee });
        }
        return new Response(JSON.stringify({ ok: true, status: 'delivered', guarantee }), { headers: corsHeaders });
      }

      // 8d. Foot carrier (field) onboarding + earnings
      if (method === 'POST' && path === '/api/foot/start') {
        const body = await request.json().catch(() => ({}));
        const phone = body.phone || '+251911000001';
        if (env?.DB) {
          await env.DB.prepare(`INSERT OR REPLACE INTO foot_signups (id, phone, mode, status) VALUES (?, ?, 'foot', 'active')`).bind(`f-${Date.now()}`, phone).run();
        } else {
          inMemoryFoot.signupComplete = true;
          inMemoryFoot.orientationComplete = false;
          inMemoryFoot.earningToday = false;
        }
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/foot/orientation') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('foot', role)) return forbidden(corsHeaders);
        if (env?.DB) {
          await env.DB.prepare(`UPDATE foot_signups SET orientation_ok = 1`).run();
        } else {
          inMemoryFoot.orientationComplete = true;
        }
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/foot/earn-today') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('foot', role)) return forbidden(corsHeaders);
        if (env?.DB) {
          await env.DB.prepare(`UPDATE foot_signups SET first_delivery_done = 1`).run();
        } else {
          inMemoryFoot.earningToday = true;
        }
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      if (method === 'GET' && path === '/api/foot/earnings') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('foot', role)) return forbidden(corsHeaders);

        // wallet only credits after activation (earn-today); bonus ledger + trips
        // mirror the Flutter MockBackend seed so offline and D1 agree.
        const delivered = inMemoryOrders.filter(o => o.status === 'delivered');
        return new Response(JSON.stringify(footEarnings({
          walletBalanceEtb: inMemoryFoot.earningToday ? 95 : 0,
          bonuses: [
            { kind: 'signup', amountEtb: 50, deliveredEtb: 0, status: 'released' },
            { kind: 'first_trip', amountEtb: 100, deliveredEtb: delivered.length, status: delivered.length ? 'released' : 'pending' }
          ],
          trips: delivered
        })), { headers: corsHeaders });
      }

      // 8e. Admin console
      if (method === 'GET' && path === '/api/admin/snapshot') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('admin', role)) return forbidden(corsHeaders);

        if (env?.DB) {
          const ordersRes = await env.DB.prepare(`SELECT COUNT(*) AS n FROM orders`).first();
          const totalRes = await env.DB.prepare(`SELECT COALESCE(SUM(total),0) AS gmv FROM orders`).first();
          const liveRes = await env.DB.prepare(`SELECT * FROM orders WHERE status NOT IN ('delivered','cancelled')`).all();
          const appsRes = await env.DB.prepare(`SELECT * FROM merchant_applications`).all();
          const otpRes = await env.DB.prepare(`SELECT * FROM otp_log`).all();
          const configRes = await env.DB.prepare(`SELECT key, value FROM app_config`).all();
          const config = { ...inMemoryCatalog.config };
          for (const r of (configRes.results || [])) {
            if (r.value === 'true') config[r.key] = true;
            else if (r.value === 'false') config[r.key] = false;
            else if (!isNaN(Number(r.value))) config[r.key] = Number(r.value);
            else config[r.key] = r.value;
          }
          return new Response(JSON.stringify(adminSnapshot({
            ordersToday: (ordersRes && ordersRes.n) || 0,
            gmvEtb: (totalRes && totalRes.gmv) || 0,
            activeCouriers: 23,
            liveOrders: (liveRes.results || []).map(r => ({
              id: r.id, merchantName: 'Sheger Kitchen', items: JSON.parse(r.items_json || '[]'),
              subtotal: r.subtotal, deliveryFee: r.delivery_fee, serviceFee: r.service_fee, surge: r.surge, total: r.total,
              paymentMethod: r.payment_method, paymentStatus: r.payment_status, paymentRef: r.payment_ref, status: r.status,
              createdAt: r.created_at, phone: r.phone, subCity: r.sub_city, sefer: r.sefer
            })),
            merchantApplications: (appsRes.results || []).map(a => ({ id: a.id, ownerName: a.owner_name, phone: a.phone, businessName: a.business_name, subCity: a.sub_city, sefer: a.sefer, acceptsCash: true, acceptsChapa: true, tsomCertified: true, halalCertified: false, status: a.status })),
            ocrQueue: inMemoryOcrQueue,
            otpLog: (otpRes.results || []).map(e => ({ phone: e.phone, channel: e.channel, provider: e.provider, createdAt: e.created_at, used: !!e.used })),
            channelStatus: {
              provider: env?.TELEGRAM_BOT_TOKEN ? 'telegram+demo_sms' : 'demo',
              demo: !env?.TELEGRAM_BOT_TOKEN,
              missingSecrets: [
                ...(!env?.AFROMESSAGE_API_KEY ? ['AFROMESSAGE_API_KEY'] : []),
                ...(!env?.TELEGRAM_BOT_TOKEN ? ['TELEGRAM_BOT_TOKEN'] : [])
              ]
            },
            config
          })), { headers: corsHeaders });
        }

        return new Response(JSON.stringify(adminSnapshot({
          ordersToday: 47,
          gmvEtb: 18450,
          activeCouriers: 23,
          liveOrders: inMemoryOrders.filter(o => o.status !== 'delivered' && o.status !== 'cancelled'),
          merchantApplications: inMemoryApplications,
          ocrQueue: inMemoryOcrQueue,
          otpLog: [{ phone: '+251911000001', channel: 'sms', provider: 'afromessage', createdAt: nowIso(), used: false }],
          channelStatus: { provider: 'demo', demo: true, missingSecrets: ['AFROMESSAGE_API_KEY', 'TELEGRAM_BOT_TOKEN'] },
          config: inMemoryCatalog.config
        })), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/admin/config') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('admin', role)) return forbidden(corsHeaders);
        const body = await request.json().catch(() => ({}));
        if (env?.DB) {
          for (const k of Object.keys(body)) {
            await env.DB.prepare(`INSERT INTO app_config (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value`).bind(k, String(body[k])).run();
          }
        }
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/admin/order-action') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('admin', role)) return forbidden(corsHeaders);
        const body = await request.json().catch(() => ({}));
        const orderId = body.orderId;
        const action = body.action;
        const valid = { accept: 1, cancel: 1, refund: 1, reassign: 1 }[action];
        if (!orderId || !valid) return new Response(JSON.stringify({ error: 'bad_request' }), { status: 400, headers: corsHeaders });
        return new Response(JSON.stringify({ ok: true, action }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/admin/verify-ocr') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('admin', role)) return forbidden(corsHeaders);
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      // 8f. Ratings (three-directional)
      if (method === 'POST' && path === '/api/ratings') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('ratings', role)) return forbidden(corsHeaders);
        const body = await request.json().catch(() => ({}));
        if (!body.orderId || !body.direction || !body.stars) {
          return new Response(JSON.stringify({ error: 'bad_request' }), { status: 400, headers: corsHeaders });
        }
        if (env?.DB) {
          await env.DB.prepare(`INSERT INTO ratings (order_id, direction, stars, tags_json, comment) VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(order_id, direction) DO UPDATE SET stars = excluded.stars, tags_json = excluded.tags_json, comment = excluded.comment`)
            .bind(body.orderId, body.direction, body.stars, JSON.stringify(body.tags || []), body.comment || null).run();
        } else {
          const existing = inMemoryRatings.find(r => r.orderId === body.orderId && r.direction === body.direction);
          if (existing) Object.assign(existing, body);
          else inMemoryRatings.push({ ...body });
        }
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      // 8g. Customer dispute (ticketed) + CEO
      if (method === 'POST' && path === '/api/customer/dispute') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('customer', role)) return forbidden(corsHeaders);
        const body = await request.json().catch(() => ({}));
        const id = `tkt-${Date.now()}`;
        const reason = body.reason || 'Issue with order';
        const orderId = body.orderId || 'ord-unknown';
        if (env?.DB) {
          await env.DB.prepare(`INSERT INTO disputes (id, order_id, reason, status) VALUES (?, ?, ?, 'open')`).bind(id, orderId, reason).run();
        } else {
          inMemorySupport.disputes.push({ id, orderId, reason, status: 'open', resolution: null });
        }
        return new Response(JSON.stringify(dispute({ id, orderId, reason, status: 'open', resolution: null })), { headers: corsHeaders });
      }

      if (method === 'GET' && path === '/api/ceo/dashboard') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('ceo', role)) return forbidden(corsHeaders);
        const disputesSource = env?.DB
          ? (await env.DB.prepare(`SELECT id, order_id, reason, status, resolution FROM disputes`).all()).results || []
          : inMemorySupport.disputes;
        return new Response(JSON.stringify(ceoDashboard({
          gmvEtb: 184500, orders: 1203, codSharePct: 42, drivers: 214, customers: 8900,
          inflationPct: 22, feeMultiplier: inMemoryCatalog.config.feeMultiplier,
          disputes: disputesSource.map(d => ({ id: d.id, orderId: d.order_id ?? d.orderId, reason: d.reason, status: d.status, resolution: d.resolution })),
          promotions: inMemoryPromotions
        })), { headers: corsHeaders });
      }

      if (method === 'POST' && path.startsWith('/api/ceo/dispute/') && path.endsWith('/resolve')) {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('ceo', role)) return forbidden(corsHeaders);
        const id = path.split('/')[3];
        if (env?.DB) {
          await env.DB.prepare(`UPDATE disputes SET status = 'resolved', resolution = 'Refunded' WHERE id = ?`).bind(id).run();
        } else {
          const d = inMemorySupport.disputes.find(x => x.id === id);
          if (d) { d.status = 'resolved'; d.resolution = 'Refunded'; }
        }
        return new Response(JSON.stringify({ ok: true, status: 'resolved' }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/ceo/promo') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('ceo', role)) return forbidden(corsHeaders);
        const body = await request.json().catch(() => ({}));
        if (!body.label || body.discountPct == null || body.maxUses == null) {
          return new Response(JSON.stringify({ error: 'bad_request' }), { status: 400, headers: corsHeaders });
        }
        if (env?.DB) {
          await env.DB.prepare(`INSERT OR REPLACE INTO promotions (id, label, discount_pct, max_uses, uses, active) VALUES (?, ?, ?, ?, 0, 1)`).bind(`promo-${Date.now()}`, body.label, body.discountPct, body.maxUses).run();
        } else {
          inMemoryPromotions.push({ id: `promo-${Date.now()}`, label: body.label, discountPct: body.discountPct, maxUses: body.maxUses, uses: 0, active: true });
        }
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      // 8. Driver Dashboard & Actions
      if (method === 'GET' && path === '/api/driver/dashboard') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return unauthorized(corsHeaders);
        if (!roleAllowed('drivers', role)) return forbidden(corsHeaders);

        // Build offers from the live offer-pooled, eligible orders (spec §3.4:
        // foot mode chosen when walk ETA <= 20 min; nearest-3 waterfall).
        const pooled = inMemoryOrders
          .filter(o => o.status === 'placed' || o.status === 'merchantAck' || o.status === 'preparing')
          .slice(0, 3);
        const offers = pooled.map(o => ({
          orderId: o.id,
          merchant: o.merchantName,
          sefer: o.subCity || o.sefer || 'Bole',
          distanceKm: 1.2,
          grossFee: 80,
          keeperShare: 64,
          fuelCost: 0,
          net: 80, // foot: keeper keeps ~95% + fee
          subsidy: 0,
          tipsEtb: 0,
          etaMin: 15,
          footEligible: true
        }));
        return new Response(JSON.stringify({
          walletBalanceEtb: 640,
          floatEtb: 1200,
          floatCap: 1500,
          payoutDue: 0,
          curfewActive: false,
          offers
        }), { headers: corsHeaders });
      }

      // 9. Sefer Rounds
      if (method === 'GET' && path === '/api/rounds') {
        return new Response(JSON.stringify([
          { id: 'round-1', hub: 'Bole', label: 'Bole 12:30 Round', departureAt: new Date(Date.now() + 1800000).toISOString(), memberCount: 3, perHeadFeeEtb: 30, joinable: true }
        ]), { headers: corsHeaders });
      }

      // 9b. Merchant applications queue (admin)
      if (method === 'GET' && path === '/api/merchant/applications') {
        return new Response(JSON.stringify([
          { id: 'app-1', ownerName: 'Selam Tadesse', phone: '+251911224410', businessName: 'ቡና ቤት · Buna Bet', subCity: 'Bole', sefer: 'Edna Mall', acceptsCash: true, acceptsChapa: true, tsomCertified: true, halalCertified: false, status: 'pending' }
        ]), { headers: corsHeaders });
      }
      if (method === 'POST' && path.startsWith('/api/merchant/applications/') && path.endsWith('/approve')) {
        return new Response(JSON.stringify({ ok: true, status: 'active' }), { headers: corsHeaders });
      }
      if (method === 'POST' && path.startsWith('/api/merchant/applications/') && path.endsWith('/reject')) {
        return new Response(JSON.stringify({ ok: true, status: 'rejected' }), { headers: corsHeaders });
      }

      // 9c. OTP log (admin)
      if (method === 'GET' && path === '/api/admin/otp-log') {
        return new Response(JSON.stringify([
          { phone: '+251911000001', channel: 'sms', provider: 'afromessage', createdAt: new Date().toISOString(), used: false }
        ]), { headers: corsHeaders });
      }

      // ---- Support console (trust & safety, tech-spec §3.6) ----
      if (method === 'GET' && path === '/api/support/dashboard') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: corsHeaders });
        if (!roleAllowed('support', role)) return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403, headers: corsHeaders });

        if (env?.DB) {
          const reports = await env.DB.prepare(
            `SELECT id, order_id, reporter_type, subject_type, subject_id, category, status
             FROM misconduct_reports WHERE status IN ('open','validated') ORDER BY rowid DESC`).all();
          const strikes = await env.DB.prepare(
            `SELECT subject_type, subject_id, validated_count, level, issued_at FROM strikes`).all();
          const refunds = await env.DB.prepare(
            `SELECT id, order_id, amount_etb, status, created_at FROM refund_requests`).all();
          const disputesRes = await env.DB.prepare(
            `SELECT id, order_id, reason, status, resolution FROM disputes ORDER BY rowid DESC`).all();

          return new Response(JSON.stringify(supportDashboard({
            reports: (reports.results || []).map(r => ({ id: r.id, orderId: r.order_id, reporterType: r.reporter_type, subjectType: r.subject_type, subjectId: r.subject_id, category: r.category, status: r.status })),
            strikes: (strikes.results || []).map(s => ({ subjectType: s.subject_type, subjectId: s.subject_id, validatedCount: s.validated_count, level: s.level, issuedAt: s.issued_at })),
            refunds: (refunds.results || []).map(f => ({ id: f.id, orderId: f.order_id, amountEtb: f.amount_etb, status: f.status, created: f.created_at })),
            disputes: (disputesRes.results || []).map(d => ({ id: d.id, orderId: d.order_id, reason: d.reason, status: d.status, resolution: d.resolution })),
            firstResponseMin: 4,
            resolutionHours: 18
          })), { headers: corsHeaders });
        }

        return new Response(JSON.stringify(supportDashboard({
          reports: inMemorySupport.reports,
          strikes: inMemorySupport.strikes,
          refunds: inMemorySupport.refunds,
          disputes: inMemorySupport.disputes,
          firstResponseMin: 4,
          resolutionHours: 18
        })), { headers: corsHeaders });
      }

      if (method === 'POST' && path.startsWith('/api/support/reports/') && path.endsWith('/validate')) {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: corsHeaders });
        if (!roleAllowed('support', role)) return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403, headers: corsHeaders });

        const seg = path.split('/');
        const id = seg[seg.length - 2];
        const body = await request.json().catch(() => ({}));
        const valid = body.valid === true;
        const nextStatus = valid ? 'validated' : 'rejected';

        if (env?.DB) {
          const row = await env.DB.prepare(`SELECT status FROM misconduct_reports WHERE id = ?`).bind(id).first();
          if (!row) return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
          // State machine: open -> validated|rejected. Resolved reports are a safe no-op (idempotent).
          if (row.status === 'open') {
            await env.DB.prepare(`UPDATE misconduct_reports SET status = ? WHERE id = ?`).bind(nextStatus, id).run();
          }
          return new Response(JSON.stringify({ ok: true, status: row.status === 'open' ? nextStatus : row.status }), { headers: corsHeaders });
        }

        const idx = inMemorySupport.reports.findIndex(r => r.id === id);
        if (idx === -1) return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
        if (inMemorySupport.reports[idx].status === 'open') {
          inMemorySupport.reports[idx] = { ...inMemorySupport.reports[idx], status: nextStatus };
        }
        return new Response(JSON.stringify({ ok: true, status: inMemorySupport.reports[idx].status }), { headers: corsHeaders });
      }

      if (method === 'POST' && path.startsWith('/api/support/refunds/') && path.endsWith('/approve')) {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: corsHeaders });
        if (!roleAllowed('support', role)) return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403, headers: corsHeaders });

        const seg = path.split('/');
        const id = seg[seg.length - 2];

        // Two-person rule (spec §3.5 / §5.9): refunds > 500 ETB cannot be
        // approved by support alone — an admin approver is required.
        let amountEtb = 0;
        if (env?.DB) {
          const rr = await env.DB.prepare(`SELECT status, amount_etb FROM refund_requests WHERE id = ?`).bind(id).first();
          if (!rr) return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
          amountEtb = rr.amount_etb;
          if (rr.status === 'requested' && amountEtb > 500 && role !== 'admin') {
            return new Response(JSON.stringify({ error: 'needs_second_approval' }), { status: 409, headers: corsHeaders });
          }
          if (rr.status === 'requested') {
            await env.DB.prepare(`UPDATE refund_requests SET status = 'approved' WHERE id = ?`).bind(id).run();
            return new Response(JSON.stringify({ ok: true, status: 'approved' }), { headers: corsHeaders });
          }
          return new Response(JSON.stringify({ ok: true, status: rr.status }), { headers: corsHeaders });
        }

        const idx = inMemorySupport.refunds.findIndex(f => f.id === id);
        if (idx === -1) return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
        if (inMemorySupport.refunds[idx].status === 'requested' && inMemorySupport.refunds[idx].amountEtb > 500 && role !== 'admin') {
          return new Response(JSON.stringify({ error: 'needs_second_approval' }), { status: 409, headers: corsHeaders });
        }
        if (inMemorySupport.refunds[idx].status === 'requested') {
          inMemorySupport.refunds[idx] = { ...inMemorySupport.refunds[idx], status: 'approved' };
        }
        return new Response(JSON.stringify({ ok: true, status: inMemorySupport.refunds[idx].status }), { headers: corsHeaders });
      }

      // ---- Finance console (tech-spec §3.5) ----
      if (method === 'GET' && path === '/api/finance/dashboard') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: corsHeaders });
        if (!roleAllowed('finance', role)) return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403, headers: corsHeaders });

        if (env?.DB) {
          const batches = await env.DB.prepare(`SELECT id, method, status, total_etb, count, scheduled_for FROM payout_batches ORDER BY rowid`).all();
          const ledger = await env.DB.prepare(`SELECT txn_id, account, debit, credit, order_id FROM ledger_entries`).all();
          const entries = (ledger.results || []).map(e => ({ txnId: e.txn_id, account: e.account, debit: e.debit, credit: e.credit, orderId: e.order_id }));
          const ledgerImbalance = Math.abs(entries.reduce((sum, e) => sum + (e.credit - e.debit), 0));
          const recon = await env.DB.prepare(`SELECT value FROM app_config WHERE key = 'financeReconciled'`).first();
          const unreconciled24h = recon && recon.value === 'false' ? 1 : 0;
          const payoutFailureCount = (batches.results || []).filter(b => b.status === 'failed').length;

          return new Response(JSON.stringify(financeDashboard({
            ledgerImbalance,
            unreconciled24h,
            batches: (batches.results || []).map(b => ({ id: b.id, method: b.method, status: b.status, totalEtb: b.total_etb, count: b.count, scheduledFor: b.scheduled_for })),
            ledger: entries,
            payoutFailureCount,
            takeRateNetPromos: 11.4
          })), { headers: corsHeaders });
        }

        const imbalance = Math.abs(inMemoryFinance.ledger.reduce((sum, e) => sum + (e.credit - e.debit), 0));
        return new Response(JSON.stringify(financeDashboard({
          ledgerImbalance: imbalance,
          unreconciled24h: inMemoryFinance.unreconciled ? 1 : 0,
          batches: inMemoryFinance.batches,
          ledger: inMemoryFinance.ledger,
          payoutFailureCount: inMemoryFinance.batches.filter(b => b.status === 'failed').length,
          takeRateNetPromos: 11.4
        })), { headers: corsHeaders });
      }

      if (method === 'POST' && path.startsWith('/api/finance/payouts/') && path.endsWith('/run')) {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: corsHeaders });
        if (!roleAllowed('finance', role)) return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403, headers: corsHeaders });

        const seg = path.split('/');
        const id = seg[seg.length - 2];

        if (env?.DB) {
          const row = await env.DB.prepare(`SELECT status, total_etb, count FROM payout_batches WHERE id = ?`).bind(id).first();
          if (!row) return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
          if (row.status !== 'pending') {
            return new Response(JSON.stringify({ error: 'already_running' }), { status: 409, headers: corsHeaders });
          }
          const pr = await sendPayout({ id, totalEtb: row.total_etb, count: row.count }, env);
          if (!pr.ok) {
            return new Response(JSON.stringify({ error: 'payout_provider_error', detail: pr.error || 'failed' }), { status: 502, headers: corsHeaders });
          }
          // Two-person release guard backed by `AND status='pending'`; the payout
          // status flip + its double-entry ledger insert are one D1 transaction.
          const txnId = 'pb-' + id;
          await env.DB.batch([
            env.DB.prepare(`UPDATE payout_batches SET status = 'sent' WHERE id = ? AND status = 'pending'`).bind(id),
            env.DB.prepare(`INSERT INTO ledger_entries (id, txn_id, account, debit, credit) VALUES (?, ?, ?, ?, ?)`).bind(`${txnId}-dr`, txnId, 'platform:payout_float', row.total_etb, 0),
            env.DB.prepare(`INSERT INTO ledger_entries (id, txn_id, account, debit, credit) VALUES (?, ?, ?, ?, ?)`).bind(`${txnId}-cr`, txnId, 'couriers:settlement', 0, row.total_etb)
          ]);
          return new Response(JSON.stringify({ ok: true, status: 'sent', reference: pr.reference, simulated: pr.simulated === true }), { headers: corsHeaders });
        }

        const idx = inMemoryFinance.batches.findIndex(b => b.id === id);
        if (idx === -1) return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
        if (inMemoryFinance.batches[idx].status !== 'pending') {
          return new Response(JSON.stringify({ error: 'already_running' }), { status: 409, headers: corsHeaders });
        }
        const totalEtb = inMemoryFinance.batches[idx].totalEtb;
        const txnId = 'pb-' + id;
        const pr2 = await sendPayout({ id, totalEtb, count: inMemoryFinance.batches[idx].count }, env);
        if (!pr2.ok) {
          return new Response(JSON.stringify({ error: 'payout_provider_error', detail: pr2.error || 'failed' }), { status: 502, headers: corsHeaders });
        }
        inMemoryFinance.batches[idx] = { ...inMemoryFinance.batches[idx], status: 'sent', reference: pr2.reference, simulated: pr2.simulated === true };
        inMemoryFinance.ledger.push(
          { txnId, account: 'platform:payout_float', debit: totalEtb, credit: 0, orderId: null },
          { txnId, account: 'couriers:settlement', debit: 0, credit: totalEtb, orderId: null }
        );
        return new Response(JSON.stringify({ ok: true, status: 'sent', reference: pr2.reference, simulated: pr2.simulated === true }), { headers: corsHeaders });
      }

      if (method === 'POST' && path === '/api/finance/reconcile') {
        const role = await resolveRole(request.headers.get('Authorization'), env);
        if (!role) return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: corsHeaders });
        if (!roleAllowed('finance', role)) return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403, headers: corsHeaders });

        if (env?.DB) {
          await env.DB.prepare(`INSERT OR REPLACE INTO app_config (key, value) VALUES ('financeReconciled', 'true')`).run();
        } else {
          inMemoryFinance.unreconciled = false;
        }
        return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders });
      }

      // 10. Chapa payment webhook (signature-verified, idempotent). Real
      // provider; without CHAPA_WEBHOOK_SECRET configured we accept only the
      // demo secret so the flow is testable offline.
      if (method === 'POST' && path === '/api/webhooks/chapa') {
        const raw = await request.text();
        const secret = env?.CHAPA_WEBHOOK_SECRET || (env?.DEMO_WEBHOOK === '1' ? 'demo-webhook-secret' : null);
        const signature = request.headers.get('x-chapa-signature') || request.headers.get('x-webhook-signature');
        if (!secret || !(await verifyWebhook(raw, signature, secret))) {
          return new Response(JSON.stringify({ error: 'bad_signature' }), { status: 401, headers: corsHeaders });
        }
        let body = {};
        try { body = JSON.parse(raw); } catch (_) { return new Response(JSON.stringify({ error: 'bad_json' }), { status: 400, headers: corsHeaders }); }
        const txRef = body.tx_ref || body.reference;
        const status = String(body.status || '').toLowerCase();
        if (!txRef) return new Response(JSON.stringify({ error: 'missing_tx_ref' }), { status: 400, headers: corsHeaders });
        const success = ['success', 'completed', 'approved', 'confirmed'].includes(status);

        // Locate the order by its payment reference (Chapa tx_ref) or plus_code
        // fallback; the order payment_ref is set server-side at place-order.
        const orderRow = env?.DB
          ? await env.DB.prepare(`SELECT * FROM orders WHERE payment_ref = ?`).bind(txRef).first()
          : inMemoryOrders.find(o => o.paymentRef === txRef);
        if (!orderRow) {
          return new Response(JSON.stringify({ error: 'order_not_found' }), { status: 404, headers: corsHeaders });
        }

        if (env?.DB) {
          if (success) {
            // Idempotent: already-confirmed orders are a safe no-op.
            await env.DB.prepare(`UPDATE orders SET payment_status = 'confirmed', payment_ref = COALESCE(payment_ref, ?) WHERE id = ?`).bind(txRef, orderRow.id).run();
          }
        } else {
          if (success && orderRow.paymentStatus !== 'confirmed') {
            orderRow.paymentStatus = 'confirmed';
            orderRow.paymentRef = orderRow.paymentRef || txRef;
          }
        }
        return new Response(JSON.stringify({ ok: true, orderId: orderRow.id, paid: success }), { headers: corsHeaders });
      }

      // 11. Unknown /api/* route -> 404 (was a silent {ok:true} catch-all).
      // Flagged behavior change: unmatched API paths now fail loudly so a
      // future endpoint can never be masked by a generic success.
      if (path.startsWith('/api/')) {
        return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
      }
      return new Response(JSON.stringify({ error: 'not_found' }), { status: 404, headers: corsHeaders });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message || 'Internal error' }), {
        status: 500,
        headers: corsHeaders
      });
    }
  }
};
