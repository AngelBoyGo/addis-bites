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