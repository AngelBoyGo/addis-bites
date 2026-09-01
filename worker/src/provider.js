/**
 * Addis Bites — payment/payout provider integration shell.
 *
 * Real Telebirr B2C & Chapa calls require API credentials that are kept out of
 * source. When the corresponding secret is configured this module performs the
 * real call; otherwise it simulates success so the app and tests stay runnable
 * offline. This keeps the provider boundary explicit and testable.
 */
import { verifyHmac } from './hmac.js';

/** Sends a B2C payout batch to Telebirr when configured. Returns {ok, reference}. */
export async function sendPayout(batch, env) {
  const key = env?.TELEBIRR_API_KEY;
  if (!key) {
    // Simulated provider (no creds): deterministic reference so the batch can
    // be reconciled; status is driven by the caller's state machine.
    return { ok: true, simulated: true, reference: `TB-SIM-${batch.id}` };
  }
  // Real integration point — wired when a live key is provided.
  const endpoint = env?.TELEBIRR_B2C_ENDPOINT || 'https://sandbox.ethiotelecom.et/telebirr/payment/v1/payout';
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Api-Key': key },
    body: JSON.stringify({ reference: batch.id, amount: batch.totalEtb, count: batch.count })
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, error: json.message || `HTTP ${res.status}` };
  return { ok: true, simulated: false, reference: json.reference || batch.id };
}

/** Validates a Chapa webhook signature (HMAC-SHA256 hex over the raw body). */
export async function verifyWebhook(rawBody, signature, secret) {
  return verifyHmac(rawBody, signature, secret);
}

/**
 * Fire-and-forget Telegram ops alert. Silent no-op unless both
 * TELEGRAM_BOT_TOKEN and TELEGRAM_ALERT_CHAT_ID are configured, so the
 * offline harness and tests are unaffected.
 */
export async function sendTelegram(env, text) {
  const token = env?.TELEGRAM_BOT_TOKEN;
  const chatId = env?.TELEGRAM_ALERT_CHAT_ID;
  if (!token || !chatId) return false;
  try {
    const res = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: chatId, text, parse_mode: 'HTML', disable_web_page_preview: true })
    });
    return res.ok;
  } catch (_) {
    return false;
  }
}

/**
 * Initializes a Chapa hosted-checkout transaction for an order.
 * Without CHAPA_SECRET_KEY configured, returns a simulated checkout URL so the
 * demo/offline harness keeps working (same policy as sendPayout).
 * Returns {ok, simulated, checkoutUrl, error?}.
 */
export async function initializeChapaTx(order, env) {
  const key = env?.CHAPA_SECRET_KEY;
  if (!key) {
    return {
      ok: true,
      simulated: true,
      checkoutUrl: `https://checkout.chapa.co/payment/addis-bites/demo/${order.id}`
    };
  }
  const baseUrl = env?.PUBLIC_BASE_URL || 'https://addis-bites-web.pages.dev';
  const res = await fetch('https://api.chapa.co/v1/transaction/initialize', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      amount: String(order.total),
      currency: 'ETB',
      email: env?.CHAPA_CUSTOMER_EMAIL || 'izzyblast2010@gmail.com',
      first_name: 'Addis',
      last_name: 'Bites',
      tx_ref: order.id,
      callback_url: `${baseUrl}/api/webhooks/chapa`,
      return_url: `${baseUrl}/`,
      customization: { title: 'Addis Bites', description: `Order ${order.id}` }
    })
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json.status !== 'success' || !json?.data?.checkout_url) {
    return { ok: false, error: json?.message || `HTTP ${res.status}` };
  }
  return { ok: true, simulated: false, checkoutUrl: json.data.checkout_url };
}