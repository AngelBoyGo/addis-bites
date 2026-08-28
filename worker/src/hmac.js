/**
 * Addis Bites — shared secret-signature helpers (SHA-256 HMAC).
 * Used by the Chapa webhook and any future signed callbacks.
 */
const enc = new TextEncoder();

function toHex(bytes) {
  const u8 = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  return Array.from(u8).map(b => b.toString(16).padStart(2, '0')).join('');
}

/** Returns the hex HMAC-SHA256 of `data` keyed by `secret`. */
export async function hmacHex(data, secret) {
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  return toHex(sig);
}

/** Constant-time comparison of a computed hex HMAC against a provided one. */
export async function verifyHmac(data, signature, secret) {
  if (!signature || !secret) return false;
  const expected = await hmacHex(data, secret);
  const a = expected;
  const b = String(signature).toLowerCase();
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}