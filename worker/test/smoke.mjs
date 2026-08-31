/**
 * Addis Bites Worker — offline regression harness.
 *
 * Imports worker/src/index.js with NO env.DB and asserts every console route's
 * happy path plus authz (401/403), errors (404/409), idempotency (double
 * accept / double run), and the double-entry ledger balance invariant.
 *
 * Run:   node worker/test/smoke.mjs
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dir = path.dirname(fileURLToPath(import.meta.url));
const srcIndex = path.resolve(__dir, '../src/index.js');
const srcShapes = path.resolve(__dir, '../src/shapes.js');
const srcAuth = path.resolve(__dir, '../src/auth.js');
const srcHmac = path.resolve(__dir, '../src/hmac.js');
const srcProvider = path.resolve(__dir, '../src/provider.js');
const text = readFileSync(srcIndex, 'utf8')
  .replace("'./shapes.js'", "'./shapes.mjs'")
  .replace("'./auth.js'", "'./auth.mjs'")
  .replace("'./provider.js'", "'./provider.mjs'")
  .replace("'./hmac.js'", "'./hmac.mjs'");
const shapes = readFileSync(srcShapes, 'utf8');
const authSrc = readFileSync(srcAuth, 'utf8');
const hmacSrc = readFileSync(srcHmac, 'utf8');
const providerSrc = readFileSync(srcProvider, 'utf8').replace("'./hmac.js'", "'./hmac.mjs'");

// Write .mjs twins into a temp dir so ESM import resolves ./shapes.mjs etc.
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
const tmp = mkdtempSync(path.join(tmpdir(), 'ab-smoke-'));
writeFileSync(path.join(tmp, 'shapes.mjs'), shapes);
writeFileSync(path.join(tmp, 'auth.mjs'), authSrc);
writeFileSync(path.join(tmp, 'hmac.mjs'), hmacSrc);
writeFileSync(path.join(tmp, 'provider.mjs'), providerSrc);
writeFileSync(path.join(tmp, 'index.mjs'), text);
const worker = (await import(`file://${path.join(tmp, 'index.mjs')}`)).default;
const auth = await import(`file://${path.join(tmp, 'auth.mjs')}`);
const hmac = await import(`file://${path.join(tmp, 'hmac.mjs')}`);

const env = {};
const envAuth = { AUTH_SECRET: 'test-secret-0123456789' };
const call = async (method, route, token, body, whichEnv = env) => {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const req = new Request(`https://x.com${route}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined
  });
  const res = await worker.fetch(req, whichEnv, {});
  const j = await res.json().catch(() => null);
  return { status: res.status, j };
};

const tok = (phone) => `eyJhbGciOiJIUzI1NiJ9.demo-${phone}`;

let pass = 0, fail = 0;
const check = (name, cond, extra) => {
  if (cond) { pass++; console.log('PASS', name); }
  else { fail++; console.log('FAIL', name, JSON.stringify(extra)); }
};

const CUST = tok('+251911000001');
const SUPPORT = tok('+25192223331');
const FINANCE = tok('+25194445551');
const MERCHANT = tok('+25195556661');
const DRIVER = tok('+25196667771');
const ADMIN = tok('+25197778881');
const CEO = tok('+25198889991');
const CUST2 = tok('+25193334441');

let r;

// ---- Merchant ----
r = await call('GET', '/api/merchant/queue', null);
check('merchant queue 401 without token', r.status === 401, r);
r = await call('GET', '/api/merchant/queue', CUST);
check('merchant queue 403 for customer', r.status === 403, r);
r = await call('GET', '/api/merchant/queue', MERCHANT);
check('merchant queue 200 with orders', r.status === 200 && Array.isArray(r.j) && r.j.length > 0, r);
r = await call('POST', '/api/merchant/action', MERCHANT, { orderId: 'ord-demo-1', action: 'accept' });
check('merchant accept -> merchantAck', r.status === 200 && r.j.status === 'merchantAck', r);
r = await call('POST', '/api/merchant/action', MERCHANT, { orderId: 'does-not-exist', action: 'accept' });
check('merchant action unknown order -> 404', r.status === 404, r);
r = await call('POST', '/api/merchant/menu-toggle', MERCHANT, { itemId: 'sk-doro-wot', isAvailable: false });
check('menu-toggle ok', r.status === 200 && r.j.isAvailable === false, r);
r = await call('POST', '/api/merchant/menu-photo', MERCHANT, { merchantId: 'm', photoB64: 'abc' });
check('menu-photo ok', r.status === 200, r);

// Driver
r = await call('POST', '/api/driver/accept', DRIVER, { orderId: 'ord-demo-1' });
check('driver accept -> courierAssigned', r.status === 200 && r.j.status === 'courierAssigned', r);
r = await call('POST', '/api/driver/accept', DRIVER, { orderId: 'ord-demo-1' });
check('driver accept idempotent', r.status === 200, r);
r = await call('POST', '/api/driver/accept', CUST, { orderId: 'ord-demo-1' });
check('driver accept 403 for customer', r.status === 403, r);
// simpler: accept order-demo-2 then POD it
r = await call('POST', '/api/driver/accept', DRIVER, { orderId: 'ord-demo-2' });
check('driver accept order2', r.status === 200, r);
r = await call('POST', '/api/driver/pod', DRIVER, { orderId: 'ord-demo-2', photoB64: 'AAAA', pin: '1234' });
check('POD -> delivered', r.status === 200 && r.j.status === 'delivered', r);
r = await call('POST', '/api/driver/pod', DRIVER, { orderId: 'ord-demo-2', photoB64: 'AAAA', pin: '1234' });
check('POD on delivered order -> 409 pod_not_eligible', r.status === 409, r);
r = await call('POST', '/api/driver/pod', DRIVER, { orderId: 'ord-demo-1', photoB64: '', pin: '' });
check('POD missing pin/photo -> 409', r.status === 409, r);

// Foot
r = await call('POST', '/api/foot/start', null, { phone: '+251911000001' });
check('foot start ok', r.status === 200, r);
r = await call('POST', '/api/foot/orientation', CUST);
check('foot orientation 403 for customer', r.status === 403, r);
r = await call('POST', '/api/foot/orientation', DRIVER);
check('foot orientation ok', r.status === 200, r);
r = await call('POST', '/api/foot/earn-today', DRIVER);
check('foot earn-today ok', r.status === 200, r);
r = await call('GET', '/api/foot/earnings', DRIVER);
check('foot earnings shape', r.status === 200 && typeof r.j.walletBalanceEtb === 'number', r);

// Admin
r = await call('GET', '/api/admin/snapshot', ADMIN);
check('admin snapshot 200 + shape', r.status === 200 && r.j && typeof r.j.ordersToday === 'number' && Array.isArray(r.j.liveOrders) && r.j.channelStatus && r.j.config, r.j);
r = await call('GET', '/api/admin/snapshot', CEO);
check('admin snapshot 403 for ceo', r.status === 403, r);
r = await call('POST', '/api/admin/config', ADMIN, { serviceFee: 25, feeMultiplier: 1.0 });
check('admin config upsert ok', r.status === 200, r);
r = await call('POST', '/api/admin/order-action', ADMIN, { orderId: 'ord-demo-1', action: 'cancel' });
check('admin order-action ok', r.status === 200, r);
r = await call('POST', '/api/admin/verify-ocr', ADMIN);
check('admin verify-ocr ok', r.status === 200, r);

// Ratings
r = await call('POST', '/api/ratings', CUST, { orderId: 'ord-demo-1', direction: 'customer_to_courier', stars: 5, tags: ['on_time'] });
check('rating ok', r.status === 200, r);
r = await call('POST', '/api/ratings', null, { orderId: 'ord-demo-1', direction: 'customer_to_courier', stars: 5 });
check('rating 401 without token', r.status === 401, r);

// CEO + customer dispute
r = await call('POST', '/api/customer/dispute', CUST, { orderId: 'ord-demo-1', reason: 'Never received' });
check('customer dispute creates ticket', r.status === 200 && r.j.id && r.j.status === 'open', r);
r = await call('GET', '/api/ceo/dashboard', CEO);
check('ceo dashboard 200 + shape', r.status === 200 && typeof r.j.gmvEtb === 'number' && Array.isArray(r.j.disputes) && Array.isArray(r.j.promotions), r.j);
r = await call('GET', '/api/ceo/dashboard', CUST);
check('ceo dashboard 403 for customer', r.status === 403, r);
r = await call('POST', `/api/ceo/dispute/${r.j?.disputes?.[0]?.id || 'x'}/resolve`, CEO);
check('ceo resolve dispute ok', r.status === 200, r);
r = await call('POST', '/api/ceo/promo', CEO, { label: 'Weekend -15%', discountPct: 15, maxUses: 100 });
check('ceo promo ok', r.status === 200, r);

// ---- Order state-machine guard (spec §3.4) ----
r = await call('POST', '/api/place-order', CUST, {
  phone: '1234567890', merchantId: 'sheger-kitchen',
  items: [{ itemId: 'sk-doro-wot', qty: 1 }],
  subCity: 'Bole', sefer: 'Bole Medhanealem', landmarkText: 'x', paymentMethod: 'chapa',
  idempotencyKey: 'sm-state-1'
});
const smOrder = r.j && r.j.id;
r = await call('POST', '/api/merchant/action', MERCHANT, { orderId: smOrder, action: 'accept' });
check('merchant accept legal transition', r.status === 200 && r.j.status === 'merchantAck', r.j);
r = await call('POST', '/api/driver/accept', DRIVER, { orderId: smOrder });
check('driver accept from merchantAck', r.status === 200 && r.j.status === 'courierAssigned', r.j);
r = await call('POST', '/api/merchant/action', MERCHANT, { orderId: smOrder, action: 'does-not-exist' });
check('bad merchant action rejected', r.status === 400, r.j);

// ---- Driver dashboard: auth-gated + offers derive from stalled orders ----
r = await call('GET', '/api/driver/dashboard', null);
check('driver dashboard requires auth', r.status === 401, r);
r = await call('GET', '/api/driver/dashboard', CUST);
check('driver dashboard forbidden for customer', r.status === 403, r);
r = await call('GET', '/api/driver/dashboard', DRIVER);
check('driver dashboard returns offers array', r.status === 200 && Array.isArray(r.j.offers), r.j);
check('driver dashboard offers are foot-eligible', r.j.offers.every(o => o.footEligible === true), r.j);

// Support / Finance regression (unchanged)
r = await call('GET', '/api/support/dashboard', SUPPORT);
check('support dashboard still 200', r.status === 200, r);
r = await call('GET', '/api/finance/dashboard', FINANCE);
check('finance dashboard ledgerImbalance 0', r.status === 200 && r.j.ledgerImbalance === 0, r.j);

// Unknown route -> 404 (was silent {ok:true})
r = await call('POST', '/api/no-such-endpoint', ADMIN, {});
check('unknown api route -> 404', r.status === 404, r);

// ---- Real JWT auth (AUTH_SECRET configured) ----
const jwtCall = (m, route, token, body) => call(m, route, token, body, envAuth);

r = await call('POST', '/join', null, { phone: '+25195556661', name: 'Merchant', role: 'merchant' }, envAuth);
const jwt = r.j && r.j.token;
check('join signs a 3-part JWT when AUTH_SECRET set', Boolean(jwt) && jwt.split('.').length === 3 && !jwt.includes('demo-'), r.j);

r = await jwtCall('GET', '/api/merchant/queue', jwt);
check('verified JWT authorizes merchant route', r.status === 200, r);

// Tampered token must be rejected outright (no legacy downgrade).
const tampered = jwt.slice(0, 20) + (jwt[20] === 'A' ? 'B' : 'A') + jwt.slice(21);
r = await jwtCall('GET', '/api/merchant/queue', tampered);
check('tampered JWT -> 401', r.status === 401, r);

// Expired token -> 401.
const expired = await auth.signToken({ phone: '+91995556666', role: 'admin' }, envAuth.AUTH_SECRET, -10);
r = await jwtCall('GET', '/api/admin/snapshot', expired);
check('expired JWT -> 401', r.status === 401, r);

// A garbage bearer in JWT mode is 401, not downgraded to legacy.
r = await jwtCall('GET', '/api/admin/snapshot', 'eyJhbGciOiJIUzI1NiJ9.demo-+25197778881');
check('legacy demo token rejected when AUTH_SECRET set', r.status === 401, r);

// ---- Privilege-escalation guard: /join must NOT self-assign staff roles.
// A random public caller claiming "admin" must not gain staff access. Staff
// roles (admin, finance, support, ceo) are provisioned server-side only.
for (const bad of ['admin', 'finance', 'support', 'ceo']) {
  r = await call('POST', '/join', null, { phone: '+25197777777', name: 'Impostor', role: bad }, envAuth);
  const gotRole = r.j && r.j.profile && r.j.profile.role;
  check(`join rejects self-assigned ${bad} role`, r.status === 403 || gotRole !== bad, { status: r.status, j: r.j });
}
r = await jwtCall('GET', '/api/admin/snapshot', 'eyJhbGciOiJIUzI1NiJ9.demo-+25197777777');
check('impostor admin snapshot is denied', r.status === 401 || r.status === 403, r);

// ---- Chapa webhook (signature-verified, idempotent) + payout provider shell ----
const demoEnv = { DEMO_WEBHOOK: '1' };
const rawCall = async (route, rawBody) => {
  const signature = await hmac.hmacHex(rawBody, 'demo-webhook-secret');
  const req = new Request(`https://x.com${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-chapa-signature': signature },
    body: rawBody
  });
  const res = await worker.fetch(req, demoEnv, {});
  const j = await res.json().catch(() => null);
  return { status: res.status, j };
};
const badSigCall = async (route, rawBody) => {
  const req = new Request(`https://x.com${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-chapa-signature': '0'.repeat(64) },
    body: rawBody
  });
  const res = await worker.fetch(req, demoEnv, {});
  const j = await res.json().catch(() => null);
  return { status: res.status, j };
};

r = await badSigCall('/api/webhooks/chapa', JSON.stringify({ tx_ref: 'FT2589102X4', status: 'success' }));
check('chapa webhook bad signature -> 401', r.status === 401, r);

r = await rawCall('/api/webhooks/chapa', JSON.stringify({ tx_ref: 'FT2589102X4', status: 'success' }));
check('chapa webhook valid -> 200 paid', r.status === 200 && r.j.paid === true && r.j.orderId === 'ord-demo-1', r);

r = await rawCall('/api/webhooks/chapa', JSON.stringify({ tx_ref: 'FT2589102X4', status: 'success' }));
check('chapa webhook idempotent', r.status === 200 && r.j.paid === true, r);

r = await rawCall('/api/webhooks/chapa', JSON.stringify({ tx_ref: 'unknown-999', status: 'success' }));
check('chapa webhook unknown order -> 404', r.status === 404, r);

// Provider shell: without creds, sendPayout simulates a deterministic reference.
const provider = await import(`file://${path.join(tmp, 'provider.mjs')}`);
const sim = await provider.sendPayout({ id: 'pb-x', totalEtb: 100, count: 2 }, {});
check('provider simulates payout without creds', sim.ok === true && sim.simulated === true && sim.reference === 'TB-SIM-pb-x', sim);
const vOk = await provider.verifyWebhook('hello', await hmac.hmacHex('hello', 'k'), 'k');
const vBad = await provider.verifyWebhook('hello', 'deadbeef', 'k');
check('verifyWebhook accepts correct sig', vOk === true);
check('verifyWebhook rejects wrong sig', vBad === false);

// ---- Chapa checkout initialization (simulated without creds) ----
r = await call('POST', '/api/payments/chapa/initialize', null, { orderId: 'ord-demo-1' });
check('chapa initialize without token -> 401', r.status === 401, r);
r = await call('POST', '/api/payments/chapa/initialize', SUPPORT, { orderId: 'ord-demo-1' });
check('chapa initialize non-customer -> 403', r.status === 403, r);
r = await call('POST', '/api/payments/chapa/initialize', CUST, { orderId: 'no-such-order' });
check('chapa initialize unknown order -> 404', r.status === 404, r);
// fresh unpaid order (webhook tests above already confirmed ord-demo-1)
r = await call('POST', '/api/place-order', CUST, {
  phone: '+251911000001', merchantId: 'sheger-kitchen',
  items: [{ itemId: 'sk-doro-wot', qty: 2, injeraCount: 4, spice: 2 }],
  subCity: 'Bole', sefer: 'Bole Medhanealem', landmarkText: 'Gate 2', paymentMethod: 'chapa',
  idempotencyKey: 'chapa-init-1'
});
const unpaidId = r.j && r.j.id;
r = await call('POST', '/api/payments/chapa/initialize', CUST, { orderId: unpaidId });
check('chapa initialize simulates checkout url', r.status === 200 && r.j.ok === true && r.j.simulated === true
  && typeof r.j.checkoutUrl === 'string' && r.j.checkoutUrl.includes('checkout.chapa.co'), r);
r = await call('POST', '/api/payments/chapa/initialize', CUST, { orderId: unpaidId });
check('chapa initialize twice -> ok (idempotent response)', r.status === 200 && r.j.ok === true, r);
r = await call('POST', '/api/payments/chapa/initialize', CUST, {});
check('chapa initialize missing orderId -> 400', r.status === 400, r);
// real Chapa payload shape (event/data wrapper) must also verify
const chapaRaw = JSON.stringify({ event: 'charge.success', data: { tx_ref: 'FT2589102X4', status: 'success' } });
const chapaSig = await hmac.hmacHex(chapaRaw, 'demo-webhook-secret');
{
  const req = new Request('https://x.com/api/webhooks/chapa', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-chapa-signature': chapaSig },
    body: chapaRaw
  });
  const res = await worker.fetch(req, demoEnv, {});
  const j = await res.json().catch(() => null);
  check('chapa webhook accepts event/data payload', res.status === 200 && j.paid === true, { status: res.status, j });
}

// ---- Idempotent order creation (spec §3.5 / §5.10 duplicate protection) ----
const orderBody = {
  phone: '+251911000001', merchantId: 'sheger-kitchen',
  items: [{ itemId: 'sk-doro-wot', qty: 2, injeraCount: 4, spice: 2 }],
  subCity: 'Bole', sefer: 'Bole Medhanealem', landmarkText: 'Gate 2', paymentMethod: 'chapa',
  idempotencyKey: 'dup-key-1'
};
r = await call('POST', '/api/place-order', CUST, orderBody);
const firstOrderId = r.j && r.j.id;
check('place-order with idempotency key returns an order', r.status === 200 && Boolean(firstOrderId), r.j);
r = await call('POST', '/api/place-order', CUST, orderBody);
check('replayed idempotency key returns the SAME order (no duplicate)', r.status === 200 && r.j.id === firstOrderId, r.j);
r = await call('POST', '/api/place-order', CUST, { ...orderBody, idempotencyKey: 'dup-key-2' });
check('a different key mints a distinct order', r.status === 200 && r.j.id !== firstOrderId, r.j);

// ---- Refund two-person gate (>500 ETB needs admin) ----
r = await call('POST', '/api/support/refunds/rf-1/approve', SUPPORT);
check('refund under 500 approved by support', r.status === 200 && r.j.status === 'approved', r);
r = await call('POST', '/api/support/refunds/rf-big/approve', SUPPORT);
check('refund >500 approved by support is blocked', r.status === 409 && r.j.error === 'needs_second_approval', r);
r = await call('POST', '/api/support/refunds/rf-big/approve', ADMIN);
check('refund >500 approved by admin (second person)', r.status === 200 && r.j.status === 'approved', r);

// ---- Delivery guarantee credit (spec §3.4 step 7) ----
// ord-demo-1 has a promisedAt 40 min in the past; delivering it must grant an
// auto-approved delivery-fee refund.
r = await call('POST', '/api/driver/accept', DRIVER, { orderId: 'ord-demo-1' });
check('accept for guarantee test', r.status === 200, r);
r = await call('POST', '/api/driver/pod', DRIVER, { orderId: 'ord-demo-1', photoB64: 'x', pin: '0000' });
check('delivering late order grants guarantee refund', r.status === 200 && r.j.guarantee && r.j.guarantee.deliveryRefundEtb === 80 && r.j.guarantee.bunaCreditEtb === 50 && r.j.guarantee.autoApproved === true, r.j);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);